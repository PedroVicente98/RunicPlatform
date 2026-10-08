# RunicPlatform documentation

RunicPlatform (formerly RunicFabric) is the public (MIT) **networking and
distributed infrastructure** of a server-authoritative MMORPG: versioned
contracts, client↔simulation and simulation↔simulation transport, service
runtime, persistence primitives, identity, the world-control plane,
Agones/Kubernetes orchestration, and observability. It owns mechanisms, never
RunicGame policy.

> Architecture version **v0** — imported from earlier design work and being
> refined here. See [system/README.md](system/README.md) for provenance.

## Start here

1. [system/01-architecture-overview.md](system/01-architecture-overview.md) — invariants, three-way rule, ownership.
2. [architecture.md](architecture.md) — how RunicPlatform is organized.
3. [current-state.md](current-state.md) — what exists today and the gap to the target.
4. [modules/README.md](modules/README.md) — module catalog.
5. [system/05-distributed-simulation.md](system/05-distributed-simulation.md) and
   [system/07-service-backed-systems.md](system/07-service-backed-systems.md) — the two areas Platform serves most.
6. [system/10-ai-development-workflow.md](system/10-ai-development-workflow.md) — how a module task is executed.

## Layout of this folder

| Path | Content | Scope |
| --- | --- | --- |
| `system/` | Cross-repository architecture | **Mirrored** in RunicEngine and RunicGame — edit all three |
| `architecture.md` | RunicPlatform structure, languages, integration with Engine and Game | this repository |
| `current-state.md` | Bootstrap inventory, gaps, migration checklist | this repository |
| `modules/` | One contract per Platform module (8) | this repository |
