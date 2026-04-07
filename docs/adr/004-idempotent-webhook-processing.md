# ADR-004: Idempotent Webhook Processing

**Status:** Accepted
**Date:** 2026-04-07

## Context

YooKassa sends webhook notifications for payment events. Webhooks can arrive:
- Multiple times (retries on timeout)
- Out of order (network delays)
- For already-processed payments
- After the order has been cancelled

The system must handle all of these cases without corrupting financial data.

## Decision

All webhook processing is **idempotent** with the following guarantees:

1. `WebhookEvent` records store every incoming event with `external_event_id`.
2. Unique index on `external_event_id` prevents duplicate storage.
3. Before processing, the current order status is checked.
4. State transitions are guarded: only valid transitions proceed.
5. Processing happens in a database transaction with row-level locking.
6. `NotificationLog` prevents duplicate email sends.

## Rationale

- **External systems are unreliable.** Webhooks will be sent multiple times.
- **Financial operations must be exactly-once.** Double-crediting an account is unacceptable.
- **Audit trail is mandatory.** Even duplicate/rejected events are stored for debugging.

## Consequences

- Slightly more complex webhook handler (status checks, locking, dedup).
- `WebhookEvent` table grows over time (acceptable, can be archived).
- Failed webhook processing can be retried safely.
- Reconciliation job can re-check stale payments without fear of duplication.

## Test Coverage Required

- Duplicate webhook (same `external_event_id`)
- Out-of-order webhook (success after cancel)
- Webhook for unknown payment
- Webhook retry after partial failure
- Concurrent webhook processing (race condition test)
