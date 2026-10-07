# CLAUDE.md — RunicPlatform

RunicPlatform (formerly RunicFabric) is the public (MIT) networking and distributed-infrastructure
repository of a three-repository MMORPG project:

- **RunicEngine** (`../RunicEngine`) — reusable real-time/game mechanisms (C++20).
- **RunicPlatform** (this repo) — contracts, realtime transport, service runtime, persistence,
  identity, world control, orchestration (Agones/Kubernetes), observability. Go + C++ bindings.
- **RunicGame** (`../RunicGame`, proprietary) — all concrete game rules, content, domain services.

## Read before changing anything

1. `docs/README.md`
2. `docs/system/01-architecture-overview.md`, `02-module-contract.md`, `03-dependency-rules.md`
3. `docs/current-state.md`
4. The module you are working on: `docs/modules/<Module>.md` (or `<Module>/ARCHITECTURE.md` once it exists)
5. `docs/system/10-ai-development-workflow.md`

## Hard rules

- Platform owns **mechanisms, never game policy**: no inventory/quest/trade/auction/economy/combat
  rules here. Concrete domain services are RunicGame code built on ServiceRuntime/Persistence.
- Never depend on RunicGame. Touch RunicEngine only through the NetworkAdapter ↔ Realtime seam
  and Contracts (direction: `docs/system/11-open-questions.md#oq-1`).
- The realtime path is direct and broker-free: no NATS, gRPC, database, or Agones on per-tick
  ghost/combat/replication traffic.
- Nothing Platform does may block a simulation tick; completions are delivered to queues that the
  simulation drains at safe boundaries.
- Local Flecs entity IDs never appear in schemas; use `GlobalEntityId` / `GlobalPlayerId`.
- Work on one module at a time; report needed changes in other modules instead of making them.
- Do not silently resolve items in `docs/system/11-open-questions.md`; ask.

## Build

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug && cmake --build build && ctest --test-dir build --output-on-failure
go build ./... && go test ./...
```

## Docs maintenance

- Update the module contract, `docs/modules/README.md` status, and `docs/current-state.md`
  in the same change as the code.
- `docs/system/` is mirrored in all three repositories; edit all copies together.
