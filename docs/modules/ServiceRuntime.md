# ServiceRuntime

> **Contract seed.** When the `ServiceRuntime/` module is created, copy this file
> to `ServiceRuntime/ARCHITECTURE.md`; from then on that file is authoritative.
> Purpose, Owns, Does not own, Allowed dependencies, and Primary consumers come
> from Appendix J §J.5.3 and §J.10. Other sections are derived and are proposals
> until confirmed.

| Field | Value |
| --- | --- |
| Directory | `ServiceRuntime/` |
| Implementation | Go; plus a C++ async client binding for simulation-originated requests (proposal, [OQ-9](../system/11-open-questions.md#oq-9)) |
| Roadmap phase | 9 — durable service foundation |
| Status | Not started (gRPC/NATS deferred) |

## Purpose

Reusable service-process and service-messaging infrastructure.

## Owns

- gRPC and NATS integration.
- Request context and auth propagation.
- Async completion.
- Service lifecycle.
- Retry and idempotent-request plumbing, where generic.

## Does not own

Inventory, quest, auction, or economy rules — those are private RunicGame
services built on this runtime.

## Allowed dependencies

- Contracts, Identity, Observability.

## Forbidden dependencies

RunicGame domain code; Persistence policy (services use Persistence directly);
anything on the realtime per-tick path.

## Primary consumers

RunicGame `Server/Services/*` (CharacterService, InventoryService, QuestService,
TradeService, AuctionService, EconomyService, GuildService, MailService); the
simulation (through a C++ binding) for async durable requests.

## Public surface (conceptual)

```text
ServiceRuntime/
├── api_or_pkg/
├── internal/
├── tests/
└── build/deploy metadata as appropriate
```

```text
Simulation (C++) ── async request ──► ServiceRuntime ──► Game service (Go)
       ▲                                                      │
       └──── typed completion, applied at a later safe tick ◄─┘
```

## Threading model (derived)

Go services: standard concurrency. C++ binding: requests are submitted without
blocking; completions are delivered to a queue the simulation drains at safe
tick boundaries. Callbacks never touch simulation state. [J.7.2, J.14.4]

## Integration points (derived)

- Identity: service identity and player auth context on every request.
- Persistence: used by the Game service implementation, not by the runtime itself.
- Observability: request metrics, logs, traces.

## Acceptance tests (Stage A, derived — phase 9)

- [ ] Host a neutral sample service (no game rules) with lifecycle start/stop.
- [ ] Auth context propagates from caller to handler.
- [ ] A retried request with the same idempotency key executes once.
- [ ] A C++ caller receives an async completion without blocking, through a
      queue suitable for tick-boundary application.
- [ ] Phase 9 proof (with Game services): load/reconnect and idempotent item
      grants.

## Open questions

- Which traffic uses gRPC vs. NATS is not specified.
