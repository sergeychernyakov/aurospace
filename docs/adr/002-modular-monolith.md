# ADR-002: Modular Monolith Architecture

**Status:** Accepted
**Date:** 2026-04-07

## Context

The project needs an architecture that is realistic, maintainable, and demonstrates engineering maturity.

## Decision

We use a **modular monolith** with Rails API backend and React frontend.

## Rationale

- **Realistic:** This is the mature choice for a small-to-medium financial application.
- **Simpler to maintain:** One deployable unit. No inter-service communication overhead.
- **Faster to develop:** No microservice ceremony (service discovery, API gateways, distributed transactions).
- **Easier to demonstrate:** The entire system is visible and coherent.
- **No premature splitting:** Domain boundaries are enforced via service objects, not network boundaries.

## Consequences

- All backend code lives in one Rails application.
- Clear separation achieved through service objects, query objects, and directory structure.
- If the system grows beyond this scope, extraction to services is straightforward because boundaries already exist.

## Alternatives Considered

- **Microservices:** Over-engineering for this domain. Adds deployment complexity, distributed transaction problems, and doesn't improve the demo. Rejected.
- **Serverless:** Doesn't match the stateful, transactional nature of financial operations. Rejected.
