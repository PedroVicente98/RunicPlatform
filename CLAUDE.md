# CLAUDE.md — RunicPlatform

RunicPlatform (formerly RunicFabric) is the public (MIT) networking, services and infrastructure
repository of a three-repository MMORPG project (C++ and Go):

- **RunicEngine** (`external/RunicEngine` submodule, or a sibling `../RunicEngine`) — generic C++20
  mechanisms: simulation, networking interfaces and encoding, the entry point and layers, tools.
- **RunicPlatform** (this repo) — Transport (GameNetworkingSockets), Contracts (Protobuf),
  ServerBindings (services bridge, lifecycle, metrics exporter), Go SDK, core services, building
  blocks (item ledger, currency wallets), infrastructure (Agones, Kubernetes, Prometheus, Grafana).
- **RunicGame** (`../RunicGame`, proprietary) — game rules, content, executables and game services.

The source of truth is ARCH (RunicEngine — Technical Architecture v3); these docs are generated from it.

## Read before changing anything

1. `docs/README.md`
2. `docs/system/01-architecture-overview.md`, `02-module-contract.md`, `03-dependency-rules.md`
3. `docs/architecture.md`
4. `docs/current-state.md`
5. The module you are working on: `docs/modules/<Module>.md` (or `<directory>/ARCHITECTURE.md` once it exists)
6. `docs/system/12-work-packages.md` and `docs/system/10-ai-development-workflow.md`

## Hard rules

- Platform owns **mechanisms, never game policy**: no game rules, names, numbers or content in code,
  tests or docs (for example no inventory, quest, trade, economy or combat rules). Game services are
  RunicGame code built on the Go SDK, the item ledger and the wallets.
- Never depend on RunicGame.
- Touch the Engine only through its public interfaces: the `Runic::Network` transport interface and
  connect-ticket hook, the `Runic::Application` Layer, the `Runic::Simulation` service port and the
  `Runic::Core` metrics registry. Direction: Platform C++ includes Engine public headers; the Engine
  never includes Platform code. Never include an Engine `Source/` folder. If the Engine interface
  needs a change, report it instead of working around it.
- The realtime path is direct and broker-free: no NATS, gRPC, database or Agones on per-tick
  replication, ghost or combat traffic.
- Nothing the Platform does may block a simulation tick: I/O runs on its own threads, completions go
  to queues the simulation drains at safe ticks, and no I/O callback touches Flecs.
- Every durable change is an operation with an ID; retries must be safe (Go SDK idempotency store).
- Local Flecs entity IDs never appear in schemas; use `GlobalEntityId`, `GlobalPlayerId` and the
  other plain ID types.
- Library types (GameNetworkingSockets, gRPC, NATS, Agones SDK, Prometheus client) never appear in a
  `Public/` header; C++ modules stay headless (no GLFW, bgfx, RmlUi, ImGui, audio or editor code).
- One work package = one module = one PR. Write only inside that module's directory, its build
  target and its docs; contract (interface and tests) approved before code; Stage A only.
- Do not silently resolve items in `docs/system/11-open-questions.md`; ask.

## Build

```sh
# C++ (standalone; RUNIC_ENGINE_DIR defaults to external/RunicEngine, else ../RunicEngine)
cmake --preset debug && cmake --build --preset debug && ctest --preset debug
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug && cmake --build build && ctest --test-dir build --output-on-failure

# Engine submodule (only when a package needs Engine headers)
git submodule update --init external/RunicEngine

# Go (toolchain version from go.mod)
go build ./... && go test ./...
```

## Docs maintenance

- Update the module contract, `docs/modules/README.md` status, and `docs/current-state.md`
  in the same change as the code.
- `docs/system/` is mirrored in all three repositories; edit all copies together.
