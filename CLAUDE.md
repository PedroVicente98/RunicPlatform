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
(`../RunicDocs/content/Architecture/`). RunicDocs is the only place the architecture and the development plan are
written: this repository keeps no copy of them (decided 2026-11-12). RunicDocs is edited on GitHub, so run
`git -C ../RunicDocs pull` before reading it; the local clone can lag. When RunicDocs and anything here disagree,
RunicDocs wins: report the difference. This repository's own documents sit next to the code: the READMEs of
`cpp/`, `proto/`, `go/` and `infra/` (the folder map), each module's `ARCHITECTURE.md`, `cmake/README.md` and this
file. The Platform never links Godot.

## Read before changing anything

1. The module or area you are working on: its folder's `README.md` and its `ARCHITECTURE.md` once it has one.
2. RunicDocs › Architecture › Repositories, build targets and processes (Platform modules) and Platform and operations.
3. RunicDocs › Architecture › Modules, work packages and the implementation contract — the package (write scope,
   Done when, Needs, slice), the module contract and the Building with Claude Code cycle; RunicDocs › Development ›
   the slice note for the package's slice.
4. `cmake/README.md` (this repository's part of the build).

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
- Do not silently resolve open questions (RunicDocs › Architecture › Open questions, such as the canonical Go
  module path); ask the owner.

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

- In the same change as the code: the module's `ARCHITECTURE.md` (its contract and package status) and its folder's
  `README.md` when what a folder holds changes. The PR closes the package's GitHub issue; RunicDocs' Development notes
  read the status from the issues.
- A change to the architecture or the plan is a RunicDocs change, made there by the owner or with the owner's
  approval, never a copy here; `cmake/RunicPlatformCatalog.cmake` must equal RunicDocs' Platform modules table
  (`checks.catalog_sync`).
