# Architecture Invariants

> Rules that MUST hold true at all times. Violations are caught by `spec/architecture/architecture_spec.rb`, CI, and code review.

---

## Money Invariants

### Balance changes ONLY through ledger

```
Account#balance_cents is NEVER updated directly.
Every balance-affecting operation must create a corresponding immutable
LedgerEntry within the same database transaction.
account.balance_cents is a cached aggregate and must remain consistent
with the sum of all ledger entries for that account.
```

- No `account.update(balance_cents: ...)` outside `Accounts::ApplyLedgerEntry`
- No `account.increment!(:balance_cents)` anywhere
- No raw SQL, `update_all`, or `update_columns` bypassing invariants for money-affecting fields

### Locking Invariant

```
All money-affecting operations must acquire a pessimistic lock on the
affected account row before applying ledger changes.
Order row must also be locked before state transition in money-affecting workflows.
```

- `account.lock!` (`SELECT ... FOR UPDATE`) before any balance change
- Lock acquired INSIDE the transaction, not before it
- If two concurrent operations target the same account, one waits

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

### Order lifecycle (AASM)

```
created → payment_pending → successful → cancelled
```

Only `successful` orders can be cancelled. Cancelling an unpaid (`created` / `payment_pending`) order is not supported --- the order simply expires or remains in its current state.

Cancellation always means a compensating reversal entry in the ledger.

### Transition safety

```
Transition preconditions may be checked optimistically before locking,
but the authoritative status check must happen inside the locked transaction.
```

- AASM guards validate transitions declaratively
- Services acquire locks before calling AASM events
- `AASM::InvalidTransition` is caught and mapped to `Failure(:invalid_transition)`

### No direct status updates (AASM enforced)

```
Order uses AASM state machine. Status transitions happen
ONLY via AASM events: start_payment!, mark_successful!, cancel!
Direct update/update!/save on status column is forbidden.
```

- `order.start_payment!` --- created -> payment_pending
- `order.mark_successful!` --- payment_pending -> successful
- `order.cancel!` --- successful -> cancelled
- Admin "Cancel" button calls `Orders::Cancel` service which calls `order.cancel!`

---

## Service Result Pattern (dry-monads)

```
Expected domain outcomes are represented via Success/Failure results.
Exceptions are reserved for unexpected framework or infrastructure failures.
```

- Services `include Dry::Monads[:result]`
- Controllers use pattern matching: `case service.call(...) in Success(v) ... in Failure(e) ...`
- `ApplicationError` subclasses exist for error serialization at the API boundary
- Inside transactions: validations go BEFORE the block; `raise` inside for rollback; `rescue` maps to `Failure`

---

## Module Boundaries (Packwerk)

```
Domain is split into packages with explicit public interfaces.
Cross-package dependencies are declared, acyclic, and enforced.
```

Packages:
- `orders` --- Order model, order services (Create, Cancel, StartPayment, MarkSuccessful)
- `accounts` --- Account model, LedgerEntry, ApplyLedgerEntry service
- `payments` --- YooKassa client, CreatePayment, ProcessWebhook, WebhookEvent
- `notifications` --- OrderMailer, SendOrderEmailJob, NotificationLog

Rules:
- `notifications` can depend on `orders` (to read order data for emails)
- `orders` can depend on `accounts` (to apply ledger entries)
- `payments` cannot depend on `notifications` (no circular deps)
- `accounts` cannot depend on `orders` (no circular deps)
- Order workflows may trigger payment initiation through a payment service boundary, but package-level dependencies must remain acyclic

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
- Disabled by default in test environment; explicitly enabled for tracing smoke/integration verification where needed

---

## Side Effect Invariants

### External side effects ONLY after commit

```
Emails, webhooks, external API calls, and job enqueues
happen ONLY after the database transaction commits.
```

- Use `after_commit` callbacks or enqueue outside the transaction block
- Never call `deliver_now` or `perform_later` inside a transaction
- If the transaction rolls back, no side effects should have fired

### Emails are never sent twice

```
NotificationLog tracks every sent email.
Before sending, check if (order_id, mail_type) already exists.
```

- `NotificationLog` has unique composite index on `(order_id, mail_type)`
- Email jobs check log before sending
- sidekiq-unique-jobs provides queue-level deduplication as additional layer
- Webhook replay does not trigger duplicate emails

---

## Idempotency Invariants

### Webhook processing is idempotent

```
Processing the same webhook event N times
produces the same result as processing it once.
Webhook processing must tolerate duplicate, delayed,
and out-of-order provider events.
```

- `WebhookEvent` stores every incoming event
- Unique index on `external_event_id` prevents duplicate storage
- Service checks current order status before acting
- Already-processed events are logged and skipped
- Out-of-order events (e.g., `payment.canceled` arriving after order already cancelled) are handled gracefully

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

### Jobs: orchestration only

```
Jobs may perform minimal record lookup by ID, but must not contain
business decision logic or direct domain write orchestration.
All state-changing operations must be delegated to services.
```

- Jobs load records by ID, then call services
- No `where` / `update!` / `create!` with business logic in jobs
- Jobs delegate everything to services

### Mailers: formatting only

```
Mailers should avoid domain queries and must not enforce business rules
or perform writes. Presentation data should preferably be prepared
by presenters or calling services.
```

- No `save!`, `update!`, `create!` in mailers
- Mailers may load order by ID if needed, but no business logic
- Data preparation in presenters when practical

---

## Admin Safety Invariant

```
Admin UI is observational by default.
Dangerous actions are explicit and routed through services only.
Admin never edits financial state directly.
```

- No direct editing of `balance_cents` in admin
- No status change via select/dropdown in admin
- "Cancel order" action calls `Orders::Cancel` service
- Admin protected with Basic Auth (ENV credentials)
- All admin data views use `includes` to prevent N+1

---

## API Contract Invariant

```
Public API responses and error shapes are documented via OpenAPI (rswag)
and must remain consistent with generated documentation.
```

- Structured error format: `{ "error": { "code": "...", "message": "..." } }`
- rswag specs generate OpenAPI schema from tests
- Swagger UI available at `/api-docs`
- Breaking API changes require explicit documentation update

---

## Database Invariants

### Required constraints

| Table | Constraint |
|-------|-----------|
| `users` | unique index on `email` |
| `accounts` | unique index on `user_id`; `balance_cents NOT NULL DEFAULT 0` |
| `orders` | `amount_cents NOT NULL`; `status NOT NULL`; index on `user_id`, `status`; CHECK `amount_cents > 0` |
| `ledger_entries` | FK on `account_id`, `order_id`; `amount_cents NOT NULL`; `entry_type NOT NULL` |
| `webhook_events` | unique index on `external_event_id`; index on `provider` |
| `notification_logs` | unique composite index on `(order_id, mail_type)` |

### Check constraints

- `orders.amount_cents > 0` --- orders must have positive amount
- `accounts.balance_cents >= 0` --- overdraft is not supported (if applicable to domain)
- `ledger_entries.amount_cents > 0` --- entries record positive amounts, direction via `entry_type`

### Money columns

- Always `integer` type (`*_cents`)
- Always `NOT NULL`
- `balance_cents` defaults to `0`

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
| Locking on money operations | Service code + integration tests |
| Thin controllers | `spec/architecture/architecture_spec.rb` |
| No API calls from models | `spec/architecture/architecture_spec.rb` |
| Jobs don't write DB | `spec/architecture/architecture_spec.rb` |
| AASM state transitions | AASM gem + model specs |
| Service result contracts | dry-monads + service specs |
| Module boundaries | Packwerk + `packwerk validate` in CI |
| No debug statements | Pre-commit hook + architecture spec |
| Commit format | `commit-msg` hook (lefthook) |
| Coverage thresholds | SimpleCov + `bin/check_coverage` |
| DB constraints match validations | `database_consistency` gem |
| Check constraints | DB-level enforcement + migration specs |
| Safe migrations | `strong_migrations` gem |
| No N+1 queries | `bullet` gem (raises in test) |
| No secrets in code | Pre-commit hook + CI secret scan |
| API contract consistency | rswag specs + OpenAPI generation |
| Admin safety | Architecture spec + code review |
| PR quality | Dangerfile + PR template |
