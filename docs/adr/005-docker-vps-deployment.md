# ADR-005: Docker + VPS Deployment

**Status:** Accepted
**Date:** 2026-04-07

## Context

The project needs a production-like deployment to demonstrate that it works as a real system, not just locally.

## Decision

Deploy with **Docker Compose** on a **VPS** (168.222.253.178) behind **Nginx** with SSL.

## Rationale

- **Reproducible:** `docker compose up` works identically on any machine.
- **Production-like:** Separate containers for app, sidekiq, postgres, redis --- mirrors real infrastructure.
- **Demonstrable:** Live domain (ауроспейс.рф) with HTTPS shows the project is not just code, but a running system.
- **Simple:** No Kubernetes overhead. VPS + Docker Compose is the right tool for this scale.

## Stack

| Service | Container | Notes |
|---------|-----------|-------|
| Rails API | `app` | Puma, non-root user |
| Sidekiq | `sidekiq` | Same image, different entrypoint |
| PostgreSQL | `postgres` | Named volume for persistence |
| Redis | `redis` | For Sidekiq and caching |
| Nginx | Host or container | Reverse proxy, SSL termination |

## Consequences

- Need to manage VPS (security updates, monitoring).
- SSL via Let's Encrypt (certbot auto-renewal).
- Environment variables managed on server, not in code.
- Deployment is `git pull && docker compose up -d --build`.

## Alternatives Considered

- **Heroku:** Too expensive for a demo. Hides infrastructure knowledge. Rejected.
- **Kubernetes:** Massive overkill for a single-app demo. Rejected.
- **Kamal:** Good option, but Docker Compose is simpler and more transparent for demonstration. Deferred.
