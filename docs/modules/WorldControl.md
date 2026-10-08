# WorldControl

> **Contract seed.** When the `WorldControl/` module is created, copy this file to
> `WorldControl/ARCHITECTURE.md`; from then on that file is authoritative.
> Purpose, Owns, Does not own, Allowed dependencies, and Primary consumers come
> from Appendix J §J.5.5 and §J.8. Other sections are derived and are proposals
> until confirmed.

| Field | Value |
| --- | --- |
| Directory | `WorldControl/` |
| Implementation | Go control plane; simulation-side agent through Realtime control channels (proposal, [OQ-9](../system/11-open-questions.md#oq-9)) |
| Roadmap phase | 13 — distributed simulation · 14 — hot-area/cross-sim combat |
| Status | Not started |

## Purpose

Semantic distributed control plane that maps the logical world onto running
simulations.

## Owns

- `SimulationDirectory`, `AuthorityDirectory`.
- Neighbor topology.
- `SimulationGroup`.
- `AuthorityPartition` assignment.
- Handoff planning.
- Capacity-aware load balancing.
- Client connection directives.

## Does not own

Per-tick combat/physics; Region/Sector/Cell definitions (Engine World); Agones
internals (Orchestration).

## Allowed dependencies

- Contracts, Realtime control channels, Orchestration interface, Identity,
  Observability.

## Forbidden dependencies

Per-tick ghost/combat traffic (that is direct sim↔sim); RunicGame rules;
Agones/Kubernetes types (only through the Orchestration interface).

## Primary consumers

Simulations (as receivers of control directives), clients (connection
directives via Realtime), Orchestration (capacity requests).

## Model (from [05](../system/05-distributed-simulation.md))

```text
Logical/spatial world:            Operational authority:
Continent                         SimulationGroup
└── Region                        └── AuthorityPartition -> SimulationId
    └── Sector
        └── Cell
```

```cpp
struct AuthorityPartition {
    PartitionId    id;
    SimulationId   owner;
    SpatialBounds  bounds;
    AuthorityEpoch epoch;
};
```

**Hot-city rule.** Never round-robin nearby players across simulations. Preserve
interaction/spatial locality; split hot areas into authority partitions with
overlap/ghost bands where cross-boundary interaction is likely. Request/warm new
capacity before repartitioning. [J.8.3, J.8.8]

## Data ownership (derived)

Owns the directories (which simulation serves which partition, at which epoch)
and topology. Does not own any entity state.

## Integration points (derived)

- Orchestration: request/warm/release simulation capacity.
- Realtime control channels: `AssignPartition`, `DrainSimulation`,
  connection-role directives (`PrepareConnection`, `PromoteConnection`, …).
- Identity: signs connection/transfer directives.
- Engine DistributedSimulation enforces what WorldControl decides.

## Acceptance tests (Stage A, derived — from [J.14.2](../system/09-validation-scenarios.md#j142-hot-city-two-simulation-test))

- [ ] Assign adjacent AuthorityPartitions inside one Region to two simulations
      loading the same static data.
- [ ] Plan a handoff: candidate identification, client preconnect directive,
      commit with epoch increment.
- [ ] Losing a candidate or retiring connection never yields two owners.
- [ ] Load-balancing a hot area keeps nearby players on the same simulation
      where possible (no round-robin).

## Open questions

- Partitioning algorithm and thresholds are not specified.
