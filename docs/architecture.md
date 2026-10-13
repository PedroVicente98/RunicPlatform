---
# obsidian-graph: generated tags and aliases
tags:
  - repo/platform
  - source/arch
  - type/architecture
---

# RunicPlatform architecture

This file explains how RunicPlatform is organized, how it connects to RunicEngine and RunicGame, and the rules every Platform change must keep.

Source: ARCH[^arch] (RunicEngine — Technical Architecture v3, revision 502), mainly § Repositories, build targets and processes, § Modules, work packages and the implementation contract, § Networking: stack, sessions and responsiveness, § Networking: replication, interest and handoff, and § Platform and operations. When this file and ARCH disagree, ARCH wins.

## Scope: mechanisms, never policy

The Platform supplies the services every MMORPG needs, an SDK for building more, and the infrastructure that places one multi-core simulation per region. Game-specific services live in RunicGame on that SDK. Another team could build a different MMORPG on the Engine and the Platform.

| Platform owns | Platform never owns |
| --- | --- |
| The GameNetworkingSockets transport behind the Engine transport interface | Wire encoding of every realtime message, envelope included: inputs, snapshots, deltas, ghost deltas, transfer messages (Engine `Runic::Network`[^engine-network]) |
| Protobuf service APIs, published facts and the connect-ticket format | Authority semantics, epochs, transfer (Engine `Runic::DistributedSimulation`[^engine-distributedsimulation]) |
| C++ server bindings[^platform-serverbindings]: services bridge, lifecycle, metrics exporter | Which layers a server composes (RunicGame) |
| Go SDK[^platform-gosdk]: skeleton, gRPC, NATS, PostgreSQL, transactions, idempotency | Characters, inventory rules, quest progress, economy, trade, guilds, mail, housing, durable water state and every other game rule or game-owned state (RunicGame services, stored through the Go SDK) |
| Core services[^platform-coreservices]: accounts and `GlobalPlayerId` issue, entitlements, connect tickets, World Coordinator (worlds, the world epoch and placement by load and traffic), instances, world directives with a duration, chat and party groups, admission | Game messages, game data, game dashboards (RunicGame) |
| Building blocks[^platform-buildingblocks]: item ledger and currency wallets, including one-transaction item and currency transfers; mechanisms only | What an item or a currency means |
| Infrastructure[^platform-infrastructure]: local stack, Agones, Kubernetes, Prometheus, Grafana | Live inspection of a server (Engine Editor[^engine-editor] attach, development and staging builds only) |

## Modules

| Module | Language | Packages | Contract |
| --- | --- | --- | --- |
| Transport[^platform-transport] | C++ | PTR-1 to PTR-4 | [modules/Transport.md](modules/Transport.md) |
| Contracts[^platform-contracts] | Protobuf → C++ and Go | PCT-1 | [modules/Contracts.md](modules/Contracts.md) |
| ServerBindings[^platform-serverbindings] | C++ | PBND-1 to PBND-4 | [modules/ServerBindings.md](modules/ServerBindings.md) |
| GoSDK[^platform-gosdk] | Go | PSDK-1 to PSDK-3 | [modules/GoSDK.md](modules/GoSDK.md) |
| CoreServices[^platform-coreservices] | Go | PCS-1 to PCS-7 | [modules/CoreServices.md](modules/CoreServices.md) |
| BuildingBlocks[^platform-buildingblocks] | Go | PBB-1 to PBB-3 | [modules/BuildingBlocks.md](modules/BuildingBlocks.md) |
| Infrastructure[^platform-infrastructure] | Configuration | PINF-1, PINF-2 | [modules/Infrastructure.md](modules/Infrastructure.md) |

The catalog with dependencies, directories and slices is [modules/README.md](modules/README.md).

## Dependency direction

```text
RunicGame ──────────────────────────────────────────────► RunicEngine
    │                                                          ▲
    ▼                                                          │ Engine interface targets only:
RunicPlatform C++ (Transport, ServerBindings) ─────────────────┘ Runic::Core, Runic::Application,
    │                                                            Runic::NetworkTransport, Runic::SimulationPort
    ▼
Contracts ◄──── RunicPlatform Go (GoSDK ◄── CoreServices, BuildingBlocks)
```

Arrows point from a part to what it builds on. Nothing points from the Engine to the Platform, and nothing points into RunicGame.

- The Platform implements Engine interfaces: the transport interface (Transport[^platform-transport]), the Simulation's service port (ServicesBridgeLayer[^platform-serverbindings]) and the Layer interface (ServicesBridgeLayer, LifecycleLayer).
- Platform C++ links only Engine interface targets:

  | Engine target | What the Platform uses | Linked by |
  | --- | --- | --- |
  | `Runic::NetworkTransport`[^engine-network] | Header-only: the transport interface and the connect-ticket hook (NET-1); Core types only | Transport |
  | `Runic::SimulationPort`[^engine-simulation] | Header-only: the service port (SIM-5); Core types only | ServerBindings |
  | `Runic::Application`[^engine-application] | The Layer interface (APP-1) | ServerBindings |
  | `Runic::Core`[^engine-core] | Plain ID types (CORE-1) and the metrics registry (CORE-2) | ServerBindings (and Transport through the Core types its interface uses) |

  Never `Runic::Network`, `Runic::Simulation`, Flecs, Jolt, a gameplay module or an Engine `Source/` folder. Because the two interface targets include only Core types, a standalone Platform build configures Core and Application and never Flecs, Jolt or the gameplay modules.
- Transport and the Go SDK[^platform-gosdk] depend on Contracts[^platform-contracts]; CoreServices[^platform-coreservices] and BuildingBlocks[^platform-buildingblocks] build on the Go SDK.
- The Engine never includes Platform code; it has no Agones, Kubernetes, gRPC, NATS or database dependency.
- The Platform never depends on RunicGame, in code, tests or docs. RunicGame depends on both.
- Platform Go code needs no Engine code.
- Library types (GameNetworkingSockets, gRPC, NATS, Agones SDK, Prometheus client) never appear in a Platform `Public/` header.

## Three paths, never mixed

```text
REALTIME PATH  (per tick, direct, broker-free)
  client ◄──Transport──► authoritative simulation ◄──Transport──► neighbor simulation
                                                    (in-memory, local or network link, by locality)

SERVICE PATH   (asynchronous, durable, idempotent)
  simulation ──service port──► ServicesBridgeLayer ──gRPC / NATS──► Go service ──► PostgreSQL
             ◄── completion queued, applied at a later safe tick ◄──┘

CONTROL PATH   (operations)
  World Coordinator ──► placement requests ──► Agones / Kubernetes
  LifecycleLayer ──► Agones SDK (Ready, health, shutdown)
```

- The realtime path is direct and broker-free. No NATS, gRPC, database or Agones on per-tick replication, ghost or combat traffic. Simulation-to-simulation traffic uses the cheapest direct channel for where the peers run: an in-memory queue in one process, a local socket or shared memory on one machine, GameNetworkingSockets between machines (PTR-4[^platform-transport]); DistributedSimulation[^engine-distributedsimulation] semantics do not change with the channel.
- `Runic::Network`[^engine-network] encodes every message on the realtime connection, envelope included. Protobuf (Contracts[^platform-contracts]) carries only service APIs, published facts and the connect-ticket format, never per-tick traffic.
- Nothing the Platform does blocks a simulation tick. Network I/O and service clients run on their own threads and only enqueue.

| Piece | Used for |
| --- | --- |
| GameNetworkingSockets (Transport) | Real-time UDP, client ↔ simulation and simulation ↔ simulation between machines: reliable and unreliable messages, encryption, congestion control |
| Engine encoding (`Runic::Network`) | Every realtime message, envelope included; high-frequency payloads bit-packed and quantized |
| Protobuf (Contracts) | Service APIs, published facts and the connect-ticket format; never per-tick traffic |
| gRPC (GoSDK[^platform-gosdk] PSDK-1, ServicesBridgeLayer[^platform-serverbindings] PBND-1) | Calls that need an answer, for example loading a character or allocating an instance |
| NATS (GoSDK PSDK-3, ServicesBridgeLayer PBND-4; both slice 30) | Publish and subscribe without an answer; JetStream only where replay is required |
| Agones and Kubernetes (Infrastructure[^platform-infrastructure], LifecycleLayer, World Coordinator[^platform-coreservices]) | Simulation lifecycle, placement, fleets, configuration |

## Server layers and the services bridge

The GameServer (RunicGame) composes its layer stack bottom to top:

| Layer | Owner |
| --- | --- |
| Network: ingress and egress | Engine (uses the Platform transport) |
| Simulation: scheduler and world | Engine |
| Services bridge[^platform-serverbindings]: gRPC, NATS | Platform ServerBindings (PBND-1 gRPC, PBND-4 NATS) |
| Lifecycle: Agones, or a local stub mode without Agones | Platform ServerBindings (PBND-2) |
| Diagnostics: network and replication metrics into the Core registry, Editor attach endpoint (development and staging builds) | Engine (NET-7[^engine-network]) |

The Engine's only door to durable services is the Simulation's service port (SIM-5[^engine-simulation], shipped as the header-only `Runic::SimulationPort`): an outbox of durable operations with stable operation IDs and an inbox of accepted results drained at safe ticks. The ServicesBridgeLayer implements it, with gRPC from slice 27 (PBND-1) and NATS from slice 30 (PBND-4):

1. A simulation system writes an operation with a stable ID to the outbox.
2. The bridge's I/O threads send it over gRPC (answer needed, PBND-1) or publish it on NATS (no answer, PBND-4).
3. The service validates the source, deduplicates by operation ID, commits in one transaction.
4. The result is queued into the inbox.
5. The simulation applies it at a later safe tick. No I/O callback touches Flecs.
6. A replayed operation changes nothing.

In the other direction, NATS subscriptions (PBND-4) deliver world directives[^platform-coreservices] (PCS-3) and other subscribed messages into the inbox; the simulation applies them at a safe tick, never from the NATS callback.

## Connect tickets and sessions

1. The client logs in through the Platform accounts service and receives a signed, short-lived connect ticket for its simulation.
2. The client opens a transport connection directly to the simulation and presents the ticket first.
3. The simulation checks the ticket locally (signature, expiry and key ID, against a configured set of public keys) through Transport[^platform-transport]'s verifier (PTR-2), with no service call in the hot path.
4. The WorldSession survives handoffs: one authoritative connection plus up to three candidate connections near borders (PTR-3). Connection roles are Primary, WarmCandidate, Dormant and Retiring; gameplay code never reasons about addresses.
5. Worlds never share a border. Moving to another world (a separate map, an instance) is a world transition (Engine NET-8[^engine-network]): the source simulation checkpoints the character through the service port, PCS-1[^platform-coreservices] issues a ticket for the destination simulation, and the client connects there while it loads.

Tickets are test-signed with a local key from slice 12 (PTR-2) until the accounts service (PCS-1, slice 27) issues real ones, signed with rotating keys whose public halves the simulations load. The ticket format is a Contracts[^platform-contracts] message (PCT-1). PCS-1 also issues each player's `GlobalPlayerId`, the plain player ID type in Engine Core[^engine-core] (CORE-1).

## Monitoring split

| Part | Owner |
| --- | --- |
| Recording simulation metrics: time per clock domain and system, tick backlog, players, entities, bandwidth per client, handoffs, ghosts | Every GameServer, in the Core metrics registry (CORE-2[^engine-core]); the Engine Diagnostics layer (NET-7[^engine-network]) adds network and replication metrics |
| Publishing the Core registry to Prometheus | Platform exporter (PBND-3[^platform-serverbindings]; needs CORE-2 and SIM-1[^engine-simulation]), the only metrics endpoint of a production server |
| Go service metrics | Platform GoSDK[^platform-gosdk] |
| Fleets, allocations, game-server states | Agones, scraped by the same Prometheus |
| One operations panel, logs included | Grafana (Platform Infrastructure[^platform-infrastructure], PINF-2); game dashboards live in RunicGame |
| Live inspection (entity inspector, behavior trees, resolver traces, debug shapes) | Engine Editor[^engine-editor] attach, compiled only into development and staging builds |

## Building Go services with the SDK

Every Platform and Game Go service is built the same way:

1. Start from the SDK service skeleton: configuration, gRPC wiring, metrics (PSDK-1[^platform-gosdk]).
2. Define the service API in Protobuf (Contracts[^platform-contracts] for Platform services; the Game's own schemas for Game services).
3. Store state in PostgreSQL through the SDK: transactions and migrations (PSDK-2).
4. Wrap every durable change in the SDK idempotency store, keyed by the operation ID (PSDK-2).
5. Publish or consume facts through the SDK's NATS wiring when no answer is needed (PSDK-3).
6. Run locally against the one-command stack (PINF-1[^platform-infrastructure]); deploy with the Kubernetes manifests (PINF-2).

Game services that hold items or currencies call the item ledger[^platform-buildingblocks] (PBB-1) and wallets (PBB-2), which apply no game rule. A transfer that moves items and currency together commits in one transaction (PBB-3). Game state with no Platform building block, for example durable water state, is stored by a Game service on the Go SDK and reaches the simulation through the service port.

## Idempotency

- Every durable change is an operation with an ID, so retries are safe.
- Stable event IDs are a SimulationId plus a sequence (EVT-1[^engine-events]); services deduplicate by them.
- The Go SDK[^platform-gosdk] owns transactions and the idempotency store (OQ-16[^oq-16]); the deduplication check and the effect commit together.
- The simulation never waits for the database. Durable writes happen at explicit boundaries (logout, trade, periodic checkpoint).

## World time and directives

| Item | Owner |
| --- | --- |
| The world epoch world time counts from | World Coordinator[^platform-coreservices] (PCS-2, slice 36); until then the Engine Environment[^engine-environment] clock (ENV-1, slice 25) reads it from configuration |
| Deciding a world-wide override, for example a storm | A RunicGame service |
| World directives with an effective world time and a duration (weather, wind and current events) | Platform CoreServices (PCS-3, slice 43) |
| Delivering directives to every simulation owning the affected regions | ServicesBridgeLayer[^platform-serverbindings] NATS subscriptions (PBND-4), applied at a safe tick |
| Applying an override at its effective time and returning to the baseline when it ends | Engine `Runic::Environment` |

## Operations

- One region per simulation pod by default; quiet neighbors may share a pod.
- Pods request whole vCPUs; the simulation sizes its worker pool from them and can grow in place (Kubernetes in-place resize).
- Moving to a bigger machine is a handoff: the World Coordinator[^platform-coreservices] starts a new pod, transfers the region and retires the old one.
- A busy area such as a city can get its own simulation through an Engine AuthorityPartition (DSIM-5[^engine-distributedsimulation]), using the same border handoff; a partition never cuts an indivisible volume.
- Placement by load and traffic (PCS-7): the World Coordinator places simulations by load, memory and inter-simulation traffic, with distance from the regions' global coordinates, and moves pairs that exchange much traffic onto one node by move-by-handoff, up to a per-node cap. Their link then uses the cheaper local channel (PTR-4[^platform-transport]).
- A new open-world simulation is never allocated inside a handoff's critical path.
- Worlds are hosted in regional datacenters, each with its own Kubernetes cluster and Agones; accounts are global.
- Gameplay work never needs Kubernetes: run GameServer directly, without a lifecycle layer or with the LifecycleLayer[^platform-serverbindings]'s local stub mode (PBND-2), and, only when needed, the local stack (PINF-1[^platform-infrastructure]).
- Admission (per-world capacity limits, login queue, cohort waves) is a Platform mechanism (PCS-6, slice 44+); when a game uses it is the game's decision.

## Repository wiring

Decided in ARCH[^arch] as "hybrid":

| Situation | How the Engine is found |
| --- | --- |
| Platform CI and standalone C++ builds | The submodule pinned at `external/RunicEngine` (`https://github.com/PedroVicente98/RunicEngine.git`) |
| Daily work | The CMake cache variable `RUNIC_ENGINE_DIR` points at a sibling checkout (default `../RunicEngine` when the submodule is not checked out) |
| RunicGame superproject | RunicGame pins both the Engine and the Platform as submodules and provides the Engine targets itself; the Platform then does not touch Engine resolution |

- `RUNIC_ENGINE_DIR` defaults to `external/RunicEngine` when that folder has a `CMakeLists.txt`, otherwise to `../RunicEngine`. Override it with `-DRUNIC_ENGINE_DIR=<path>`.
- The Engine is not added to the build yet. The C++ bindings start using it with PTR-1[^platform-transport] (Transport) and PBND-1[^platform-serverbindings] (ServerBindings); the first of those packages adds the Engine to the build, guarded so a superproject that already provides Engine targets is never affected.
- That standalone build configures only `Runic::Core`[^engine-core], `Runic::Application`[^engine-application], `Runic::NetworkTransport`[^engine-network] and `Runic::SimulationPort`[^engine-simulation], never Flecs, Jolt or the gameplay modules. The Engine commit pinned today cannot do that yet; see [current-state.md](current-state.md#gaps-against-v3).
- Fetching the submodule: `git submodule update --init external/RunicEngine`. Moving the pin to a new Engine commit is its own reviewed change.

## Directory layout

| Path | Contents |
| --- | --- |
| `cpp/Transport/`, `cpp/ServerBindings/` | C++ modules (to be created by PTR-1[^platform-transport] and PBND-1[^platform-serverbindings]) |
| `cpp/Core/`, `cpp/include/` | Bootstrap library `Runic::Platform` (version stub), kept until its consumers move to module targets |
| `proto/` | Contracts[^platform-contracts] schema sources |
| `cpp/generated/`, `go/generated/` | Generated code (git-ignored) |
| `go/sdk/`, `go/services/`, `go/blocks/`, `go/cmd/` | Go SDK[^platform-gosdk], core services[^platform-coreservices], building blocks[^platform-buildingblocks], executables (to be created) |
| `go/platform/` | Bootstrap placeholder package, replaced by PSDK-1 |
| `infra/` | Infrastructure[^platform-infrastructure] (to be created by PINF-1) |
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

<!-- obsidian-graph:start -->

---

## Connections

*Generated for the Obsidian graph. The numbered markers in the text jump to the footnotes below, which link the notes they refer to.*

- **See also:** [[../docs/README|Platform docs README]] · [[../../RunicEngine/docs/system/README|System README]]

[^arch]: #source/arch — ARCH, "RunicEngine — Technical Architecture v3": the architecture source of truth (a project document, not a note in this vault)
[^engine-network]: [[../../RunicEngine/docs/modules/Network|Network]] — Engine module · Networking
[^engine-distributedsimulation]: [[../../RunicEngine/docs/modules/DistributedSimulation|DistributedSimulation]] — Engine module · Networking
[^platform-serverbindings]: [[../docs/modules/ServerBindings|ServerBindings]] — Platform module · C++
[^platform-gosdk]: [[../docs/modules/GoSDK|GoSDK]] — Platform module · Go
[^platform-coreservices]: [[../docs/modules/CoreServices|CoreServices]] — Platform module · Go
[^platform-buildingblocks]: [[../docs/modules/BuildingBlocks|BuildingBlocks]] — Platform module · Go
[^platform-infrastructure]: [[../docs/modules/Infrastructure|Infrastructure]] — Platform module · configuration
[^engine-editor]: [[../../RunicEngine/docs/modules/Editor|Editor]] — Engine module · Tools
[^platform-transport]: [[../docs/modules/Transport|Transport]] — Platform module · C++
[^platform-contracts]: [[../docs/modules/Contracts|Contracts]] — Platform module · Protobuf
[^engine-simulation]: [[../../RunicEngine/docs/modules/Simulation|Simulation]] — Engine module · Simulation core
[^engine-application]: [[../../RunicEngine/docs/modules/Application|Application]] — Engine module · Foundation
[^engine-core]: [[../../RunicEngine/docs/modules/Core|Core]] — Engine module · Foundation
[^engine-events]: [[../../RunicEngine/docs/modules/Events|Events]] — Engine module · Foundation
[^oq-16]: [[../docs/system/11-open-questions#OQ-16 — Quest storage placement (decided 2026-10-09)|OQ-16]] — open question or decision
[^engine-environment]: [[../../RunicEngine/docs/modules/Environment|Environment]] — Engine module · World systems
