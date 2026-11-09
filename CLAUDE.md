# CLAUDE.md — RunicPlatform

RunicPlatform (formerly RunicFabric) is the public (MIT) networking, services and infrastructure
repository of a three-repository MMORPG project (C++ and Go):

- **RunicEngine** (`external/RunicEngine` submodule, or a sibling `../RunicEngine`) — generic C++20
  mechanisms: simulation, networking interfaces and encoding, the entry point and layers, tools.
- **RunicPlatform** (this repo) — Transport (GameNetworkingSockets), Contracts (Protobuf),
  ServerBindings (services bridge, lifecycle, metrics exporter), Go SDK, core services, building
  blocks (item ledger, currency wallets), infrastructure (Agones, Kubernetes, Prometheus, Grafana).
- **RunicGame** (`../RunicGame`, proprietary) — game rules, content, executables and game services.

The source of truth is ARCH v4 (RunicEngine — Technical Architecture), kept in the RunicDocs vault
(`../RunicDocs/content/Architecture/`). `docs/system/03-dependency-rules.md` and `docs/build/` follow v4; the other
docs are still v3 and lose to RunicDocs where they disagree. The Platform never links Godot.

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
- Link only the Engine interface targets: `Runic::NetworkTransport` (header-only transport interface
  and connect-ticket hook), `Runic::SimulationPort` (header-only service port), `Runic::Application`
  (Layer) and `Runic::Core` (plain ID types, metrics registry). Never link `Runic::Network`,
  `Runic::Simulation`, Flecs, Jolt or a gameplay module; a standalone build never configures them.
  Direction: Platform C++ includes Engine interface headers; the Engine never includes Platform code.
  Never include an Engine `Source/` folder. If the Engine interface needs a change, report it instead
  of working around it.
- The realtime path is direct and broker-free: no NATS, gRPC, database or Agones on per-tick
  replication, ghost or combat traffic. `Runic::Network` encodes every realtime message, envelope
  included; Protobuf (Contracts) carries only service APIs, published facts and the connect-ticket
  format, never per-tick traffic.
- Nothing the Platform does may block a simulation tick: I/O runs on its own threads, completions go
  to queues the simulation drains at safe ticks, and no I/O callback touches Flecs.
- Every durable change is an operation with an ID; retries must be safe (Go SDK idempotency store).
- Local Flecs entity IDs never appear in schemas; use `GlobalEntityId`, `GlobalPlayerId` and the
  other plain ID types.
- Library types (GameNetworkingSockets, gRPC, NATS, Agones SDK, Prometheus client) never appear in a
  `Public/` header; C++ modules stay headless (no libgodot, godot-cpp, GodotBridge, GodotTools, audio or editor
  code; the Engine's configure-time headless check enforces it).
- One work package = one module = one PR. Write only inside that module's directory, its build
  target and its docs; contract (interface and tests) approved before code; Stage A only.
- Do not silently resolve items in `docs/system/11-open-questions.md`; ask.

## Build

```sh
# C++ (standalone; RUNIC_ENGINE_DIR defaults to external/RunicEngine, else ../RunicEngine). The Engine is added
# with its bundles, tests, tools and Godot off: only its helpers (runic_add_module, checks, GoogleTest).
cmake --preset debug && cmake --build --preset debug && ctest --preset debug
cmake --preset debug-siblings && cmake --build --preset debug-siblings   # always ../RunicEngine
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
- The docs carry generated Obsidian links: frontmatter tags, `[^…]` markers after names, and the
  `## Connections` footer. Never edit them by hand; after any docs change, run
  `python3 RunicEngine/scripts/docs/obsidian_graph.py RunicEngine RunicPlatform RunicGame --write` from the
  folder that holds the three repositories (sibling checkouts).
