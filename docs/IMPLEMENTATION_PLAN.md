# AUROSPACE Orders Demo --- Implementation Plan

## Scope

### In Scope
- Domain correctness (ledger-based accounting)
- Payment processing (YooKassa)
- Declarative order state transitions (AASM)
- Webhook idempotency
- Async notifications with duplicate protection
- Explicit service result contracts (dry-monads)
- Enforced architectural boundaries (Packwerk + architecture specs)
- Auto-generated API documentation (OpenAPI / Swagger)
- Production-style observability (OpenTelemetry)
- Admin panel (ActiveAdmin)
- Production-style deployment

### Out of Scope
- User authentication and registration
- Role-based access control for end users
- Full production hardening of administrative access

> Authentication is intentionally outside the assignment scope.
> ActiveAdmin is protected with Basic Auth (env credentials) for demo safety.
> Frontend works in demo-user mode with seeded users.

---

## Financial Semantics (CRITICAL)

User pays for an order via YooKassa. Successful payment = **credit to user's account**.

| Event | Ledger Operation | Balance Effect |
|-------|-----------------|----------------|
| Payment successful | `credit` | balance increases |
| Order cancelled | `reversal` | balance decreases (compensating entry) |

**Invariants:**
- `balance_cents` is NEVER updated directly
- Every change creates an immutable `LedgerEntry`
- Reversals are compensating entries, not deletions

---

## Service Result Pattern (dry-monads)

All services return `Success(value)` or `Failure(error)`. No exceptions for business logic.

```ruby
class Orders::Create
  include Dry::Monads[:result]

  def call(user:, amount_cents:, currency: 'RUB')
    # Validations BEFORE transaction
    return Failure(:invalid_amount) unless amount_cents.positive?
    return Failure(:account_missing) unless user.account

    order = Order.create!(user: user, amount_cents: amount_cents, currency: currency)
    Success(order)
  rescue ActiveRecord::RecordInvalid => e
    Failure(e.record.errors)
  end
end
```

**Safety rule for transactions:** validations and guard checks go BEFORE the transaction block. Inside a transaction, either everything succeeds or we raise to trigger rollback. Never `return Failure(...)` after partial writes inside a transaction.

```ruby
# CORRECT pattern for transactional services:
def call(account:, order:, entry_type:, amount_cents:)
  # 1. Validate BEFORE transaction
  return Failure(:invalid_amount) unless amount_cents.positive?
  return Failure(:currency_mismatch) if order.currency != account.currency

  # 2. Transaction: all or nothing
  entry = ActiveRecord::Base.transaction do
    account.lock!
    delta = calculate_delta(entry_type, amount_cents)

    if (account.balance_cents + delta).negative?
      raise Accounts::InsufficientFundsError  # rollback via exception
    end

    entry = LedgerEntry.create!(...)
    account.update!(balance_cents: account.balance_cents + delta)
    entry
  end

  Success(entry)
rescue Accounts::InsufficientFundsError
  Failure(:insufficient_funds)
end
```

---

## State Machine (AASM)

```ruby
class Order < ApplicationRecord
  include AASM

  aasm column: :status, enum: true do
    state :created, initial: true
    state :payment_pending, :successful, :cancelled

    event :start_payment do
      transitions from: :created, to: :payment_pending
    end
    event :mark_successful do
      transitions from: :payment_pending, to: :successful
    end
    event :cancel do
      transitions from: :successful, to: :cancelled
    end
  end
end
```

---

## Packwerk Module Boundaries

Packages: `orders`, `accounts`, `payments`, `notifications`.

Start with Packwerk config + architecture specs in PR 1. Enforce incrementally as packages are built.

---

## PR Sequence

### PR 1: Rails Scaffold `feat/rails-scaffold` [L]

Generate Rails API skeleton. Configure foundational tools.

**Create:**
- Rails skeleton: `config/application.rb`, `config/environment.rb`, `config/environments/*.rb`, `config/routes.rb`, `config/database.yml`, `config/puma.rb`, `config/boot.rb`, `config.ru`, `Rakefile`
- `config/sidekiq.yml` (queues: critical, default, mailers, low)
- `config/initializers/cors.rb`, `sidekiq.rb`, `money.rb`, `dry_monads.rb`
- `app/controllers/application_controller.rb`
- `app/models/application_record.rb`
- `app/jobs/application_job.rb`, `app/mailers/application_mailer.rb`
- `spec/spec_helper.rb`, `spec/rails_helper.rb`, `spec/swagger_helper.rb`
- `packwerk.yml`, `package.yml` (root package, no strict enforcement yet)
- `Gemfile.lock` (via `bundle install`)

**Modify:**
- `Gemfile` --- add `database_cleaner-active_record`

**NOT in this PR:** OpenTelemetry instrumentation (nothing to trace yet).

**Verification:** `bundle exec rspec` (0 examples), `bundle exec rubocop` passes, `bundle exec packwerk validate` passes.

---

### PR 2: User + Account Models `feat/user-account-models` [M]
**Depends on:** PR 1

**User** --- just data, no auth:
- Fields: `email` (unique, NOT NULL), `name` (NOT NULL)
- `has_one :account`, `has_many :orders`

**Account:**
- Fields: `user_id` (unique FK), `balance_cents` (NOT NULL, DEFAULT 0), `currency` (NOT NULL, DEFAULT 'RUB')
- `belongs_to :user`, `has_many :ledger_entries`

**DB constraints:** unique indexes, foreign keys, NOT NULL.

Factories + model specs (~10 examples).

---

### PR 3: Order (AASM) + LedgerEntry + WebhookEvent + NotificationLog `feat/order-ledger-models` [L]
**Depends on:** PR 2

**Order with AASM:**
- `status` via AASM: `created` -> `payment_pending` -> `successful` -> `cancelled`
- Events: `start_payment!`, `mark_successful!`, `cancel!`
- `amount_cents` NOT NULL, `currency`, `payment_provider`, `external_payment_id`, `paid_at`, `cancelled_at`
- Indexes on `user_id`, `status`

**LedgerEntry:**
- FK `account_id`, `order_id` (NOT NULL), `entry_type` enum, `amount_cents` NOT NULL
- `reference`, `metadata` (jsonb)
- **Immutable after creation**

**WebhookEvent:**
- `external_event_id` unique index, `payload` jsonb, `status` DEFAULT 'pending'

**NotificationLog:**
- Unique composite `(order_id, mail_type)`

Factories + model specs including AASM transition tests (~30 examples).

---

### PR 4: Accounts::ApplyLedgerEntry `feat/accounts-ledger-service` [M]
**Depends on:** PR 3. **THE most critical service.**

Returns `dry-monads Result`. Validates BEFORE transaction, raises inside transaction for rollback.

**Algorithm:**
1. Validate before transaction: `amount_cents > 0`, currency match
2. Transaction: `account.lock!`, create LedgerEntry, update balance
3. Insufficient funds: raise inside transaction (triggers rollback), rescue to `Failure(:insufficient_funds)`

**Locking:** pessimistic row lock (`SELECT ... FOR UPDATE`). Full rollback on failure.

Specs (target 95%+, ~20 examples): Success/Failure paths, atomicity, concurrency.

---

### PR 5: Orders::Create + Orders::Cancel `feat/order-create-cancel` [M]
**Depends on:** PR 4

Both return `dry-monads Result`. Cancel uses AASM `order.cancel!`.

**Orders::Create:** validate before write. `Success(order)` or `Failure(:invalid_amount)`.

**Orders::Cancel:** `order.may_cancel?` (AASM guard), transaction with lock + reversal + `order.cancel!`. **No side effects before commit.**

Specs (target 95%+, ~18 examples).

---

### PR 6: Orders::StartPayment + Orders::MarkSuccessful `feat/order-payment-services` [M]
**Depends on:** PR 5

**StartPayment:** AASM `order.may_start_payment?`, `order.start_payment!`. Injectable payment result param.

**MarkSuccessful:** idempotent (if already successful, return `Success`). Transaction: lock + credit + `order.mark_successful!` + set `paid_at`. **No side effects before commit.**

Specs (target 95%+, ~18 examples).

---

### PR 7: YooKassa Integration `feat/yookassa-integration` [L]
**Depends on:** PR 6

**lib/clients/yookassa_client.rb:** create/get payment, Idempotence-Key header.

**Yookassa::CreatePayment** --- `Success({ confirmation_url:, payment_id: })` or `Failure(:provider_error)`.

**Yookassa::ProcessWebhook** --- idempotent: store WebhookEvent, route by event_type, `Success(:processed)` / `Success(:duplicate)` / `Failure(:unknown_order)`.

All HTTP mocked via WebMock/VCR. Specs (~22 examples).

---

### PR 8: API Controllers + rswag + OpenTelemetry `feat/api-controllers` [L]
**Depends on:** PR 7

**OpenTelemetry added HERE** (not PR 1) --- now there are requests, DB, Redis, HTTP to trace.

**Create:**
- `config/initializers/opentelemetry.rb` --- instrument Rails, PG, Redis, Sidekiq, Net::HTTP
- Custom spans for `ApplyLedgerEntry`, `ProcessWebhook`

Controllers use `dry-monads` pattern matching:
```ruby
case Orders::Create.new.call(...)
in Success(order) then render json: order, status: :created
in Failure(:invalid_amount) then render_error('invalid_amount', :unprocessable_entity)
end
```

**rswag specs** generate OpenAPI docs. Swagger UI at `/api-docs`.

Request specs + rswag specs (~35 examples).

---

### PR 9: Jobs (sidekiq-unique-jobs) + Mailer `feat/async-email` [M]
**Depends on:** PR 8

**sidekiq-unique-jobs** prevents duplicate execution:
```ruby
class SendOrderEmailJob < ApplicationJob
  sidekiq_options lock: :until_executed, queue: 'mailers'
end
```

- `ProcessWebhookJob` (queue: critical, 3 retries)
- `ReconciliationJob` (queue: low)
- `OrderMailer` --- HTML + text, no business logic
- Services enqueue AFTER commit

**Double protection:** sidekiq-unique-jobs (queue level) + NotificationLog (DB level).

Specs (~22 examples).

---

### PR 10: Integration Tests `test/integration-flows` [M]
**Depends on:** PR 9

- **Payment flow:** create -> pay -> webhook -> success
- **Cancellation flow:** success -> cancel -> reversal
- **Idempotency:** duplicate webhook, duplicate cancel, duplicate email
- **AASM guards:** invalid transitions at integration level
- Tracing verification: smoke-level check that spans are created (not hard assertions)

~20 examples.

---

### PR 11: ActiveAdmin + Basic Auth `feat/activeadmin` [M]
**Depends on:** PR 9. **Parallel with PR 10, 13.**

HTTP Basic Auth via `ADMIN_USER` / `ADMIN_PASSWORD` from ENV.

Resources: Orders (AASM status, cancel via service), Accounts, LedgerEntries, WebhookEvents, NotificationLogs, Dashboard.

No direct balance/status editing. N+1 prevention.

Request specs (~12 examples).

---

### PR 12: Seeds `feat/seed-data` [S]
**Depends on:** PR 11

2 demo users, orders in every AASM state, ledger entries, webhook events, notification logs. Uses service objects. Idempotent.

---

### PR 13: Frontend Scaffold `feat/frontend-scaffold` [L]
**Depends on:** PR 8. **Parallel with PR 10, 11.**

Demo-user mode (UserSelector). Typed API client (can use OpenAPI schema from rswag). TanStack Query hooks. Shared components.

Component tests (~8 examples).

---

### PR 14: Frontend Pages `feat/frontend-pages` [M]
**Depends on:** PR 13

Dashboard, Orders list, Order detail (AASM-aware buttons), Account + ledger. No login/register. `cursor: pointer`.

Component tests (~8 examples).

---

### PR 15: Production Deploy `feat/production-deploy` [M]
**Depends on:** PR 14

- Nginx config (SSL, proxy, gzip)
- `bin/deploy` script
- `docker-compose.production.yml` (+ optional OTEL collector)
- `docs/DEPLOYMENT.md`

**Deploy verification tests (~5):**
- `docker compose build` succeeds
- `docker compose up` starts all services
- `curl /up` returns 200 (liveness)
- `curl /health` returns 200 with `database: ok`, `redis: ok` (readiness)
- Nginx config passes `nginx -t` syntax check

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
| 1 | Rails Scaffold + Packwerk init + dry-monads | L | ~5 |
| 2 | User + Account Models | M | ~10 |
| 3 | Order (AASM) + LedgerEntry + Webhook + NotificationLog | L | ~30 |
| 4 | Accounts::ApplyLedgerEntry (dry-monads Result) | M | ~20 |
| 5 | Orders::Create + Cancel | M | ~18 |
| 6 | Orders::StartPayment + MarkSuccessful | M | ~18 |
| 7 | YooKassa Integration | L | ~22 |
| 8 | API Controllers + rswag + OpenTelemetry | L | ~35 |
| 9 | Jobs (sidekiq-unique-jobs) + Mailer | M | ~22 |
| 10 | Integration Tests | M | ~20 |
| 11 | ActiveAdmin + Basic Auth | M | ~12 |
| 12 | Seeds | S | ~2 |
| 13 | Frontend Scaffold (demo-user mode) | L | ~8 |
| 14 | Frontend Pages | M | ~8 |
| 15 | Production Deploy + smoke tests | M | ~5 |
| **Total** | | | **~235** |

---

## Sacred Invariants (never cut)

These are the heart of the project. Everything else is an amplifier.

- Ledger-based accounting (balance via entries only)
- State transition correctness (AASM guards)
- Idempotent webhook processing
- After-commit discipline (no side effects in transactions)
- Notification deduplication (NotificationLog + sidekiq-unique-jobs)
- Integration tests (full payment + cancellation flows)
- DB constraints (NOT NULL, unique indexes, foreign keys, row locking)
- Row locking on all money-affecting flows

---

## If Time Gets Tight

**Cut first:** frontend dashboard stats, ActiveAdmin polish, OTEL collector setup, Packwerk strict mode.

**Never cut:** the Sacred Invariants above.

---

## Known Risks

| Risk | Mitigation |
|------|-----------|
| `factory_bot_lint.rb` uses `DatabaseCleaner` | Add `database_cleaner-active_record` in PR 1 |
| ActiveAdmin requires Devise | Configure without Devise, HTTP Basic Auth |
| `yookassa` gem v0.1 limited | Fallback to direct HTTP client |
| dry-monads `Failure()` inside transaction | Validate BEFORE transaction, raise inside for rollback |
| Packwerk learning curve | Start with config, enforce incrementally |
| OpenTelemetry overhead | Disable in test, sample in production |

---

## Verification (every PR)

- `bundle exec rspec` --- all green
- `bundle exec rubocop` --- 0 offenses
- `bundle exec packwerk validate` --- no boundary violations
- `bin/check_coverage` --- 90% global, 95% critical domain
- CI pipeline passes
- No side effects before commit
