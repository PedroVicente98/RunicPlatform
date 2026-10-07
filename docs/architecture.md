# RunicPlatform architecture

## Role

Platform provides **mechanisms that cross a process, machine, service,
orchestration, or persistence boundary**. It is reusable by another game and
never contains RunicGame combat, economy, quest, inventory, or auction policy.
[system/01](system/01-architecture-overview.md)

| Owns | Does not own |
| --- | --- |
| Networking implementation and contracts; client↔simulation and simulation↔simulation transport; service runtime; persistence primitives; identity; world-control plane; Agones/Kubernetes integration; observability. | RunicGame economy/quest/inventory/auction policy; combat/gameplay rules; client presentation; authority *semantics* (Engine DistributedSimulation). |

Since Appendix J, concrete domain services (Character, Inventory, Quest, Trade,
Auction, Economy, Guild, Mail) are **private RunicGame code** built on
Platform's ServiceRuntime, Persistence, and Identity. Platform keeps transport,
contracts, runtime, persistence primitives, idempotency, deployment. [J.1.3]

## Two paths, never mixed

```text
REALTIME PATH (per tick, low latency, direct, broker-free)
  client ──Realtime──► authoritative C++ simulation ◄──Realtime──► neighbor simulation

SERVICE PATH (asynchronous, durable, transactional)
  simulation / client ──ServiceRuntime──► RunicGame Go service ──Persistence──► database

CONTROL PATH
  WorldControl ──control channels──► simulations / clients
  WorldControl ──capacity──► Orchestration ──► Agones / Kubernetes
```

- Go is **outside** the realtime movement/combat path.
- NATS, gRPC, databases, and Agones are never inserted into per-tick ghost or
  combat synchronization. [J.8.4]
- Nothing on the service path ever blocks a simulation tick. [J.7.2]

## Target repository layout

```text
RunicPlatform/
├── Contracts/
├── Realtime/
├── ServiceRuntime/
├── Persistence/
├── WorldControl/
├── Orchestration/
├── Identity/
├── Observability/
└── docs/
```

Each module uses the Go-style layout `api_or_pkg/`, `internal/`, `tests/`,
build/deploy metadata; modules with a C++ side follow the C++ module layout for
that part ([system/02](system/02-module-contract.md#go--platform-package-layout-j5)).
How today's `cpp/`, `go/`, `proto/` folders map onto this is open
([OQ-9](system/11-open-questions.md#oq-9)); see [current-state.md](current-state.md).

## Modules and dependencies

```text
Observability ◄──────────────── everyone
Contracts     ◄── Realtime, ServiceRuntime, WorldControl, Identity, Engine bindings, Game bindings
Identity      ◄── Realtime, ServiceRuntime, WorldControl, Game services
Realtime      ◄── WorldControl (control channels), Engine NetworkAdapter seam
Orchestration ◄── WorldControl (capacity interface)
Persistence   ◄── Game services (and Platform modules needing durable state)
ServiceRuntime◄── Game services, simulation async requests
```

| Module | Allowed dependencies [J.5] | Likely language (proposal) | Phase |
| --- | --- | --- | --- |
| Contracts | — (foundation) | schemas + generated C++/Go | 4 |
| Realtime | Contracts, Identity, Observability; integrates Engine NetworkAdapter | C++ | 4 / 8 / 13 |
| ServiceRuntime | Contracts, Identity, Observability | Go (+ C++ async client) | 9 |
| Persistence | Observability | Go | 9 |
| WorldControl | Contracts, Realtime control channels, Orchestration interface, Identity, Observability | Go | 13 / 14 |
| Orchestration | Observability | Go | 16 |
| Identity | Contracts | Go (+ C++ validation) | 4 |
| Observability | — | Go + C++ hooks | 16 (basic earlier) |

## Relationship to the other repositories

| With | Rule |
| --- | --- |
| RunicEngine | Only through the `NetworkAdapter` ↔ `Realtime` seam and shared `Contracts`. Binding direction is [OQ-1](system/11-open-questions.md#oq-1). Engine never depends on Agones/K8s/DB/gRPC/NATS. Platform never implements authority semantics. |
| RunicGame | Game depends on Platform; Platform never depends on Game. Game-specific schemas and services live in RunicGame and use Platform mechanisms. |

## Development order

1. **Phase 4:** Contracts, Realtime (client↔simulation), Identity — first multiplayer.
2. **Phase 8:** Realtime interest filtering.
3. **Phase 9:** ServiceRuntime, Persistence — with Game Character/Inventory services.
4. **Phase 13–14:** Realtime sim↔sim peers and connection roles, WorldControl.
5. **Phase 16:** Orchestration (Agones/Kubernetes), Observability, hardening.

Until phase 16, simulations run as ordinary local processes; Kubernetes is not
required for development.

## Build (current)

```sh
# C++
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug && cmake --build build
ctest --test-dir build --output-on-failure
# Go (Go 1.26+)
go build ./... && go test ./...
```
