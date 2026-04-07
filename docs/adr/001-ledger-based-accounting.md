# ADR-001: Ledger-Based Accounting

**Status:** Accepted
**Date:** 2026-04-07

## Context

The system needs to track user account balances as orders are paid and cancelled. Two approaches exist:

1. **Balance-only:** Update `Account#balance_cents` directly on each transaction.
2. **Ledger-based:** Every balance change creates an immutable `LedgerEntry` record. `balance_cents` is a cached aggregate.

## Decision

We use **ledger-based accounting**.

## Rationale

- **Auditability:** Every balance change has a traceable entry with timestamp, type, and reference.
- **Reversals are clean:** Cancellations create compensating entries instead of modifying history.
- **Debugging:** Current balance can be verified by summing ledger entries. Discrepancies are immediately detectable.
- **Financial domain standard:** This is how real accounting systems work. It signals domain understanding.
- **Idempotency:** Duplicate processing can be detected by checking for existing ledger entries.

## Consequences

- Slightly more complex than direct balance updates.
- Requires a `LedgerEntry` model with proper indexes.
- Balance must be updated atomically with ledger entry creation (single transaction).
- Old entries are never deleted or modified.

## Alternatives Considered

- **Balance-only:** Simpler, but loses history. A single bug can silently corrupt balances with no way to trace what happened. Rejected.
