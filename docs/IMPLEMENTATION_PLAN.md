# AUROSPACE Orders Demo --- Implementation Plan

## Scope

### In Scope
- Domain correctness (ledger-based accounting)
- Payment processing (YooKassa)
- Ledger consistency and state transitions (AASM)
- Webhook idempotency
- Async notifications with duplicate protection (sidekiq-unique-jobs)
- Admin observability (ActiveAdmin)
- API documentation (rswag / OpenAPI)
- Distributed tracing (OpenTelemetry)
- Module boundaries (Packwerk)
- Typed service results (dry-monads)
- Production-style deployment

### Out of Scope
- User authentication and registration
- Role-based access control for end users
- Full production hardening of administrative access

> Authentication is intentionally outside the assignment scope.
> ActiveAdmin is protected with Basic Auth (env credentials) for demo safety.
> Frontend works in demo-user mode with seeded users.

---

## Tech Stack Additions

| Tool | Purpose | Where |
|------|---------|-------|
| **AASM** | Declarative state machine for Order | Model layer |
| **dry-monads** | `Result(Success/Failure)` for all services | Service layer |
| **Packwerk** | Enforced module boundaries (orders, accounts, payments) | Architecture |
| **rswag** | Auto-generated OpenAPI/Swagger from RSpec | API docs |
| **sidekiq-unique-jobs** | Duplicate job prevention at queue level | Jobs |
| **OpenTelemetry** | Distributed tracing (requests, DB, Redis, Sidekiq, HTTP) | Observability |

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
    return Failure(:invalid_amount) unless amount_cents.positive?

    order = Order.create!(user: user, amount_cents: amount_cents, currency: currency)
    Success(order)
  rescue ActiveRecord::RecordInvalid => e
    Failure(e.record.errors)
  end
end

# Controller usage:
case Orders::Create.new.call(user: user, amount_cents: params[:amount_cents])
in Success(order) then render json: order, status: :created
in Failure(error) then render json: { error: error }, status: :unprocessable_entity
end
```

---

## State Machine (AASM)

Order status transitions are declarative, not scattered across services:

```ruby
class Order < ApplicationRecord
  include AASM

  aasm column: :status, enum: true do
    state :created, initial: true
    state :payment_pending
    state :successful
    state :cancelled

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

Services call `order.start_payment!` / `order.mark_successful!` / `order.cancel!` ---
AASM raises `AASM::InvalidTransition` on invalid transitions (mapped to `Orders::InvalidTransitionError`).

---

## Packwerk Module Boundaries

```
packages/
  orders/         # Order model, order services, order jobs
  accounts/       # Account model, ledger service
  payments/       # YooKassa client, payment services, webhook processing
  notifications/  # Mailer, SendOrderEmailJob, NotificationLog
```

Packwerk enforces: orders cannot directly access payment internals, notifications cannot modify account balance, etc. Public interfaces defined via `public/` directories.

Alternative: if full Packwerk packages feel heavy, enforce boundaries via `spec/architecture/` + directory convention without moving files into `packages/`.

**Decision: start with architecture specs (already exist), add Packwerk config in PR 1, enforce incrementally.**

---

## PR Sequence

### PR 1: Rails Scaffold `feat/rails-scaffold` [L]

Generate Rails API skeleton. Configure all foundational tools.

**Create:**
- Rails skeleton: `config/application.rb`, `config/environment.rb`, `config/environments/*.rb`, `config/routes.rb`, `config/database.yml`, `config/puma.rb`, `config/boot.rb`, `config.ru`, `Rakefile`
- `config/sidekiq.yml` (queues: critical, default, mailers, low)
- `config/initializers/cors.rb`, `sidekiq.rb`, `money.rb`
- `config/initializers/opentelemetry.rb` --- instrument Rails, PG, Redis, Sidekiq, Net::HTTP
- `config/initializers/dry_monads.rb` --- configure
- `app/controllers/application_controller.rb`
- `app/models/application_record.rb`
- `app/jobs/application_job.rb`, `app/mailers/application_mailer.rb`
- `spec/spec_helper.rb`, `spec/rails_helper.rb`
- `spec/swagger_helper.rb` (rswag config)
- `packwerk.yml`, `package.yml` (root package config)
- `Gemfile.lock` (via `bundle install`)

**Modify:**
- `Gemfile` --- add `database_cleaner-active_record`

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

### PR 3: Order + LedgerEntry + WebhookEvent + NotificationLog `feat/order-ledger-models` [L]
**Depends on:** PR 2

**Order with AASM:**
- `amount_cents` NOT NULL, `currency` NOT NULL DEFAULT 'RUB'
- `status` enum via AASM: `created` -> `payment_pending` -> `successful` -> `cancelled`
- AASM events: `start_payment!`, `mark_successful!`, `cancel!`
- `payment_provider`, `external_payment_id`, `paid_at`, `cancelled_at`
- Indexes on `user_id`, `status`

**LedgerEntry:**
- FK `account_id`, `order_id` (NOT NULL)
- `entry_type` enum: `{ debit: 0, credit: 1, reversal: 2 }`
- `amount_cents` NOT NULL, `reference`, `metadata` (jsonb)
- **Immutable:** `before_update`/`before_destroy` raise

**WebhookEvent:**
- `external_event_id` unique index, `payload` jsonb, `status` DEFAULT 'pending'

**NotificationLog:**
- Unique composite `(order_id, mail_type)`

Factories + model specs including AASM transition tests (~30 examples).

---

### PR 4: Accounts::ApplyLedgerEntry `feat/accounts-ledger-service` [M]
**Depends on:** PR 3. **THE most critical service.**

Returns `dry-monads Result`:

```ruby
class Accounts::ApplyLedgerEntry
  include Dry::Monads[:result]

  def call(account:, order:, entry_type:, amount_cents:, reference: nil)
    return Failure(:invalid_amount) unless amount_cents.positive?
    return Failure(:currency_mismatch) if order.currency != account.currency

    ActiveRecord::Base.transaction do
      account.lock!
      delta = calculate_delta(entry_type, amount_cents)

      if entry_type == :debit && (account.balance_cents + delta).negative?
        return Failure(:insufficient_funds)
      end

      entry = LedgerEntry.create!(...)
      account.update!(balance_cents: account.balance_cents + delta)
      Success(entry)
    end
  end
end
```

**Locking:** pessimistic row lock (`SELECT ... FOR UPDATE`). Full rollback on failure.

Specs (target 95%+, ~20 examples): Success/Failure paths, atomicity, concurrency.

---

### PR 5: Orders::Create + Orders::Cancel `feat/order-create-cancel` [M]
**Depends on:** PR 4

Both return `dry-monads Result`. Cancel uses AASM `order.cancel!`.

**Orders::Create:** `Success(order)` or `Failure(:invalid_amount)`

**Orders::Cancel:**
- `order.may_cancel?` check (AASM guard)
- Transaction: lock, `ApplyLedgerEntry(reversal)`, `order.cancel!`, set `cancelled_at`
- `Success(order)` or `Failure(:invalid_transition)` / `Failure(:already_cancelled)`
- **No side effects before commit**

Specs (target 95%+, ~18 examples).

---

### PR 6: Orders::StartPayment + Orders::MarkSuccessful `feat/order-payment-services` [M]
**Depends on:** PR 5

**Orders::StartPayment:**
- `order.may_start_payment?` (AASM), `order.start_payment!`
- `Success({ confirmation_url:, payment_id: })` or `Failure(:invalid_transition)`

**Orders::MarkSuccessful:**
- Idempotency: if `order.successful?`, return `Success(order)` (no double-credit)
- Transaction: lock, `ApplyLedgerEntry(credit)`, `order.mark_successful!`, set `paid_at`
- `Success(order)` or `Failure(:invalid_transition)`
- **No side effects before commit**

Specs (target 95%+, ~18 examples).

---

### PR 7: YooKassa Integration `feat/yookassa-integration` [L]
**Depends on:** PR 6

**lib/clients/yookassa_client.rb:**
- OpenTelemetry auto-instruments Net::HTTP calls
- `create_payment(...)` with Idempotence-Key header
- `get_payment(payment_id:)` for reconciliation

**Yookassa::CreatePayment** --- returns `Success({ confirmation_url:, payment_id: })` or `Failure(:provider_error)`

**Yookassa::ProcessWebhook** --- returns `Success(:processed)`, `Success(:duplicate)`, or `Failure(:unknown_order)`

All HTTP mocked via WebMock/VCR. Specs (~22 examples).

---

### PR 8: API Controllers + rswag `feat/api-controllers` [M]
**Depends on:** PR 7

Controllers use `dry-monads` pattern matching:
```ruby
def create
  case Orders::Create.new.call(user: @user, amount_cents: params[:amount_cents])
  in Success(order) then render json: order, status: :created
  in Failure(:invalid_amount) then render_error('invalid_amount', :unprocessable_entity)
  end
end
```

**rswag specs** generate OpenAPI docs:
```ruby
# spec/requests/orders_spec.rb (rswag format)
path '/orders' do
  post 'Create order' do
    tags 'Orders'
    consumes 'application/json'
    parameter name: :order, in: :body, schema: { ... }
    response '201', 'order created' do
      run_test!
    end
  end
end
```

Swagger UI available at `/api-docs`.

Request specs + rswag specs (~35 examples).

---

### PR 9: Jobs + Mailer + NotificationLog `feat/async-email` [M]
**Depends on:** PR 8

**sidekiq-unique-jobs** prevents duplicate job execution:
```ruby
class SendOrderEmailJob < ApplicationJob
  sidekiq_options lock: :until_executed,
                  lock_args_method: ->(args) { args },
                  queue: 'mailers'
end

class ProcessWebhookJob < ApplicationJob
  sidekiq_options lock: :until_executed,
                  lock_args_method: ->(args) { [args.first] },
                  queue: 'critical'
  retry_on StandardError, wait: :polynomially_longer, attempts: 3
end
```

- `ReconciliationJob` (queue: low) --- stale `payment_pending` re-check
- `OrderMailer` --- HTML + text, no business logic
- Services enqueue jobs AFTER commit

**Double protection:** `sidekiq-unique-jobs` at queue level + `NotificationLog` at DB level.

Specs (~22 examples).

---

### PR 10: Integration Tests `test/integration-flows` [M]
**Depends on:** PR 9

- **Payment flow:** create -> pay -> webhook -> success (verify ledger, balance, email, tracing spans)
- **Cancellation flow:** success -> cancel -> reversal
- **Idempotency:** duplicate webhook, duplicate cancel, duplicate email
- **AASM guard tests:** invalid transitions at integration level

~20 examples.

---

### PR 11: ActiveAdmin + Basic Auth `feat/activeadmin` [M]
**Depends on:** PR 9. **Parallel with PR 10, 13.**

HTTP Basic Auth via `ADMIN_USER` / `ADMIN_PASSWORD` from ENV.

Resources: Orders (AASM status displayed, cancel via service), Accounts, LedgerEntries, WebhookEvents, NotificationLogs, Dashboard.

No direct balance/status editing. N+1 prevention with includes.

Basic request specs (~12 examples).

---

### PR 12: Seeds `feat/seed-data` [S]
**Depends on:** PR 11

2 demo users, orders in every AASM state, ledger entries, webhook events, notification logs. Uses service objects. Idempotent.

---

### PR 13: Frontend Scaffold `feat/frontend-scaffold` [L]
**Depends on:** PR 8. **Parallel with PR 10, 11.**

Demo-user mode (UserSelector dropdown). Typed API client from rswag/OpenAPI schema. TanStack Query hooks. Shared components.

Component tests (~8 examples).

---

### PR 14: Frontend Pages `feat/frontend-pages` [M]
**Depends on:** PR 13

Dashboard, Orders list, Order detail (with AASM-aware action buttons), Account + ledger. No login/register. `cursor: pointer` on interactive elements.

Component tests (~8 examples).

---

### PR 15: Production Deploy `feat/production-deploy` [M]
**Depends on:** PR 14

- Nginx config (SSL, proxy, gzip)
- `bin/deploy` script
- `docker-compose.production.yml` (+ OpenTelemetry collector container optional)
- `docs/DEPLOYMENT.md`

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
| 1 | Rails Scaffold + OTEL + Packwerk + dry-monads | L | ~5 |
| 2 | User + Account Models | M | ~10 |
| 3 | Order (AASM) + LedgerEntry + Webhook + NotificationLog | L | ~30 |
| 4 | Accounts::ApplyLedgerEntry (dry-monads Result) | M | ~20 |
| 5 | Orders::Create + Cancel | M | ~18 |
| 6 | Orders::StartPayment + MarkSuccessful | M | ~18 |
| 7 | YooKassa Integration | L | ~22 |
| 8 | API Controllers + rswag (OpenAPI) | M | ~35 |
| 9 | Jobs (sidekiq-unique-jobs) + Mailer | M | ~22 |
| 10 | Integration Tests | M | ~20 |
| 11 | ActiveAdmin + Basic Auth | M | ~12 |
| 12 | Seeds | S | ~2 |
| 13 | Frontend Scaffold (demo-user mode) | L | ~8 |
| 14 | Frontend Pages | M | ~8 |
| 15 | Production Deploy | M | ~0 |
| **Total** | | | **~230** |

---

## If Time Gets Tight

**Cut first:** frontend dashboard stats, ActiveAdmin polish, OpenTelemetry collector, Packwerk strict enforcement.

**Never cut:** ledger accounting, AASM transitions, dry-monads Results, transaction locking, idempotent webhooks, notification dedup, integration tests.

---

## Known Risks

| Risk | Mitigation |
|------|-----------|
| `factory_bot_lint.rb` uses `DatabaseCleaner` | Add `database_cleaner-active_record` in PR 1 |
| ActiveAdmin requires Devise | Configure without Devise, HTTP Basic Auth |
| `yookassa` gem v0.1 limited | Fallback to direct HTTP client |
| dry-monads pattern matching requires Ruby 3.x | Ruby 3.2 is already pinned |
| Packwerk learning curve | Start with architecture specs, add Packwerk incrementally |
| OpenTelemetry overhead | Disable in test env, sample in production |

---

## Verification (every PR)

- `bundle exec rspec` --- all green
- `bundle exec rubocop` --- 0 offenses
- `bundle exec packwerk validate` --- no boundary violations
- `bin/check_coverage` --- 90% global, 95% critical domain
- CI pipeline passes
- No side effects before commit
