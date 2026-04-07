# AUROSPACE Orders Demo --- Project Specification

> Full project specification and requirements document.
> For a quick overview, see [README.md](../README.md).

---

## 1. Idea

**Name:** AUROSPACE Orders Demo
**Domain:** ауроспейс.рф
**Repository:** git@github.com:sergeychernyakov/aurospace.git

### Summary

Demonstrative fullstack project on Ruby on Rails + React, modeling a simplified but realistic financial system:

- Users and user accounts
- Orders with state transitions
- YooKassa payment processing
- Webhook handling
- Money movement via ledger
- Reversal on cancellation
- Admin panel
- Email notifications
- Background processing via Sidekiq

---

## 2. Project Goals

Demonstrate not just Rails coding ability, but specifically:

- Understanding of the financial domain
- Ability to design reliable backend logic
- Understanding of state transitions
- Ensuring balance consistency
- Working with external payment providers
- Handling asynchronous events
- Idempotency
- High code quality
- High test coverage
- Production-like readiness

---

## 3. Business Functions

- Account and balance viewing
- Order creation
- Order payment via YooKassa
- Order status transition after webhook
- User balance changes
- Account movement history
- Successful order cancellation
- Reversal operations on account
- Email notifications for key events
- Admin panel for order management and audit

---

## 4. Technical Functions

- Rails API backend
- React frontend (TypeScript, Vite)
- PostgreSQL
- Redis + Sidekiq
- YooKassa integration
- Webhook processing
- ActionMailer + transactional email templates
- CI/CD (GitHub Actions)
- Quality gates (RuboCop, Brakeman, bundle-audit)
- Dockerized local setup
- Domain deployment

---

## 5. Quality Principles

Quality is measured not by "everything works on happy path", but by:

- Balance cannot be broken accidentally
- Same payment cannot be processed twice
- Order cannot be cancelled incorrectly
- Money movement history cannot be lost
- Webhook can be safely reprocessed
- Code is clear, testable, and separated by responsibilities
- Project can be set up locally and shown as a live product

---

## 6. Domain Model

### User

| Field | Type |
|-------|------|
| id | bigint |
| email | string |
| name | string |
| timestamps | datetime |

Associations: `has_one :account`, `has_many :orders`

### Account

| Field | Type | Notes |
|-------|------|-------|
| id | bigint | |
| user_id | bigint | FK |
| balance_cents | integer | Cached aggregate |
| currency | string | |
| timestamps | datetime | |

Associations: `belongs_to :user`, `has_many :ledger_entries`

Source of truth for audit: `ledger_entries`, not `balance_cents`.

### Order

| Field | Type |
|-------|------|
| id | bigint |
| user_id | bigint |
| amount_cents | integer |
| currency | string |
| status | enum |
| payment_provider | string |
| external_payment_id | string |
| paid_at | datetime |
| cancelled_at | datetime |
| timestamps | datetime |

Statuses: `created` -> `payment_pending` -> `successful` -> `cancelled`

Associations: `belongs_to :user`, `has_many :ledger_entries`

### LedgerEntry

| Field | Type |
|-------|------|
| id | bigint |
| account_id | bigint |
| order_id | bigint |
| entry_type | enum |
| amount_cents | integer |
| currency | string |
| reference | string |
| metadata | jsonb |
| created_at | datetime |

Types: `debit`, `credit`, `reversal`

Principle: no balance changes happen directly; every change must be accompanied by a ledger entry.

### WebhookEvent

| Field | Type |
|-------|------|
| id | bigint |
| provider | string |
| external_event_id | string |
| event_type | string |
| payload | jsonb |
| processed_at | datetime |
| status | string |
| timestamps | datetime |

Principle: store incoming events for idempotency and audit.

### NotificationLog

| Field | Type |
|-------|------|
| id | bigint |
| order_id | bigint |
| mail_type | string |
| recipient | string |
| sent_at | datetime |
| timestamps | datetime |

Principle: prevent duplicate email sends on webhook replay.

---

## 7. Financial Logic

### Ledger-Based Accounting

- Balance is not just changed as a number
- Every operation leaves a trail
- Any financial operation can be explained and traced

### Successful Payment Flow

1. Verify current status
2. Lock order
3. Lock account
4. Create ledger entry
5. Update balance
6. Update order status
7. Record payment fact
8. After commit: send email
9. Entire operation in one DB transaction

### Cancellation Flow

1. Verify order is `successful`
2. Create reversal ledger entry
3. Restore balance
4. Update order to `cancelled`
5. Record cancellation timestamp
6. After commit: send email
7. Atomic operation

### Reversal Principle

Past is never rewritten:
- Old transactions are not deleted
- Nothing is "fixed retroactively"
- A new compensating entry is added

This preserves: audit trail, financial history, and balance explainability.

---

## 8. Idempotency

Critical operations must be idempotent:
- Webhook processing
- Successful order processing
- Email sending
- Background job processing

Implementation:
- Unique keys for external events
- Status checks before transitions
- Unique index on provider events
- Separate journal of processed webhooks
- No duplicate order processing
- No duplicate email sending

---

## 9. Code Standards

- No business logic in controllers
- No direct balance changes outside domain service
- All money operations only through ledger
- All critical actions only through use-case services
- `after_commit` for external side effects
- Background jobs are idempotent
- External API integrations isolated in dedicated client/service layer

---

## 10. Backend Standards

### Architecture Layers

```
app/controllers    app/models     app/services
app/jobs           app/mailers    app/policies
app/serializers    app/queries    lib/clients
```

### Use-Case Services

- `Orders::Create`
- `Orders::StartPayment`
- `Orders::MarkSuccessful`
- `Orders::Cancel`
- `Accounts::ApplyLedgerEntry`
- `Yookassa::CreatePayment`
- `Yookassa::ProcessWebhook`

### Linting & Security

- RuboCop + rubocop-rails + rubocop-rspec + rubocop-performance + rubocop-factory_bot
- Brakeman
- bundle-audit

---

## 11. Frontend Standards

### Stack

- React + TypeScript + Vite
- React Router
- TanStack Query
- ESLint + Prettier

### Architecture

```
src/app      src/pages     src/features
src/entities src/shared    src/api
```

### Principles

- Typed API client
- Separate UI components and domain entities
- Explicit loading/error states
- Predictable data-fetching patterns
- Clean admin interface
- Simple, mature UI

### Screens

- Dashboard
- Order list
- Order detail
- Account view
- Admin panel
- Ledger / History view

---

## 12. Testing Strategy

### Goals

Cover:
- Critical domain logic
- Edge cases
- YooKassa integration
- Email flow
- Admin scenarios
- Invalid transitions

### Coverage Targets

- Backend: 90%+
- Critical domain/services: 95-100%
- Frontend: reasonable coverage of critical components
- E2E smoke for key scenarios

### Test Types

**Unit tests:** model validations, enum logic, ledger behavior, state transition guards, presenter/serializer logic

**Service tests:** order creation, successful order processing, cancellation, webhook duplicate handling, email sending after commit

**Request tests:** API endpoints, admin endpoints, auth, webhook endpoint

**Job tests:** Sidekiq jobs, email jobs, webhook processing, retry-safe behavior

**Integration tests:** full flows (create -> pay -> webhook -> success -> cancel -> reversal)

**E2E tests:** user creates order, initiates payment, webhook arrives, admin cancels, emails sent

---

## 13. Quality Gates

### Backend
- RuboCop must pass
- Brakeman must pass
- bundle-audit must pass
- RSpec must pass
- Coverage threshold enforced

### Frontend
- ESLint must pass
- Prettier check must pass
- Unit tests must pass
- E2E smoke must pass

### CI
PR is not ready unless all green:
- Backend lint, security, tests
- Frontend lint, tests
- E2E smoke
- Coverage

---

## 14. YooKassa Integration

### What to Demonstrate

- Real payment creation
- Redirect/confirmation flow
- Webhook endpoint
- Payment status processing
- Order transition only after confirmation
- Provider event logging
- Duplicate processing protection

### Organization

- `Yookassa::Client` --- API client
- `Yookassa::CreatePayment` --- payment creation service
- `Yookassa::ProcessWebhook` --- webhook processing service

### Principles

- Don't trust the frontend
- Don't trust only HTTP 200
- Order status changes only on backend
- Webhooks processed async if needed
- Incoming events are stored

---

## 15. Email Notifications

### Emails

- Order created
- Order successfully paid
- Order cancelled

### Requirements

- HTML template + plain-text fallback
- Real email delivery
- Async sending
- Send only after successful commit
- Duplicate protection

### Architecture

- `OrderMailer`
- `SendOrderEmailJob`
- `NotificationLog`

---

## 16. Sidekiq

### Usage

- Email sending
- Webhook processing
- Reconciliation jobs
- Cleanup / retries

### Principles

- Jobs must be idempotent
- Pass only IDs / primitives
- Separate queues for critical tasks
- Clear logging
- Thoughtful retry policy

### Queues

- `critical`
- `default`
- `mailers`
- `low`

---

## 17. Reconciliation

### Polling

Periodically query YooKassa for payment status if webhook hasn't arrived.

### Reconciliation Job

Background job that:
- Finds stuck payments
- Re-checks their status with provider
- Brings system to consistent state

---

## 18. Security Baseline

- Secrets only in env / credentials
- No sensitive payment data storage
- Webhook verification
- Sanitized logging
- CSRF protection
- Secure headers
- Rate limiting for sensitive endpoints
- Auth for admin section
- Basic auth or separate role for Sidekiq Web UI
- No logging of PII or sensitive payment provider fields
- No trusting incoming webhooks without verification

---

## 19. Admin Panel (ActiveAdmin)

### Features

- Order list with status filters
- Order detail view
- Ledger entries per order
- User account view
- Webhook event log
- "Cancel successful order" action
- Optional: "Reprocess webhook" action

### Restrictions

- No manual balance editing
- No direct status change via select without use-case logic

---

## 20. Observability

- `request_id` and `correlation_id`
- Structured logs
- Separate logs for payments and webhooks
- Healthcheck endpoint
- Sidekiq Web UI
- Clear error messages

---

## 21. Deployment

### Production Setup

- VPS (168.222.253.178)
- Docker / Docker Compose
- Nginx (reverse proxy + SSL)
- PostgreSQL + Redis
- Rails app + Sidekiq worker
- Frontend static build

### Domain

ауроспейс.рф (учитывать punycode для внешних интеграций и email)

### SSL

- HTTPS required
- HTTP -> HTTPS redirect

### Environment Variables

- `APP_HOST`
- `FRONTEND_URL`
- `YOOKASSA_*`
- `SMTP_*` / email provider keys

---

## 22. CI/CD (GitHub Actions)

### Backend Jobs

- Setup Ruby, bundle install, DB setup
- RuboCop, Brakeman, bundle-audit
- RSpec + coverage

### Frontend Jobs

- Setup Node, install deps
- Lint, unit tests, build

### E2E

- Run app stack, smoke test

### Deploy

- Manual production deploy (reproducible and documented)

---

## 23. Development Stages

| Stage | Focus |
|-------|-------|
| 1. Foundation | Repo init, scaffolds, Docker Compose, CI skeleton, linting/security |
| 2. Domain | User, Account, Order, LedgerEntry, constraints, status rules |
| 3. Core Flows | Create/complete/cancel order, ledger, balance updates, tests |
| 4. Payments | YooKassa integration, webhooks, idempotency, reconciliation |
| 5. Async & Email | Sidekiq, mailers, notification logs, templates |
| 6. Admin & Polish | ActiveAdmin, audit pages, UI, demo data |
| 7. Deploy | VPS, domain, SSL, production config, smoke tests |

### Priority Order

1. Money domain correctness
2. Idempotency
3. Transactions + locking
4. Tests
5. Webhook flow
6. Email flow
7. Admin observability
8. Frontend polish
9. Production deploy cosmetics
