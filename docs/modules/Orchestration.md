# Orchestration

> **Contract seed.** When the `Orchestration/` module is created, copy this file
> to `Orchestration/ARCHITECTURE.md`; from then on that file is authoritative.
> Purpose, Owns, Does not own, Allowed dependencies, and Primary consumers come
> from Appendix J §J.5.6 and §J.8.8. Other sections are derived and are proposals
> until confirmed.

| Field | Value |
| --- | --- |
| Directory | `Orchestration/` |
| Implementation | Go (proposal, [OQ-9](../system/11-open-questions.md#oq-9)) |
| Roadmap phase | 16 — production orchestration (a local-process provider can exist earlier for phase 13 tests) |
| Status | Not started — this is the "ADD AGONES" item in the README title |

## Purpose

Process/container lifecycle and capacity integration.

## Owns

- Agones GameServers, Fleets, allocations, autoscaling adapters.
- Kubernetes deployment, resources, networking, CPU policy.
- Capacity acquisition.

## Does not own

Ghosts, entity authority, combat, Region semantics. Agones does not understand
players, cities, ghosts, attacks, or quests; it manages game-server processes.
[J.8.8]

## Allowed dependencies

- Observability.
- Agones SDK/client libraries and Kubernetes clients (inside this module only).

## Forbidden dependencies

WorldControl internals (WorldControl depends on Orchestration's interface, not
the reverse); RunicEngine; RunicGame rules.

## Primary consumers

WorldControl (capacity), deployment tooling.

## Public surface (conceptual)

```text
Agones / Kubernetes
    provide process capacity and lifecycle
             |
             v
Platform WorldControl
    assigns world/authority responsibility
             |
             v
Engine DistributedSimulation
    enforces ghost/authority/transfer semantics
```

A capacity interface (proposal) with two providers: **local processes** (for
development and tests — the bootstrap README's "ordinary local processes first")
and **Agones/Kubernetes** (production).

## Integration points (derived)

- WorldControl asks for, warms, and releases simulation capacity.
- The simulation process reports Ready/Health to Agones through a binding that
  Engine never links ([OQ-10](../system/11-open-questions.md#oq-10)).

## Acceptance tests (Stage A, derived — phase 16)

- [ ] The same capacity interface works with the local-process provider and the
      Agones provider.
- [ ] Allocate → Ready → Health → Shutdown lifecycle for a simulation process.
- [ ] Fleet scaling responds to WorldControl capacity requests.
- [ ] No Agones/Kubernetes type leaks into WorldControl's or Engine's APIs.

## Open questions

- [OQ-10](../system/11-open-questions.md#oq-10) — Agones SDK in the simulation process.
