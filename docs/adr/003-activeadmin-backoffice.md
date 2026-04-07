# ADR-003: ActiveAdmin for Backoffice

**Status:** Accepted
**Date:** 2026-04-07

## Context

The project needs an admin panel for order management, ledger inspection, and webhook monitoring.

## Decision

We use **ActiveAdmin** for the backoffice interface.

## Rationale

- **Fast to implement:** Declarative DSL generates full CRUD with filters, search, and pagination.
- **Audit-focused:** Perfect for read-heavy admin needs (viewing orders, ledger entries, webhook events).
- **Practical choice:** Shows understanding of backoffice needs without wasting time building a custom admin UI.
- **Production-proven:** Widely used in Rails applications for internal tools.

## Constraints

- Admin actions that modify data (e.g., cancel order) MUST go through domain service objects, not direct ActiveRecord updates.
- No manual balance editing through admin interface.
- No direct status changes via select dropdowns.

## Consequences

- Admin panel available at `/admin`.
- Requires admin authentication (separate from user auth).
- Some styling limitations compared to a custom admin, but adequate for an audit/management tool.

## Alternatives Considered

- **Custom React admin:** Too much effort for a demo project. The time is better spent on domain logic and tests. Rejected.
- **Administrate:** Good alternative, but ActiveAdmin has more features out of the box. Deferred.
