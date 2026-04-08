# AUROSPACE Orders Demo

> Production-style fullstack payment workflow showcase built with Ruby on Rails and React.

**Domain:** ауроспейс.рф
**Repository:** [sergeychernyakov/aurospace](https://github.com/sergeychernyakov/aurospace)

---

## Overview

AUROSPACE Orders Demo is a demonstration fullstack project modeling a simplified but realistic financial system:

- User accounts and balances
- Orders with state machine transitions
- YooKassa payment processing with webhook handling
- Ledger-based money movement and balance tracking
- Reversal operations on order cancellation
- Admin panel for audit and management (ActiveAdmin)
- Email notifications
- Background processing via Sidekiq

The primary focus is **correctness, consistency, and transparency** of financial operations, strong test coverage, and production-like quality standards.

### Out of Scope

The following are intentionally **not included** in this demo project:

- User authentication (login, registration, password recovery)
- Authorization / role-based access control
- User profile management
- Multi-tenancy
- Real-time notifications (WebSocket)

The project focuses exclusively on the financial domain: orders, payments, ledger, and admin observability.

---

## Tech Stack

| Layer | Technologies |
|-------|-------------|
| **Backend** | Ruby 3.2+, Rails 7.1+ (API mode), ActiveAdmin |
| **State Machine** | AASM (declarative order lifecycle) |
| **Service Layer** | dry-monads (Result monad: Success/Failure) |
| **Frontend** | React, TypeScript, Vite, React Router, TanStack Query |
| **Database** | PostgreSQL |
| **Queue** | Redis + Sidekiq + sidekiq-unique-jobs |
| **Payments** | YooKassa |
| **API Docs** | rswag (OpenAPI / Swagger, auto-generated from specs) |
| **Observability** | OpenTelemetry (distributed tracing: Rails, PG, Redis, Sidekiq, HTTP) |
| **Architecture** | Packwerk (enforced module boundaries) |
| **Infrastructure** | Docker / Docker Compose, Nginx, VPS |
| **Quality** | RSpec, SimpleCov, RuboCop, Brakeman, bundle-audit, ESLint, Prettier |

---

## Architecture

**Modular monolith** --- pragmatic and mature choice for this domain.

```
Backend:  Rails API + ActiveAdmin
Frontend: React + TypeScript (Vite)
Async:    Redis + Sidekiq
DB:       PostgreSQL
Deploy:   Docker Compose + Nginx + VPS
```

### Backend Layers

```
app/
  controllers/    # Thin request handlers
  models/         # ActiveRecord models, validations, scopes
  services/       # Use-case service objects (one action per class)
  jobs/           # Sidekiq background jobs
  mailers/        # ActionMailer (email templates)
  policies/       # Authorization policies
  serializers/    # API response formatting
  queries/        # Complex query objects
lib/
  clients/        # External API clients (YooKassa)
```

### Frontend Structure

```
src/
  app/            # App shell, routing
  pages/          # Page components
  features/       # Feature modules
  entities/       # Domain entities
  shared/         # Shared UI components
  api/            # Typed API client
```

### Key Service Objects

| Service | Purpose |
|---------|---------|
| `Orders::Create` | Create a new order |
| `Orders::StartPayment` | Initiate YooKassa payment |
| `Orders::MarkSuccessful` | Transition to successful after webhook |
| `Orders::Cancel` | Cancel successful order with reversal |
| `Accounts::ApplyLedgerEntry` | Record financial movement |
| `Yookassa::CreatePayment` | Create payment via YooKassa API |
| `Yookassa::ProcessWebhook` | Handle incoming webhook event |

---

## Domain Model

### User
- `has_one :account`, `has_many :orders`
- Fields: `email`, `name`

### Account
- `belongs_to :user`, `has_many :ledger_entries`
- Fields: `balance_cents`, `currency`
- `balance_cents` is a cached aggregate; `ledger_entries` are the source of truth

### Order
- `belongs_to :user`, `has_many :ledger_entries`
- Fields: `amount_cents`, `currency`, `status`, `external_payment_id`, `paid_at`, `cancelled_at`
- Statuses: `created` -> `payment_pending` -> `successful` -> `cancelled`

### LedgerEntry
- `belongs_to :account`, `belongs_to :order`
- Types: `debit`, `credit`, `reversal`
- Fields: `amount_cents`, `currency`, `entry_type`, `reference`, `metadata`
- **All balance changes go through ledger entries** --- no direct balance manipulation

### WebhookEvent
- Stores incoming YooKassa events for idempotency and audit
- Fields: `external_event_id`, `event_type`, `payload`, `processed_at`, `status`

### NotificationLog
- Prevents duplicate email sends on webhook replay
- Fields: `order_id`, `mail_type`, `recipient`, `sent_at`

---

## Financial Logic

### Ledger-Based Accounting

Every balance change creates a `LedgerEntry`. Balance is never updated directly --- it's always derived from the ledger trail. Past entries are never deleted or modified; reversals are compensating entries.

### Successful Payment Flow

1. Verify current order status
2. Lock order + account (within DB transaction)
3. Create `LedgerEntry` (credit)
4. Update `Account#balance_cents`
5. Update order status to `successful`
6. Record `paid_at` timestamp
7. After commit: send email notification
8. Entire operation within a single DB transaction

### Cancellation (Reversal)

1. Verify order is `successful`
2. Create reversal `LedgerEntry`
3. Restore account balance
4. Update order to `cancelled`, record `cancelled_at`
5. After commit: send cancellation email
6. Atomic operation

---

## Idempotency

- Unique index on `WebhookEvent#external_event_id`
- Status checks before state transitions
- `NotificationLog` prevents duplicate emails
- All critical operations are idempotent
- Sidekiq jobs are retry-safe

---

## YooKassa Integration

- Dedicated `Yookassa::Client` for API communication
- Payment creation with confirmation redirect
- Webhook endpoint with IP validation
- Async processing via Sidekiq
- Reconciliation job for stale/stuck payments
- All payment events stored for audit

See [.claude/docs/yookassa/](/.claude/docs/yookassa/) for detailed API documentation.

---

## Email Notifications

| Event | Email |
|-------|-------|
| Order created | Order confirmation |
| Payment successful | Payment receipt |
| Order cancelled | Cancellation notice |

- Async delivery via Sidekiq (`SendOrderEmailJob`)
- HTML + plain-text templates
- Sent only after successful DB commit (`after_commit`)
- Duplicate protection via `NotificationLog`

---

## Admin Panel (ActiveAdmin)

- Orders list with status filters
- Order detail view with associated ledger entries
- Account balances and user info
- Webhook event log with payload inspection
- "Cancel order" action (via service object, not direct update)
- **No direct balance editing** --- all changes through use-case services

---

## Local Setup

```bash
git clone git@github.com:sergeychernyakov/aurospace.git
cd aurospace

# Configure environment
cp .env.example .env
# Edit .env: add YooKassa credentials, SMTP, SECRET_KEY_BASE

# Start services
docker compose up

# Setup database (in another terminal)
docker compose exec app bundle exec rails db:create db:migrate db:seed
```

Services:
- **App (Rails):** `http://localhost:3000`
- **Admin:** `http://localhost:3000/admin`
- **Sidekiq Web UI:** `http://localhost:3000/sidekiq`

### Setup pre-commit hooks

```bash
gem install lefthook
lefthook install
```

### Run all checks locally

```bash
bin/ci
```

Runs RSpec, RuboCop, Brakeman, and bundle-audit. Same checks as CI pipeline.

---

## Testing Payments (YooKassa)

### Getting Test Credentials

1. Register at [yookassa.ru](https://yookassa.ru)
2. Create a test shop in [dashboard](https://yookassa.ru/my/shop-settings)
3. Copy **Shop ID** and **Secret Key** to `.env`:
   ```
   YOOKASSA_SHOP_ID=your_test_shop_id
   YOOKASSA_SECRET_KEY=test_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   ```

### Test Cards

| Card Number | Result | Use Case |
|-------------|--------|----------|
| `5555 5555 5555 4444` | Successful payment | Happy path testing |
| `4111 1111 1111 1111` | 3-D Secure (any code) | Testing 3DS flow |
| `5555 5555 5555 5599` | Payment declined | Error handling |
| `4444 4444 4444 4448` | Successful + requires capture | Two-stage payments |
| `4444 4444 4444 4455` | Declined after 3DS | 3DS failure scenario |

**Expiry:** any future date. **CVV:** any 3 digits.

### Testing Webhooks Locally

YooKassa needs a public URL to send webhooks. Use [ngrok](https://ngrok.com):

```bash
# 1. Start ngrok tunnel
ngrok http 3000

# 2. Copy the HTTPS URL (e.g. https://abc123.ngrok-free.app)

# 3. Set webhook URL in .env
YOOKASSA_WEBHOOK_URL=https://abc123.ngrok-free.app/webhooks/yookassa

# 4. Register webhook in YooKassa dashboard:
#    - URL: https://abc123.ngrok-free.app/webhooks/yookassa
#    - Events: payment.succeeded, payment.canceled, refund.succeeded
```

### End-to-End Payment Test Flow

1. **Create order** --- `POST /orders` with amount
2. **Start payment** --- `POST /orders/:id/pay` --- returns YooKassa confirmation URL
3. **Pay with test card** --- use `5555 5555 5555 4444` on YooKassa page
4. **Webhook arrives** --- `POST /webhooks/yookassa` with `payment.succeeded`
5. **Verify:**
   - Order status changed to `successful`
   - `LedgerEntry` created (credit)
   - `Account#balance_cents` updated
   - `WebhookEvent` stored
   - Email sent (check Sidekiq + `NotificationLog`)
6. **Cancel order** --- `POST /orders/:id/cancel`
7. **Verify reversal:**
   - Order status changed to `cancelled`
   - Reversal `LedgerEntry` created
   - Balance restored
   - Cancellation email sent

### Testing Idempotency

```bash
# Send the same webhook twice --- second should be a no-op
curl -X POST http://localhost:3000/webhooks/yookassa \
  -H "Content-Type: application/json" \
  -d '{"event": "payment.succeeded", "object": {"id": "test-payment-id", ...}}'

# Verify: only one LedgerEntry, one email, balance unchanged on second call
```

### Running Payment Tests

```bash
# Unit tests (mocked, no network)
bundle exec rspec spec/services/yookassa/

# Integration tests with VCR cassettes
bundle exec rspec spec/requests/webhooks/

# Full flow tests
bundle exec rspec spec/integration/payment_flow_spec.rb
```

---

## Deployment

| Parameter | Value |
|-----------|-------|
| **Site** | https://ауроспейс.рф |
| **Admin** | https://ауроспейс.рф/a/ |
| **API Docs** | https://ауроспейс.рф/api-docs |
| **Server** | 168.222.253.178 (Ubuntu 24.04) |
| **SSL** | Let's Encrypt (auto-renew) |
| **Stack** | Rails 7.2 + Puma + Sidekiq + PostgreSQL 16 + Redis + Nginx |
| **YooKassa** | Test mode (Shop 1325535) |

---

## Quality Infrastructure

The project treats quality as an **enforceable engineering standard**, not a best-effort aspiration.

### Coverage Enforcement

| Scope | Threshold | Enforcement |
|-------|-----------|-------------|
| **Global** (line + branch) | 90% | SimpleCov, CI fails below |
| **Critical domain** (orders, accounts, yookassa) | 95% | `bin/check_coverage` |
| **New code in PR** (diff coverage) | 90% | `diff-cover` |
| **Branch coverage** | 85% | SimpleCov branch mode |

### CI Pipeline (17 parallel checks + Quality Gate)

| Category | Checks |
|----------|--------|
| **Backend Lint** | RuboCop |
| **Backend Security** | Brakeman, bundle-audit, secret scanning |
| **Backend Tests** | RSpec + coverage + FactoryBot.lint |
| **Backend Quality** | DB consistency, architecture specs |
| **Backend Docs** | YARD documentation coverage |
| **Frontend Lint** | ESLint, Prettier, Stylelint |
| **Frontend Quality** | TypeScript strict, tests + build |
| **E2E** | Playwright smoke tests |
| **Docker** | Hadolint, Docker build, Docker Compose smoke |
| **PR Automation** | Danger (tests for changes, critical zone alerts) |
| **Quality Gate** | Blocks merge if ANY check fails |

### Commit Convention

[Conventional Commits](docs/COMMIT_CONVENTION.md) enforced by `commit-msg` hook:

```
<type>(<scope>): <subject>

feat(orders): add cancellation with ledger reversal
fix(webhooks): prevent duplicate payment processing
test(accounts): add edge cases for insufficient funds
db(orders): add cancelled_at timestamp
```

Types: `feat` `fix` `refactor` `perf` `test` `docs` `chore` `security` `db`
Scopes: `orders` `accounts` `payments` `webhooks` `mailers` `jobs` `admin` `api` `ci` `docker` `deps` `config`

Commits that don't match the pattern are **blocked**.

### PR Standards

Every PR uses a [template](.github/pull_request_template.md) with:
- Summary (what + why)
- Critical zone checklist (which money/payment code was touched)
- Test plan (what types of tests cover the change)
- Quality checklist (tests, lint, coverage, security)

### Git Hooks (Lefthook)

**commit-msg:** validates conventional commit format

**pre-commit** (auto-fix + block):
- RuboCop auto-fix (Ruby)
- ESLint + Prettier auto-fix (JS/TS/CSS)
- Stylelint auto-fix (CSS)
- Secret detection (blocks commit)
- Debug statement detection (blocks commit)
- Focused spec detection (blocks commit)
- Trailing whitespace fix

**pre-push:**
- Full RSpec suite
- Brakeman security scan
- bundle-audit
- database_consistency
- YARD documentation warnings

### Architecture Enforcement

Automated architecture specs (`spec/architecture/`) ensure:
- Controllers stay thin (max 15 lines per action)
- Models don't call external APIs
- Services don't depend on controllers
- Jobs only orchestrate (no business logic in jobs)
- Mailers don't modify data
- Balance changes only through ledger services
- No debug statements in production code

### Database Quality

- `strong_migrations` --- prevents dangerous schema changes
- `database_consistency` --- validates DB constraints match model validations
- `bullet` --- detects N+1 queries (raises in test, logs in dev)
- `annotate` --- auto-generates schema docs in model files

### Security Layers

| Layer | Tool |
|-------|------|
| Static analysis | Brakeman |
| Dependency audit | bundle-audit |
| Secret scanning | CI + pre-commit hooks |
| Rate limiting | rack-attack |
| HTTP headers | secure_headers (CSP, X-Frame, etc.) |
| Parameter filtering | Sensitive data stripped from logs |
| Webhook verification | IP validation + idempotency |

### Error Taxonomy

Structured domain errors for clear API responses and testability:

```
ApplicationError
  Orders::InvalidTransitionError
  Orders::AlreadyCancelledError
  Payments::DuplicateWebhookError
  Payments::ProviderError
  Accounts::InsufficientFundsError
```

### Contract Testing

- **WebMock** --- blocks all real HTTP in tests
- **VCR** --- records/replays YooKassa API interactions
- No live external calls in CI

### Architectural Decisions

Documented in [`docs/adr/`](docs/adr/):

1. [Ledger-based accounting](docs/adr/001-ledger-based-accounting.md)
2. [Modular monolith](docs/adr/002-modular-monolith.md)
3. [ActiveAdmin backoffice](docs/adr/003-activeadmin-backoffice.md)
4. [Idempotent webhook processing](docs/adr/004-idempotent-webhook-processing.md)
5. [Docker + VPS deployment](docs/adr/005-docker-vps-deployment.md)

---

## Development Roadmap

| Stage | Focus |
|-------|-------|
| 1. Foundation | Repo, scaffolds, Docker, CI, linting |
| 2. Domain | User, Account, Order, LedgerEntry, constraints |
| 3. Core Flows | Create/complete/cancel order, ledger, balance |
| 4. Payments | YooKassa integration, webhooks, idempotency, reconciliation |
| 5. Async & Email | Sidekiq, mailers, notification logs, templates |
| 6. Admin & Polish | ActiveAdmin, audit views, UI polish, demo data |
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

---

## Documentation

| Document | Purpose |
|----------|---------|
| [Project Specification](docs/SPECIFICATION.md) | Full project spec and requirements |
| [Architecture Invariants](docs/ARCHITECTURE.md) | Rules that must always hold true |
| [Ruby Style Guide](RUBY_STYLE_GUIDE.md) | Coding conventions |
| [Commit Convention](docs/COMMIT_CONVENTION.md) | Commit message and PR standards |
| [ADR: Architectural Decisions](docs/adr/) | Why we chose what we chose |
| [YooKassa Integration](docs/yookassa/) | Payment API reference |

### Auto-Generated Docs

| Output | Source | Command |
|--------|--------|---------|
| API documentation | YARD comments in code | `bundle exec yard doc` |
| Model annotations | DB schema | `bundle exec annotate --models` |
| Coverage report | SimpleCov | `bundle exec rspec` (generates `coverage/`) |

---

*AUROSPACE Orders Demo --- production-grade showcase demonstrating senior-level engineering approach to financial domain.*
