# RunicPlatform module catalog

This file lists the seven Platform modules, where each one lives, what it depends on, its work packages and the slice that first needs it.

The catalog follows ARCH § Repositories, build targets and processes (Platform modules) and ARCH § Modules, work packages and the implementation contract (Platform). Each row links to the module's contract. When a module's folder is created, its contract moves into `<directory>/ARCHITECTURE.md` and the row links there.

## Catalog

| Module | Language | Purpose | Depends on | Packages | First slice | Status |
| --- | --- | --- | --- | --- | --- | --- |
| [Transport](Transport.md) | C++ | GameNetworkingSockets implementation of the Engine transport interface; connect-ticket checks; authoritative and candidate connections; simulation-to-simulation links chosen by locality (in-memory queue, local socket or shared memory, GameNetworkingSockets) | Engine `Runic::NetworkTransport` (header-only transport interface); Contracts | PTR-1 to PTR-4 | 12 | Not started |
| [Contracts](Contracts.md) | Protobuf → C++ and Go | Protobuf service APIs, published facts and the connect-ticket format, generated for C++ and Go; games add their own messages. Realtime messages are encoded by `Runic::Network`, not Protobuf | — | PCT-1 | 12 | Not started |
| [ServerBindings](ServerBindings.md) | C++ | ServicesBridgeLayer (Engine service port over asynchronous gRPC and NATS, completions queued for safe ticks), LifecycleLayer (Agones SDK, local stub mode), Prometheus exporter for the Core metrics registry | Engine interface targets only: `Runic::Application` (Layer), `Runic::SimulationPort` (header-only service port), `Runic::Core` (metrics registry); Contracts | PBND-1 to PBND-4 | 27 | Not started |
| [GoSDK](GoSDK.md) | Go | Service skeleton, configuration, gRPC and NATS wiring, PostgreSQL persistence, transactions, migrations, idempotency store, metrics | Contracts (generated Go code) | PSDK-1 to PSDK-3 | 26 | Not started |
| [CoreServices](CoreServices.md) | Go | Accounts and entitlements, connect tickets, World Coordinator (worlds, regions and placement by load and traffic), instance allocation, world directives, chat and party groups, admission | GoSDK, Contracts | PCS-1 to PCS-7 | 27 | Not started |
| [BuildingBlocks](BuildingBlocks.md) | Go | Item ledger (containers, slots, atomic transfers, operation IDs), currency wallets and transfers that move items and currency in one transaction; mechanisms only | GoSDK, Contracts | PBB-1 to PBB-3 | 28 | Not started |
| [Infrastructure](Infrastructure.md) | Configuration | Local development stack, Agones fleets, Kubernetes manifests, Prometheus and Grafana dashboards | — (runtime only) | PINF-1, PINF-2 | 26 | Not started |

No Platform module depends on RunicGame. Only the two C++ modules link Engine targets, and only the Engine interface targets `Runic::Core`, `Runic::Application`, `Runic::NetworkTransport` and `Runic::SimulationPort`. `Runic::NetworkTransport` and `Runic::SimulationPort` are header-only with Core types only, so a standalone Platform build configures Core and Application and never Flecs, Jolt or the gameplay modules. Go modules need no Engine code.

ARCH's Platform module table (ARCH § Repositories, build targets and processes) lists Contracts as the dependency of Transport and of the Go SDK, and the Go SDK as the dependency of CoreServices and BuildingBlocks; the catalog above also names Contracts for the Go services because their APIs are defined there.

## Directory layout

The layout keeps the folders the repository already has (`cpp/`, `go/`, `proto/`) and adds `infra/`. No existing code moves.

| Module | Directory | Target or package |
| --- | --- | --- |
| Transport | `cpp/Transport/{Public,Source,Tests}` + `ARCHITECTURE.md` + `CMakeLists.txt` | `RunicPlatform::Transport` |
| ServerBindings | `cpp/ServerBindings/{Public,Source,Tests}` + `ARCHITECTURE.md` + `CMakeLists.txt` | `RunicPlatform::ServerBindings` |
| Contracts | `proto/` (sources); generated code in the git-ignored `cpp/generated/` and `go/generated/` | `RunicPlatform::Contracts`; Go package under `go/generated/` |
| GoSDK | `go/sdk/<package>/` | `<module path>/go/sdk/...` |
| CoreServices | `go/services/<service>/`, executables in `go/cmd/<service>/` | `<module path>/go/services/...` |
| BuildingBlocks | `go/blocks/{ledger,wallets}/`, executables in `go/cmd/<service>/` | `<module path>/go/blocks/...` |
| Infrastructure | `infra/{local,agones,kubernetes,monitoring}/` | — |

- C++ modules use the shape every C++ module in the three repositories has: `Public/` (the only headers other code may include), `Source/` (one folder per subsystem), `Tests/` (registered with CTest), `ARCHITECTURE.md`, `CMakeLists.txt`. The target is created through the `runic_add_module` helper once BUILD-1 provides it.
- Go modules use Go's own layout: one directory per package, `internal/` for private code, tests beside the code, standard `testing` package.
- `<module path>` is the placeholder `runic.local/platform` until OQ-9 decides the canonical Go module path ([../system/11-open-questions.md](../system/11-open-questions.md)).
- The bootstrap folders `cpp/Core/`, `cpp/include/` (target `Runic::Platform`) and `go/platform/` stay until their replacements land; see [../current-state.md](../current-state.md).

## Packages by slice

| Slice | Runnable result (ARCH § Vertical-slice roadmap) | Platform packages | Other packages in the slice |
| --- | --- | --- | --- |
| 12. Transport | A client connects to a local server with a test-signed ticket; ping and echo | PCT-1, PTR-1, PTR-2 | NET-1 (Engine) |
| 26. Service foundation | A Go service writes to PostgreSQL idempotently on the local stack | PINF-1, PSDK-1, PSDK-2 | — |
| 27. Accounts and characters | Log in, receive a real ticket, load and save a character | PCS-1, PBND-1 | SIM-5 (Engine); GSVC-1 (defined in RunicGame) |
| 28. Persistence | Kill, loot, log out, keep the item | PBB-1 | GPL-4 (Engine); GSVC-2, GSRV-1 (defined in RunicGame) |
| 30. Quests | A persistent quest driven by gameplay facts | PSDK-3, PBND-4 | QST-1, QST-2 (Engine); GSVC-3, GSRV-3 (defined in RunicGame) |
| 36. Multiple simulations | Walk from simulation A into B | PCS-2, PTR-3 | DSIM-1, DSIM-2, DSIM-3, NET-5 (Engine) |
| 33a. Exploration prototype | Explore at night with a light source, die to a mob, respawn at a respawn point, and keep both the uncovered map and the character build | PBB-2 | GSRV-5, GSRV-6, GSVC-5, GCL-4 (defined in RunicGame) |
| 39. Operations | Fleets on Agones, the Grafana panel, Editor live attach | PBND-2, PBND-3, PINF-2 | NET-7, EDT-7 (Engine) |
| 43. Tides, waves and weather | A tide opens a path; a storm reaches two simulations at the same world time | PCS-3 | ENV-4, ENV-5 (Engine); GWTH-1 (defined in RunicGame) |
| 44+. Expansion | Defined when the expansion slices are planned (includes separate worlds and world transitions, busy-area partitions, placement by traffic and local links) | PTR-4, PCS-4, PCS-5, PCS-6, PCS-7, PBB-3 | Engine and RunicGame packages (for example DSIM-5, NET-8) |

Slice 0 (BUILD-1) also writes in this repository: the module helper, presets, CI, the test framework, the headless and forbidden-dependency checks, the x86-64-v3 CPU baseline, and the CI use of the Engine submodule pin (the pin itself already exists at `external/RunicEngine`). See [../system/12-work-packages.md](../system/12-work-packages.md) for every package and [../system/08-implementation-roadmap.md](../system/08-implementation-roadmap.md) for the roadmap.

## Rules for using this catalog

- Work on one package at a time; a package writes inside one module's directory, its build target and its docs.
- A package starts only when every package in its Needs column is merged, including Engine packages.
- Contract first: the public interface and the acceptance tests are approved before the implementation.
- When a module needs a change in another module or repository, report the interface change instead of making it.
- Update the module's Status here, its contract, and [../current-state.md](../current-state.md) in the same pull request as the code.
