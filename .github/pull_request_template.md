## Summary

<!-- 1-3 bullet points: what changed and why -->

-

## Type

<!-- Check one -->

- [ ] `feat` --- new feature
- [ ] `fix` --- bug fix
- [ ] `refactor` --- code change that neither fixes a bug nor adds a feature
- [ ] `perf` --- performance improvement
- [ ] `test` --- adding or fixing tests
- [ ] `docs` --- documentation only
- [ ] `chore` --- build, CI, dependencies, configs
- [ ] `security` --- security fix or hardening

## Critical Zone Changes

<!-- Does this PR touch money/payment/webhook/email code? -->

- [ ] `app/services/orders/` --- order lifecycle
- [ ] `app/services/accounts/` --- balance / ledger
- [ ] `app/services/yookassa/` --- payment provider
- [ ] `app/controllers/webhooks/` --- webhook processing
- [ ] `app/jobs/` --- async processing
- [ ] `app/mailers/` --- email delivery
- [ ] `db/migrate/` --- database schema
- [ ] None of the above

## Test Plan

<!-- How was this tested? Check all that apply -->

- [ ] Unit tests (models, services)
- [ ] Request specs (API endpoints)
- [ ] Integration tests (full flow)
- [ ] Manual testing (describe below)
- [ ] Webhook replay tested
- [ ] Idempotency verified

## Checklist

- [ ] Tests pass: `bundle exec rspec`
- [ ] Lint passes: `bundle exec rubocop`
- [ ] No new security warnings: `bundle exec brakeman`
- [ ] Coverage >= 90% (critical domain >= 95%)
- [ ] Migrations are reversible
- [ ] No hardcoded secrets
- [ ] No TODO/FIXME in critical zone code
- [ ] YARD docs updated for public API changes

## Screenshots / Logs

<!-- If applicable: admin panel, API responses, Sidekiq logs -->
