# Realtime

> **Contract seed.** When the `Realtime/` module is created, copy this file to
> `Realtime/ARCHITECTURE.md`; from then on that file is authoritative.
> Purpose, Owns, Does not own, Allowed dependencies, Primary consumers, and the
> connection-role model come from Appendix J §J.5.2, §J.5.9, and §J.8. Other
> sections are derived and are proposals until confirmed.

| Field | Value |
| --- | --- |
| Directory | `Realtime/` |
| Implementation | C++ on both client and simulation sides (proposal, [OQ-9](../system/11-open-questions.md#oq-9)) |
| Roadmap phase | 4 (client↔simulation) · 8 (interest filtering) · 13 (sim↔sim peers, make-before-break) |
| Status | Not started |

## Purpose

Low-latency client↔simulation and simulation↔simulation networking
implementation.

## Owns

- Transport, sessions, channels.
- Serialization.
- Replication transport.
- Ghost/transfer transport.
- Simulation peers.
- Connection-set lifecycle (`WorldSession`, connection roles).

## Does not own

Authority semantics themselves (Engine DistributedSimulation); Game combat rules;
world load-balancing policy (WorldControl).

## Allowed dependencies

- Contracts, Identity, Observability.
- Integrates Engine `NetworkAdapter` (direction: [OQ-1](../system/11-open-questions.md#oq-1)).

## Forbidden dependencies

NATS, gRPC, databases, Agones on the per-tick path [J.8.4]; RunicGame;
WorldControl policy logic.

## Primary consumers

Engine NetworkAdapter (client and server), WorldControl (control channels),
RunicGame client/server executables.

## Public surface (conceptual)

```cpp
enum class WorldConnectionRole {
    Primary,        // authoritative simulation
    WarmCandidate,  // connected and prepared for promotion
    Dormant,        // temporarily retained with minimal traffic
    Retiring        // old authority during grace/cleanup
};
// Control operations:
// PrepareConnection, WakeConnection, PromoteConnection,
// SleepConnection, RetireConnection, DropConnection
```

The user-facing `WorldSession` is logical and stable even when the underlying
authoritative endpoint changes. Gameplay code never reasons about IP addresses or
chooses its own authority server. [J.5.9]

Direct sim-to-sim traffic it must carry [J.8.4]: GhostState/GhostDelta,
PrepareTransfer/TransferReady, FinalTransferSnapshot, AuthorityCommit,
ForeignCombatVolume/remote effect context, RemoteHitResult/feedback — all
**direct and broker-free**.

## Threading model (derived)

Network I/O on dedicated threads. Hands decoded messages to NetworkAdapter
ingress queues and takes egress from NetworkAdapter; never calls into the
simulation thread directly and never blocks it.

## Data ownership (derived)

Owns connections, sessions, sequencing/reliability state. Does not own any
gameplay or authority state.

## Integration points (derived)

- Identity validates session tokens on connect and verifies signed directives.
- WorldControl issues connection directives (prepare/promote/retire) through
  control channels.
- Observability: per-connection metrics.

## Acceptance tests (Stage A, derived)

- [ ] Phase 4: two clients connect directly to one simulation; movement
      snapshots, spawn/despawn, input sequencing for prediction/reconciliation.
- [ ] Unauthenticated connections are rejected.
- [ ] Channel reliability/ordering behaves as configured under loss/reorder.
- [ ] Phase 13: `WorldSession` survives a Primary change (make-before-break);
      dropping a candidate or retiring connection never duplicates or rolls back
      authority. [J.14.2]
- [ ] No broker or database on the realtime path.

## Open questions

- Transport technology (UDP-based protocol, library choice) is not specified
  ([OQ-12](../system/11-open-questions.md#oq-12) — Platform Fabric/Networking reference).
