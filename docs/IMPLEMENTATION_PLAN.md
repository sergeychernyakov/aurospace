# AUROSPACE Orders Demo --- Implementation Plan

## Scope

### In Scope
- Domain correctness (ledger-based accounting)
- Payment processing (YooKassa)
- Ledger consistency and state transitions
- Webhook idempotency
- Async notifications with duplicate protection
- Admin observability (ActiveAdmin)
- Production-style deployment

### Out of Scope
- User authentication and registration
- Role-based access control for end users
- Full production hardening of administrative access

> Authentication is intentionally outside the assignment scope.
> ActiveAdmin is protected with Basic Auth (env credentials) for demo safety.
> Frontend works in demo-user mode with seeded users.

---

## Financial Semantics (CRITICAL --- must be clear before writing code)

**What does a successful order mean?**

User pays for an order via YooKassa. Successful payment = **credit to user's account**.

| Event | Ledger Operation | Balance Effect |
|-------|-----------------|----------------|
| Payment successful | `credit` | balance increases |
| Order cancelled | `reversal` | balance decreases (compensating entry) |

This is a "payment received" model: the user pays, the system records the incoming money on the user's account.

**Invariants:**
- `balance_cents` is NEVER updated directly
- Every change creates an immutable `LedgerEntry`
- Reversals are compensating entries, not deletions
- `Account#balance_cents = sum of all LedgerEntries for that account`

---

## PR Sequence

### PR 1: Rails Scaffold `feat/rails-scaffold` [L]

Generate Rails API skeleton so `bundle install`, `db:create`, `rspec` work.

**Create:**
- `config/application.rb`, `config/environment.rb`, `config/environments/*.rb`
- `config/routes.rb` (with `draw(:health)`)
- `config/database.yml` (uses `DATABASE_URL`)
- `config/puma.rb`, `config/boot.rb`, `config.ru`, `Rakefile`
- `config/sidekiq.yml` (queues: critical, default, mailers, low)
- `config/initializers/cors.rb`, `sidekiq.rb`, `money.rb`
- `app/controllers/application_controller.rb`
- `app/models/application_record.rb`
- `app/jobs/application_job.rb`, `app/mailers/application_mailer.rb`
- `spec/spec_helper.rb`, `spec/rails_helper.rb`
- `Gemfile.lock` (via `bundle install`)

**Modify:**
- `Gemfile` --- add `database_cleaner-active_record` (needed by existing `factory_bot_lint.rb`)

**Verification:** `bundle exec rspec` (0 examples), `bundle exec rubocop` passes, CI bootstrap detects backend.

---

### PR 2: User + Account Models `feat/user-account-models` [M]
**Depends on:** PR 1

**User** --- just data, no auth:
- Fields: `email` (unique, NOT NULL), `name` (NOT NULL)
- No password, no Devise, no sessions
- `has_one :account`, `has_many :orders`

**Account:**
- Fields: `user_id` (unique FK), `balance_cents` (integer, NOT NULL, DEFAULT 0), `currency` (NOT NULL, DEFAULT 'RUB')
- `belongs_to :user`, `has_many :ledger_entries`
- No direct balance mutation methods (those come in PR 4)

**DB constraints:**
- `users`: unique index on `email`
- `accounts`: unique index on `user_id`, `balance_cents NOT NULL DEFAULT 0`
- Foreign keys enforced

Factories + model specs (~10 examples).

---

### PR 3: Order + LedgerEntry + WebhookEvent + NotificationLog `feat/order-ledger-models` [L]
**Depends on:** PR 2

**Order:**
- `amount_cents` NOT NULL, `currency` NOT NULL DEFAULT 'RUB'
- `status` enum: `{ created: 0, payment_pending: 1, successful: 2, cancelled: 3 }`
- `payment_provider`, `external_payment_id`, `paid_at`, `cancelled_at`
- Indexes on `user_id`, `status`
- Status transition guard: `can_transition_to?(new_status)` method on model

**LedgerEntry:**
- FK on `account_id`, `order_id` (both NOT NULL)
- `entry_type` enum: `{ debit: 0, credit: 1, reversal: 2 }`
- `amount_cents` NOT NULL, `currency`, `reference`, `metadata` (jsonb)
- **Immutable after creation:** `before_update`/`before_destroy` raise error
- Indexes on `account_id`, `order_id`

**WebhookEvent:**
- `provider` NOT NULL, `external_event_id` NOT NULL (unique index)
- `event_type` NOT NULL, `payload` (jsonb), `processed_at`, `status` DEFAULT 'pending'
- Index on `provider`

**NotificationLog:**
- `order_id` FK, `mail_type` NOT NULL, `recipient` NOT NULL, `sent_at`
- **Unique composite index** on `(order_id, mail_type)` --- prevents duplicate emails

Factories + model specs (~25 examples).

---

### PR 4: Accounts::ApplyLedgerEntry `feat/accounts-ledger-service` [M]
**Depends on:** PR 3. **THE most critical service in the project.**

`app/services/accounts/apply_ledger_entry.rb`

**Algorithm:**
1. Validate: `amount_cents > 0`, currency matches account
2. `ActiveRecord::Base.transaction` block:
   - `account.lock!` (row-level lock via `SELECT ... FOR UPDATE`)
   - Create `LedgerEntry` record
   - Calculate delta: credit adds, debit subtracts, reversal adds back
   - `account.update!(balance_cents: account.balance_cents + delta)`
3. Return the created LedgerEntry

**Locking strategy:** pessimistic row lock. Transaction boundary = entire operation. If anything fails, everything rolls back.

**Error cases:**
- `Accounts::InsufficientFundsError` if debit would make balance negative
- `ArgumentError` for zero/negative amount or currency mismatch

**Specs (target 95%+, ~18 examples):**
- credit increases balance, debit decreases, reversal restores
- atomicity: if entry creation fails, balance unchanged
- insufficient funds, zero amount, currency mismatch
- concurrent access (two threads debiting simultaneously)

---

### PR 5: Orders::Create + Orders::Cancel `feat/order-create-cancel` [M]
**Depends on:** PR 4

**Orders::Create:**
- Accepts: `user`, `amount_cents`, `currency`
- User and Account must already exist (created in seeds, NOT auto-created)
- Creates Order with `status: :created`

**Orders::Cancel:**
- Guard: order must be `successful` (raise `InvalidTransitionError`)
- Guard: order must not be `cancelled` (raise `AlreadyCancelledError`)
- Transaction: lock order, call `ApplyLedgerEntry(reversal)`, set `cancelled_at`
- **No side effects before commit** (email deferred to PR 9)

**Specs (target 95%+, ~18 examples).**

---

### PR 6: Orders::StartPayment + Orders::MarkSuccessful `feat/order-payment-services` [M]
**Depends on:** PR 5

**Orders::StartPayment:**
- Guard: order must be `created`
- Accepts payment result as injectable parameter (for testability)
- Updates: `status: :payment_pending`, `payment_provider`, `external_payment_id`

**Orders::MarkSuccessful:**
- Guard: order must be `payment_pending`
- Idempotency: if already `successful`, return silently (no double-credit)
- Transaction: lock order + account, call `ApplyLedgerEntry(credit)`, set `paid_at`
- **Successful order = credit to user account (payment received)**
- **No side effects before commit**

**Specs (target 95%+, ~18 examples).**

---

### PR 7: YooKassa Integration `feat/yookassa-integration` [L]
**Depends on:** PR 6

**lib/clients/yookassa_client.rb:**
- ENV config: `YOOKASSA_SHOP_ID`, `YOOKASSA_SECRET_KEY`
- `create_payment(amount:, currency:, description:, return_url:, idempotence_key:)`
- `get_payment(payment_id:)` --- for reconciliation
- Idempotence-Key header on all POST requests

**app/services/yookassa/create_payment.rb:**
- Build params from order, call client, store `external_payment_id`
- Return `{ confirmation_url:, payment_id: }`
- Raise `Payments::ProviderError` on failure

**app/services/yookassa/process_webhook.rb:**
- Create `WebhookEvent` (unique index catches duplicates)
- If duplicate: skip silently
- Route: `payment.succeeded` -> `Orders::MarkSuccessful`
- Mark event `processed` / `failed`

**Key priorities:** idempotent processing > IP validation, event persistence > routing.

All HTTP mocked via WebMock/VCR. Specs (~22 examples).

---

### PR 8: API Controllers `feat/api-controllers` [M]
**Depends on:** PR 7

**No auth.** Public demo API. Frontend uses seeded demo user.

```ruby
resources :orders, only: [:index, :show, :create] do
  member { post :pay; post :cancel }
end
resources :accounts, only: [:show]
namespace :webhooks { post :yookassa, to: 'yookassa#create' }
```

- `OrdersController` --- thin (max 15 lines/action), delegates to services
- `AccountsController` --- show with balance + ledger
- `Webhooks::YookassaController` --- validate IP, enqueue job, return 200
- `concerns/error_handler.rb` --- rescue `ApplicationError`, render structured JSON

**API error format:** `{ "error": { "code": "...", "message": "..." } }`

Request specs (~30 examples).

---

### PR 9: Jobs + Mailer + NotificationLog `feat/async-email` [M]
**Depends on:** PR 8

- `SendOrderEmailJob` (queue: mailers) --- check NotificationLog, send, record
- `ProcessWebhookJob` (queue: critical) --- delegate to service, 3 retries
- `ReconciliationJob` (queue: low) --- find stale `payment_pending`, re-check via API
- `OrderMailer` --- order_created, payment_successful, order_cancelled (HTML + text)

**Service modifications:** enqueue jobs AFTER transaction commits.

**Acceptance criteria:** no side effects before commit, duplicate email not sent.

Specs (~22 examples).

---

### PR 10: Integration Tests `test/integration-flows` [M]
**Depends on:** PR 9

- **Payment flow:** create -> pay -> webhook -> success (verify ledger, balance, WebhookEvent, email job)
- **Cancellation flow:** success -> cancel -> reversal (verify ledger, balance, email job)
- **Idempotency:** duplicate webhook (one ledger entry), duplicate cancel (error), **duplicate email not sent twice**

~18 examples.

---

### PR 11: ActiveAdmin + Basic Auth `feat/activeadmin` [M]
**Depends on:** PR 9. **Parallel with PR 10, 13.**

**Auth: HTTP Basic Auth via ENV** (`ADMIN_USER`, `ADMIN_PASSWORD`). NOT public.

**Resources:** Orders (+ cancel action via service), Accounts, LedgerEntries, WebhookEvents, NotificationLogs, Dashboard.

**Forbidden:** no edit of `balance_cents`, no direct status change. All via services.

Includes/preload to avoid N+1. Basic request specs (~12 examples).

---

### PR 12: Seeds `feat/seed-data` [S]
**Depends on:** PR 11

2 demo users, orders in every status (created, payment_pending, successful, cancelled), ledger entries, webhook events, notification logs.

**Uses service objects**, not direct inserts. Idempotent (can run twice).

---

### PR 13: Frontend Scaffold `feat/frontend-scaffold` [L]
**Depends on:** PR 8. **Parallel with PR 10, 11.**

**Demo-user mode:** seeded users via `UserSelector` dropdown, no login/register.

- `npm install`, Vite + Tailwind config
- Typed API client + Zod schemas + TanStack Query hooks
- Shared components: Layout, UserSelector, StatusBadge, MoneyFormat

Component tests (~8 examples).

---

### PR 14: Frontend Pages `feat/frontend-pages` [M]
**Depends on:** PR 13

- `/` Dashboard, `/orders` list, `/orders/:id` detail (pay/cancel), `/accounts/:id` balance + ledger
- No login/register pages
- All interactive elements `cursor: pointer`

Component tests (~8 examples).

---

### PR 15: Production Deploy `feat/production-deploy` [M]
**Depends on:** PR 14

- Nginx config (SSL, proxy, gzip)
- `bin/deploy` script
- `docker-compose.production.yml`
- `docs/DEPLOYMENT.md` (healthcheck, admin auth, webhook routes, mail config, punycode note)

---

## Dependency Graph

```
PR1 → PR2 → PR3 → PR4 → PR5 → PR6 → PR7 → PR8 → PR9 → PR10
                                               ├──→ PR11 → PR12
                                               └──→ PR13 → PR14 → PR15
```

---

## Summary

| PR | Title | Size | Tests |
|----|-------|------|-------|
| 1 | Rails Scaffold | L | ~5 |
| 2 | User + Account Models | M | ~10 |
| 3 | Order + Ledger + Webhook + NotificationLog | L | ~25 |
| 4 | Accounts::ApplyLedgerEntry | M | ~18 |
| 5 | Orders::Create + Cancel | M | ~18 |
| 6 | Orders::StartPayment + MarkSuccessful | M | ~18 |
| 7 | YooKassa Integration | L | ~22 |
| 8 | API Controllers | M | ~30 |
| 9 | Jobs + Mailer | M | ~22 |
| 10 | Integration Tests | M | ~18 |
| 11 | ActiveAdmin + Basic Auth | M | ~12 |
| 12 | Seeds | S | ~2 |
| 13 | Frontend Scaffold (demo-user mode) | L | ~8 |
| 14 | Frontend Pages | M | ~8 |
| 15 | Production Deploy | M | ~0 |
| **Total** | | | **~216** |

---

## If Time Gets Tight

**Cut first:** frontend dashboard stats, ActiveAdmin polish, extra pages.

**Never cut:** ledger accounting, transaction locking, idempotent webhooks, notification dedup, integration tests, architecture specs.

---

## Known Risks

| Risk | Mitigation |
|------|-----------|
| `factory_bot_lint.rb` uses `DatabaseCleaner` not in Gemfile | Add `database_cleaner-active_record` in PR 1 |
| ActiveAdmin requires Devise by default | Configure without Devise, use HTTP Basic Auth |
| `yookassa` gem v0.1 may be limited | Fallback to direct HTTP client if needed |
| SimpleCov 90% threshold on early PRs | Enforce from PR 3 onward |
| Concurrent webhook race conditions | Row-level locking + unique indexes |

---

## Verification (every PR)

- `bundle exec rspec` --- all green
- `bundle exec rubocop` --- 0 offenses
- `bin/check_coverage` --- 90% global, 95% critical domain
- CI pipeline passes
- No side effects before commit
