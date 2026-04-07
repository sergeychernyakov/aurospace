# Commit Convention

Based on [Conventional Commits](https://www.conventionalcommits.org/) with project-specific scopes.

---

## Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### Examples

```
feat(orders): add order cancellation with reversal

- Create reversal LedgerEntry on cancellation
- Restore account balance atomically
- Send cancellation email after commit

Closes #42
```

```
fix(webhooks): prevent duplicate payment processing

Duplicate webhooks from YooKassa were creating multiple
LedgerEntries. Added unique index on external_event_id
and status check before processing.
```

```
test(accounts): add edge cases for insufficient funds
```

```
chore(ci): add diff-cover to enforce PR coverage
```

---

## Types

| Type | When to Use | Example |
|------|------------|---------|
| `feat` | New functionality | New endpoint, new service, new model |
| `fix` | Bug fix | Broken state transition, wrong balance calculation |
| `refactor` | Code restructuring without behavior change | Extract service, rename method |
| `perf` | Performance improvement | Add index, optimize query, caching |
| `test` | Adding or fixing tests only | New spec, fix flaky test |
| `docs` | Documentation only | README update, YARD comments, ADR |
| `chore` | Build, CI, dependencies, configs | Update gem, CI pipeline change |
| `security` | Security fix or hardening | Fix injection, add rate limiting |
| `db` | Database migration | Add column, add index, add constraint |

---

## Scopes

Use the domain area affected:

| Scope | Area |
|-------|------|
| `orders` | Order lifecycle (create, pay, cancel) |
| `accounts` | Account balance, ledger entries |
| `payments` | YooKassa integration, payment processing |
| `webhooks` | Webhook ingestion, idempotency |
| `mailers` | Email notifications |
| `jobs` | Sidekiq background jobs |
| `admin` | ActiveAdmin panel |
| `api` | API endpoints, serializers |
| `auth` | Admin authentication |
| `ci` | CI/CD pipeline |
| `docker` | Docker, docker-compose |
| `deps` | Dependency updates |
| `config` | Rails configuration, initializers |

Scope is optional for small changes but **required** for changes in critical zones.

---

## Subject Rules

- Imperative mood: "add feature" not "added feature" or "adds feature"
- Lowercase first letter
- No period at the end
- Max 72 characters
- Describe WHAT, not HOW

```
# Good
feat(orders): add cancellation with ledger reversal
fix(webhooks): handle duplicate payment events
refactor(accounts): extract balance calculation to service

# Bad
feat(orders): Added cancellation.       # past tense, period
fix: stuff                               # vague, no scope
Update order model                       # no type
feat(orders): add cancellation with ledger reversal and also update the admin panel and fix the email template  # too long
```

---

## Body

Optional. Use when the subject alone doesn't explain the change.

- Explain **why**, not what (the diff shows what)
- Wrap at 72 characters
- Use bullet points for multiple changes
- Reference related issues

---

## Footer

- `Closes #123` --- link to issue
- `BREAKING CHANGE: description` --- for breaking API changes
- `Refs #456` --- reference without closing

---

## Commit Scope by File

| Files Changed | Suggested Scope |
|--------------|----------------|
| `app/services/orders/*` | `orders` |
| `app/services/accounts/*` | `accounts` |
| `app/services/yookassa/*` | `payments` |
| `app/controllers/webhooks/*` | `webhooks` |
| `app/models/order.rb` | `orders` |
| `app/models/ledger_entry.rb` | `accounts` |
| `app/jobs/*` | `jobs` |
| `app/mailers/*` | `mailers` |
| `app/admin/*` | `admin` |
| `db/migrate/*` | `db` |
| `.github/workflows/*` | `ci` |
| `Dockerfile`, `docker-compose.yml` | `docker` |
| `Gemfile` | `deps` |

---

## Anti-Patterns

```
# Don't combine unrelated changes
fix(orders): fix cancellation and update README and add new gems

# Don't use vague messages
chore: updates
fix: fix bug
feat: new stuff

# Don't skip type
Update order service

# Don't write novels in subject
feat(orders): implement order cancellation service that creates a reversal ledger entry and updates the account balance and sends a notification email to the user
```

---

## Git Workflow

```bash
# Feature branch
git checkout -b feat/order-cancellation

# Atomic commits (one logical change per commit)
git add app/services/orders/cancel.rb spec/services/orders/cancel_spec.rb
git commit -m "feat(orders): add cancellation service with reversal"

git add app/controllers/orders_controller.rb spec/requests/orders_spec.rb
git commit -m "feat(orders): add cancel endpoint"

git add db/migrate/xxx_add_cancelled_at_to_orders.rb
git commit -m "db(orders): add cancelled_at timestamp"

# Push and create PR
git push -u origin feat/order-cancellation
gh pr create --title "feat(orders): order cancellation with ledger reversal"
```
