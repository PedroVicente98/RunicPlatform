# RunicPlatform architecture

This file explains how RunicPlatform is organized, how it connects to RunicEngine and RunicGame, and the rules every Platform change must keep.

Source: ARCH (RunicEngine — Technical Architecture v3), mainly § Repositories, build targets and processes, § Modules, work packages and the implementation contract, § Networking: stack, sessions and responsiveness, § Networking: replication, interest and handoff, and § Platform and operations. When this file and ARCH disagree, ARCH wins.

## Scope: mechanisms, never policy

The Platform supplies the services every MMORPG needs, an SDK for building more, and the infrastructure that places one multi-core simulation per region. Game-specific services live in RunicGame on that SDK. Another team could build a different MMORPG on the Engine and the Platform.

| Platform owns | Platform never owns |
| --- | --- |
| The GameNetworkingSockets transport behind the Engine transport interface | Wire encoding of snapshots, deltas and ghost deltas (Engine `Runic::Network`) |
| Protobuf envelopes and service APIs | Authority semantics, epochs, transfer (Engine `Runic::DistributedSimulation`) |
| C++ server bindings: services bridge, lifecycle, metrics exporter | Which layers a server composes (RunicGame) |
| Go SDK: skeleton, gRPC, NATS, PostgreSQL, transactions, idempotency | Characters, inventory rules, quest progress, economy, trade, guilds, mail, housing and every other game rule (RunicGame services) |
| Core services: accounts, entitlements, connect tickets, World Coordinator, instances, world directives, chat and party groups | Game messages, game data, game dashboards (RunicGame) |
| Building blocks: item ledger and currency wallets, mechanisms only | What an item or a currency means |
| Infrastructure: local stack, Agones, Kubernetes, Prometheus, Grafana | Live inspection of a server (Engine Editor attach, development builds only) |

## Modules

| Module | Language | Packages | Contract |
| --- | --- | --- | --- |
| Transport | C++ | PTR-1 to PTR-3 | [modules/Transport.md](modules/Transport.md) |
| Contracts | Protobuf → C++ and Go | PCT-1 | [modules/Contracts.md](modules/Contracts.md) |
| ServerBindings | C++ | PBND-1 to PBND-3 | [modules/ServerBindings.md](modules/ServerBindings.md) |
| GoSDK | Go | PSDK-1 to PSDK-3 | [modules/GoSDK.md](modules/GoSDK.md) |
| CoreServices | Go | PCS-1 to PCS-5 | [modules/CoreServices.md](modules/CoreServices.md) |
| BuildingBlocks | Go | PBB-1, PBB-2 | [modules/BuildingBlocks.md](modules/BuildingBlocks.md) |
| Infrastructure | Configuration | PINF-1, PINF-2 | [modules/Infrastructure.md](modules/Infrastructure.md) |

The catalog with dependencies, directories and slices is [modules/README.md](modules/README.md).

## Dependency direction

```text
RunicGame ─────────────────────────────────────► RunicEngine
    │                                                 ▲
    ▼                                                 │ Engine public interface headers only
RunicPlatform C++ (Transport, ServerBindings) ────────┘
    │
    ▼
Contracts ◄──── RunicPlatform Go (GoSDK ◄── CoreServices, BuildingBlocks)
```

Arrows point from a part to what it builds on. Nothing points from the Engine to the Platform, and nothing points into RunicGame.

- The Platform implements Engine interfaces: the transport interface (Transport), the Simulation's service port (ServicesBridgeLayer) and the Layer interface (ServicesBridgeLayer, LifecycleLayer).
- Platform C++ includes only Engine public headers: `Runic::Network` (transport interface, connect-ticket hook), `Runic::Application` (Layer), `Runic::Simulation` (service port), `Runic::Core` (metrics registry). Never an Engine `Source/` folder.
- The Engine never includes Platform code; it has no Agones, Kubernetes, gRPC, NATS or database dependency.
- The Platform never depends on RunicGame, in code, tests or docs. RunicGame depends on both.
- Platform Go code needs no Engine code.
- Library types (GameNetworkingSockets, gRPC, NATS, Agones SDK, Prometheus client) never appear in a Platform `Public/` header.

## Three paths, never mixed

```text
REALTIME PATH  (per tick, direct, broker-free)
  client ◄──Transport──► authoritative simulation ◄──Transport──► neighbor simulation

SERVICE PATH   (asynchronous, durable, idempotent)
  simulation ──service port──► ServicesBridgeLayer ──gRPC / NATS──► Go service ──► PostgreSQL
             ◄── completion queued, applied at a later safe tick ◄──┘

CONTROL PATH   (operations)
  World Coordinator ──► placement requests ──► Agones / Kubernetes
  LifecycleLayer ──► Agones SDK (Ready, health, shutdown)
```

- The realtime path is direct and broker-free. No NATS, gRPC, database or Agones on per-tick replication, ghost or combat traffic. Simulation-to-simulation traffic uses GameNetworkingSockets directly.
- Nothing the Platform does blocks a simulation tick. Network I/O and service clients run on their own threads and only enqueue.

| Piece | Used for |
| --- | --- |
| GameNetworkingSockets (Transport) | Real-time UDP, client ↔ simulation and simulation ↔ simulation: reliable and unreliable messages, encryption, congestion control |
| Protobuf (Contracts) | Envelopes and service messages; high-frequency replication payloads inside the realtime envelope are bit-packed and quantized by the Engine |
| gRPC (GoSDK, ServicesBridgeLayer) | Calls that need an answer, for example loading a character or allocating an instance |
| NATS (GoSDK, ServicesBridgeLayer) | Publish and subscribe without an answer; JetStream only where replay is required |
| Agones and Kubernetes (Infrastructure, LifecycleLayer, World Coordinator) | Simulation lifecycle, placement, fleets, configuration |

## Server layers and the services bridge

The GameServer (RunicGame) composes its layer stack bottom to top:

| Layer | Owner |
| --- | --- |
| Network: ingress and egress | Engine (uses the Platform transport) |
| Simulation: scheduler and world | Engine |
| Services bridge: gRPC, NATS | Platform ServerBindings (PBND-1) |
| Lifecycle: Agones | Platform ServerBindings (PBND-2) |
| Diagnostics: metrics, Editor attach endpoint | Engine (NET-7) |

The Engine's only door to durable services is the Simulation's service port (SIM-5): an outbox of durable operations with stable operation IDs and an inbox of accepted results drained at safe ticks. The ServicesBridgeLayer implements it:

1. A simulation system writes an operation with a stable ID to the outbox.
2. The bridge's I/O threads send it over gRPC (answer needed) or NATS (no answer).
3. The service validates the source, deduplicates by operation ID, commits in one transaction.
4. The result is queued into the inbox.
5. The simulation applies it at a later safe tick. No I/O callback touches Flecs.
6. A replayed operation changes nothing.

## Connect tickets and sessions

1. The client logs in through the Platform accounts service and receives a signed, short-lived connect ticket for its simulation.
2. The client opens a transport connection directly to the simulation and presents the ticket first.
3. The simulation checks the ticket locally (signature and expiry) through Transport's verifier (PTR-2), with no service call in the hot path.
4. The WorldSession survives handoffs: one authoritative connection plus up to three candidate connections near borders (PTR-3). Connection roles are Primary, WarmCandidate, Dormant and Retiring; gameplay code never reasons about addresses.

Tickets are test-signed with a local key from slice 12 (PTR-2) until the accounts service (PCS-1, slice 27) issues real ones.

## Monitoring split

| Part | Owner |
| --- | --- |
| Collecting simulation metrics: time per clock domain and system, tick backlog, players, entities, bandwidth per client, handoffs, ghosts | Engine Diagnostics layer (NET-7), from the Core metrics registry (CORE-2) |
| Publishing them to Prometheus | Platform exporter (PBND-3), the only metrics endpoint of a production server |
| Go service metrics | Platform GoSDK |
| Fleets, allocations, game-server states | Agones, scraped by the same Prometheus |
| One operations panel, logs included | Grafana (Platform Infrastructure, PINF-2); game dashboards live in RunicGame |
| Live inspection (entity inspector, behavior trees, resolver traces, debug shapes) | Engine Editor attach, compiled only into development builds |

## Building Go services with the SDK

Every Platform and Game Go service is built the same way:

1. Start from the SDK service skeleton: configuration, gRPC wiring, metrics (PSDK-1).
2. Define the service API in Protobuf (Contracts for Platform services; the Game's own schemas for Game services).
3. Store state in PostgreSQL through the SDK: transactions and migrations (PSDK-2).
4. Wrap every durable change in the SDK idempotency store, keyed by the operation ID (PSDK-2).
5. Publish or consume facts through the SDK's NATS wiring when no answer is needed (PSDK-3).
6. Run locally against the one-command stack (PINF-1); deploy with the Kubernetes manifests (PINF-2).

Game services that hold items or currencies call the item ledger (PBB-1) and wallets (PBB-2), which apply no game rule.

## Idempotency

- Every durable change is an operation with an ID, so retries are safe.
- Stable event IDs are a SimulationId plus a sequence (EVT-1); services deduplicate by them.
- The Go SDK owns transactions and the idempotency store (OQ-16); the deduplication check and the effect commit together.
- The simulation never waits for the database. Durable writes happen at explicit boundaries (logout, trade, periodic checkpoint).

## Operations

- One region per simulation pod by default; quiet neighbors may share a pod.
- Pods request whole vCPUs; the simulation sizes its worker pool from them and can grow in place (Kubernetes in-place resize).
- Moving to a bigger machine is a handoff: the World Coordinator starts a new pod, transfers the region and retires the old one.
- A new open-world simulation is never allocated inside a handoff's critical path.
- Worlds are hosted in regional datacenters, each with its own Kubernetes cluster and Agones; accounts are global.
- Gameplay work never needs Kubernetes: run GameServer directly with a local lifecycle stub and, only when needed, the local stack (PINF-1).

## Repository wiring

Decided in ARCH as "hybrid":

| Situation | How the Engine is found |
| --- | --- |
| Platform CI and standalone C++ builds | The submodule pinned at `external/RunicEngine` (`https://github.com/PedroVicente98/RunicEngine.git`) |
| Daily work | The CMake cache variable `RUNIC_ENGINE_DIR` points at a sibling checkout (default `../RunicEngine` when the submodule is not checked out) |
| RunicGame superproject | RunicGame pins both the Engine and the Platform as submodules and provides the Engine targets itself; the Platform then does not touch Engine resolution |

- `RUNIC_ENGINE_DIR` defaults to `external/RunicEngine` when that folder has a `CMakeLists.txt`, otherwise to `../RunicEngine`. Override it with `-DRUNIC_ENGINE_DIR=<path>`.
- The Engine is not added to the build yet. The C++ bindings start using it with PTR-1 (Transport) and PBND-1 (ServerBindings); the first of those packages adds the Engine to the build, guarded so a superproject that already provides Engine targets is never affected.
- Fetching the submodule: `git submodule update --init external/RunicEngine`. Moving the pin to a new Engine commit is its own reviewed change.

## Directory layout

| Path | Contents |
| --- | --- |
| `cpp/Transport/`, `cpp/ServerBindings/` | C++ modules (to be created by PTR-1 and PBND-1) |
| `cpp/Core/`, `cpp/include/` | Bootstrap library `Runic::Platform` (version stub), kept until its consumers move to module targets |
| `proto/` | Contracts schema sources |
| `cpp/generated/`, `go/generated/` | Generated code (git-ignored) |
| `go/sdk/`, `go/services/`, `go/blocks/`, `go/cmd/` | Go SDK, core services, building blocks, executables (to be created) |
| `go/platform/` | Bootstrap placeholder package, replaced by PSDK-1 |
| `infra/` | Infrastructure (to be created by PINF-1) |
| `external/RunicEngine` | Engine submodule pin |
| `tests/` | Bootstrap smoke test |
| `docs/` | These docs; `docs/system/` is mirrored in all three repositories |

## Build

```sh
# C++ (CMake 3.24+, C++20, Ninja for the preset)
cmake --preset debug && cmake --build --preset debug && ctest --preset debug
# or without the preset
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug && cmake --build build && ctest --test-dir build --output-on-failure

# Go (the toolchain version in go.mod)
go build ./... && go test ./...
```
