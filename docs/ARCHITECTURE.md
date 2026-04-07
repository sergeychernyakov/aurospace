# Architecture Invariants

> Rules that MUST hold true at all times. Violations are caught by `spec/architecture/architecture_spec.rb`, CI, and code review.

---

## Money Invariants

### Balance changes ONLY through ledger

```
Account#balance_cents is NEVER updated directly.
Every change creates a LedgerEntry first.
Balance = sum of all LedgerEntries for the account.
```

- No `account.update(balance_cents: ...)` outside `Accounts::ApplyLedgerEntry`
- No `account.increment!(:balance_cents)` anywhere
- No raw SQL updating balance

### Ledger entries are immutable

```
LedgerEntry records are NEVER updated or deleted.
Corrections are made via reversal entries.
```

- No `ledger_entry.update(...)` or `ledger_entry.destroy`
- Cancellations create a new entry with `entry_type: :reversal`
- History is append-only

### Money is always in cents

```
All monetary values stored as integers (*_cents).
Never use Float for money. Never store in decimal units.
```

- `amount_cents`, `balance_cents` --- always Integer
- Display formatting in presenters only
- Use `money-rails` for currency-aware formatting

---

## State Transition Invariants

### Order status transitions are guarded

```
created → payment_pending → successful → cancelled
                                       ↗
                            created ----  (direct cancel of unpaid)
```

- Only valid transitions are allowed
- Invalid transitions raise `Orders::InvalidTransitionError`
- Status is checked BEFORE acquiring locks
- Transition + ledger entry + balance update happen in ONE transaction

### No direct status updates (AASM enforced)

```
Order uses AASM state machine. Status transitions happen
ONLY via AASM events: start_payment!, mark_successful!, cancel!
Direct update/update!/save on status column is forbidden.
```

- `order.start_payment!` --- created -> payment_pending
- `order.mark_successful!` --- payment_pending -> successful
- `order.cancel!` --- successful -> cancelled
- `AASM::InvalidTransition` raised on invalid transitions
- Admin "Cancel" button calls `Orders::Cancel` service which calls `order.cancel!`

---

## Service Result Pattern (dry-monads)

```
All services return Dry::Monads::Result.
Success(value) for happy path.
Failure(error_symbol) for business errors.
No exceptions for expected business logic failures.
```

- Services `include Dry::Monads[:result]`
- Controllers use pattern matching: `case service.call(...) in Success(v) ... in Failure(e) ...`
- Exceptions reserved for truly unexpected errors (DB down, network failure)
- `ApplicationError` subclasses still exist for error serialization, but are not raised from services

---

## Module Boundaries (Packwerk)

```
Domain is split into packages with explicit public interfaces.
Cross-package dependencies are declared and enforced.
```

Packages:
- `orders` --- Order model, order services (Create, Cancel, StartPayment, MarkSuccessful)
- `accounts` --- Account model, LedgerEntry, ApplyLedgerEntry service
- `payments` --- YooKassa client, CreatePayment, ProcessWebhook, WebhookEvent
- `notifications` --- OrderMailer, SendOrderEmailJob, NotificationLog

Rules:
- `notifications` can depend on `orders` (to read order data for emails)
- `orders` can depend on `accounts` (to apply ledger entries)
- `orders` can depend on `payments` (to create payments)
- `accounts` cannot depend on `orders` (no circular deps)
- `payments` cannot depend on `notifications` (no circular deps)

Enforced via `bundle exec packwerk validate`.

---

## Observability (OpenTelemetry)

```
All requests, DB queries, Redis calls, Sidekiq jobs,
and external HTTP calls are automatically traced.
```

- Auto-instrumented: Rails, PG, Redis, Sidekiq, Net::HTTP
- Custom spans for critical operations: `ApplyLedgerEntry`, `ProcessWebhook`
- Trace IDs propagated through async job processing
- Disabled in test environment to avoid noise

---

## Side Effect Invariants

### External side effects ONLY after commit

```
Emails, webhooks, external API calls, and job enqueues
happen ONLY after the database transaction commits.
```

- Use `after_commit` callbacks or service-level `after_commit` blocks
- Never call `deliver_now` or `perform_later` inside a transaction
- If the transaction rolls back, no side effects should have fired

### Emails are never sent twice

```
NotificationLog tracks every sent email.
Before sending, check if (order_id, mail_type) already exists.
```

- `NotificationLog` has unique composite index on `(order_id, mail_type)`
- Email jobs check log before sending
- Webhook replay does not trigger duplicate emails

---

## Idempotency Invariants

### Webhook processing is idempotent

```
Processing the same webhook event N times
produces the same result as processing it once.
```

- `WebhookEvent` stores every incoming event
- Unique index on `external_event_id` prevents duplicate storage
- Service checks current order status before acting
- Already-processed events are logged and skipped

### Jobs are retry-safe

```
Every Sidekiq job can be retried without side effects.
```

- Jobs pass only IDs, never full objects
- Jobs re-read state from DB before acting
- Jobs check preconditions (status, existence) before proceeding

---

## Layer Invariants

### Controllers are thin

```
Controllers do:     parse params, call service, render response.
Controllers DON'T:  contain business logic, query DB directly, modify state.
```

- Max 15 lines per controller action
- No `ActiveRecord` queries in controllers (delegate to services/queries)
- No conditional business logic in controllers

### Models hold data + light invariants

```
Models do:     validations, associations, scopes, simple derived attributes.
Models DON'T:  call external APIs, enqueue jobs, send emails, modify other models.
```

- No HTTP calls from models
- No `deliver_later` from models (use `after_commit` + job at most)
- No cross-model writes (use services for orchestration)

### Services hold business logic

```
Services do:     orchestrate operations, enforce rules, coordinate transactions.
Services DON'T:  depend on controllers, access request/params, render views.
```

- One service = one use case
- Services don't reference `ActionController` or `request`
- Services can call other services

### Jobs only orchestrate

```
Jobs do:     find records, call services, handle retries.
Jobs DON'T:  contain business logic, run queries, modify data directly.
```

- No `ActiveRecord` writes in jobs
- No `where` / `update` / `create` in jobs
- Jobs delegate everything to services

### Mailers only format

```
Mailers do:     format data, render templates, set recipients.
Mailers DON'T:  modify data, run queries, enforce business rules.
```

- No `save!`, `update!`, `create!` in mailers
- Data preparation in presenters, not mailer methods

---

## Database Invariants

### Required constraints

| Table | Constraint |
|-------|-----------|
| `users` | unique index on `email` |
| `accounts` | unique index on `user_id`; `balance_cents NOT NULL DEFAULT 0` |
| `orders` | `amount_cents NOT NULL`; `status NOT NULL`; index on `user_id`, `status` |
| `ledger_entries` | FK on `account_id`, `order_id`; `amount_cents NOT NULL`; `entry_type NOT NULL` |
| `webhook_events` | unique index on `external_event_id`; index on `provider` |
| `notification_logs` | unique composite index on `(order_id, mail_type)` |

### Money columns

- Always `integer` type (`*_cents`)
- Always `NOT NULL`
- `balance_cents` defaults to `0`
- `amount_cents` must be positive (check constraint or validation)

### Timestamps

- All tables have `created_at` and `updated_at`
- `paid_at` and `cancelled_at` are nullable (set on transition)

---

## Security Invariants

### Secrets never in code

```
All credentials live in ENV or Rails credentials.
.env is in .gitignore. Pre-commit hooks scan for leaked secrets.
```

### Sensitive data never in logs

```
Rails parameter filtering strips: password, token, secret,
api_key, card_number, cvv, email, phone.
```

### Webhooks are verified

```
Incoming webhooks are validated before processing:
IP whitelist, signature verification, or status re-check via API.
```

---

## How These Are Enforced

| Invariant | Enforcement |
|-----------|-------------|
| Balance via ledger only | `spec/architecture/architecture_spec.rb` |
| Thin controllers | `spec/architecture/architecture_spec.rb` |
| No API calls from models | `spec/architecture/architecture_spec.rb` |
| Jobs don't write DB | `spec/architecture/architecture_spec.rb` |
| No debug statements | Pre-commit hook + architecture spec |
| Commit format | `commit-msg` hook (lefthook) |
| Coverage thresholds | SimpleCov + `bin/check_coverage` |
| DB constraints match validations | `database_consistency` gem |
| Safe migrations | `strong_migrations` gem |
| No N+1 queries | `bullet` gem (raises in test) |
| No secrets in code | Pre-commit hook + CI secret scan |
| PR quality | Dangerfile + PR template |
