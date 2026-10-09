# RunicPlatform

RunicPlatform is the open-source (MIT) networking, services and infrastructure layer for MMORPGs built on RunicEngine: mechanisms any MMORPG can use, never one game's rules.

> Status: bootstrap. The docs describe the target architecture; no Platform module is implemented yet. See [docs/current-state.md](docs/current-state.md).

## What it provides

| Module | Language | Provides |
| --- | --- | --- |
| Transport | C++ | GameNetworkingSockets implementation of the Engine transport interface; connect-ticket checks; authoritative and candidate connections; simulation-to-simulation links |
| Contracts | Protobuf → C++ and Go | Envelopes and service APIs; games add their own messages |
| ServerBindings | C++ | ServicesBridgeLayer (the Engine service port over asynchronous gRPC and NATS), LifecycleLayer (Agones SDK), Prometheus exporter |
| GoSDK | Go | Service skeleton, configuration, gRPC and NATS wiring, PostgreSQL persistence, transactions, migrations, idempotency store, metrics |
| CoreServices | Go | Accounts and entitlements, connect tickets, World Coordinator, instance allocation, world directives, chat and party groups |
| BuildingBlocks | Go | Item ledger and currency wallets, mechanisms only |
| Infrastructure | Configuration | Local development stack, Agones fleets, Kubernetes manifests, Prometheus and Grafana |

Clients talk directly to their authoritative C++ simulation; no broker, service or database sits on per-tick traffic. Durable work goes through the services bridge and Go services, and results return to the simulation at safe ticks.

## How it fits with the other repositories

- **RunicEngine** (public): generic engine mechanisms. The Platform's C++ code implements Engine interfaces (transport, service port, Layer) and includes only Engine public headers; the Engine never includes Platform code.
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
- `RUNIC_ENGINE_DIR` points at the RunicEngine source tree: `external/RunicEngine` when the submodule is checked out, otherwise `../RunicEngine`. Override it with `-DRUNIC_ENGINE_DIR=<path>`. Nothing builds the Engine yet; the first C++ bindings (PTR-1, PBND-1) will.
- Fetch the Engine pin when you need it: `git submodule update --init external/RunicEngine`.

Go needs the toolchain version declared in `go.mod` (Go 1.26):

```sh
go build ./...
go test ./...
```

`runic.local/platform` is a placeholder module path until the canonical path is decided.

## Documentation

Start at [docs/README.md](docs/README.md). Contributors and Claude Code sessions follow [CLAUDE.md](CLAUDE.md).

## License

MIT; see [LICENSE](LICENSE).
