# RunicPlatform

RunicPlatform is the open-source (MIT) networking, services and infrastructure layer for MMORPGs built on RunicEngine: mechanisms any MMORPG can use, never one game's rules.

> Status: slice 0 (build skeleton) done; no Platform module is implemented yet. The folders of every module already exist with a README (`cpp/`, `proto/`, `go/`, `infra/`).

## What it provides

| Module | Language | Provides |
| --- | --- | --- |
| Transport | C++ | GameNetworkingSockets implementation of the Engine transport interface; connect-ticket checks; authoritative and candidate connections; simulation-to-simulation links |
| Contracts | Protobuf → C++ and Go | Service APIs, published facts and the connect-ticket format; games add their own messages. Never per-tick traffic: the Engine encodes realtime messages |
| ServerBindings | C++ | ServicesBridgeLayer (the Engine service port over asynchronous gRPC and NATS), LifecycleLayer (Agones SDK, with a local stub mode), Prometheus exporter for the Engine's Core metrics registry |
| GoSDK | Go | Service skeleton, configuration, gRPC and NATS wiring, PostgreSQL persistence, transactions, migrations, idempotency store, metrics |
| CoreServices | Go | Accounts and entitlements, connect tickets, World Coordinator, instance allocation, world directives, chat and party groups, admission |
| BuildingBlocks | Go | Item ledger and currency wallets, including item and currency transfers in one transaction; mechanisms only |
| Infrastructure | Configuration | Local development stack, Agones fleets, Kubernetes manifests, Prometheus and Grafana |

Clients talk directly to their authoritative C++ simulation; no broker, service or database sits on per-tick traffic. Durable work goes through the services bridge and Go services, and results return to the simulation at safe ticks.

## How it fits with the other repositories

- **RunicEngine** (public): generic engine mechanisms. The Platform's C++ code implements Engine interfaces (transport, service port, Layer) and links only the Engine interface targets `Runic::Core`, `Runic::Application`, `Runic::NetworkTransport` and `Runic::SimulationPort`, so a standalone build never configures Flecs, Jolt or gameplay modules; the Engine never includes Platform code.
- **RunicGame** (private): a game built on both. It pins RunicEngine and RunicPlatform as submodules.
- This repository pins RunicEngine as a submodule at `external/RunicEngine`, so its C++ bindings build and test on their own.

## Build

C++ needs CMake 3.24+ and a C++20 compiler (Ninja for the presets):

```sh
cmake --preset debug
cmake --build --preset debug
ctest --preset debug
```

Without Ninja:

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build
ctest --test-dir build --output-on-failure
```

- The bootstrap library is `runic_platform` (alias `Runic::Platform`); `RUNIC_PLATFORM_BUILD_TESTS` defaults to ON only for a top-level build.
- `RUNIC_ENGINE_DIR` points at the RunicEngine source tree: `external/RunicEngine` when the submodule is checked out, otherwise `../RunicEngine`. Override it with `-DRUNIC_ENGINE_DIR=<path>`. Nothing builds the Engine yet; the first C++ bindings (PTR-1, PBND-1) will, using only those interface targets.
- Fetch the Engine pin when you need it: `git submodule update --init external/RunicEngine`.

Go needs the toolchain version declared in `go.mod` (Go 1.26):

```sh
go build ./...
go test ./...
```

`runic.local/platform` is a placeholder module path until the canonical path is decided.

## Documentation

The architecture, the roadmap and the status of every package are in the RunicDocs vault
([pedrovicente98.github.io/RunicDocs](https://pedrovicente98.github.io/RunicDocs/)); this repository keeps no copy.
Next to the code: the READMEs of `cpp/`, `proto/`, `go/` and `infra/`, each module's `ARCHITECTURE.md`, and
[cmake/README.md](cmake/README.md) for the build. Contributors and Claude Code sessions follow [CLAUDE.md](CLAUDE.md).

## License

MIT; see [LICENSE](LICENSE).
