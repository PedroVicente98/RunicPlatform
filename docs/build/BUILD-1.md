# BUILD-1 — Build skeleton: RunicPlatform's part (contract)

This file is RunicPlatform's part of the BUILD-1 contract. The canonical contract — the CMake helpers, the checks, the decisions and the shared acceptance tests — is [RunicEngine docs/build/BUILD-1.md](https://github.com/PedroVicente98/RunicEngine/blob/main/docs/build/BUILD-1.md); approve both together.

| Field | Value |
| --- | --- |
| Package | BUILD-1 (slice 0), Stage A |
| Needs | RunicEngine's BUILD-1 merged first (this repository uses its helpers through the Engine pin) |
| Status | **Contract — awaiting owner review.** The acceptance tests in `tests/build/` exist and fail |

## What BUILD-1 delivers here

| Item | Rule |
| --- | --- |
| Engine pin | `external/RunicEngine` moves to the merge commit of RunicEngine's BUILD-1. `RUNIC_ENGINE_DIR` keeps today's behavior (submodule when populated, else `../RunicEngine`; a superproject that already added the Engine wins) |
| Engine in the build | The Platform now adds the Engine with `add_subdirectory`, with `RUNIC_ENGINE_BUNDLES=OFF`, `RUNIC_ENGINE_BUILD_TESTS=OFF`, `RUNIC_ENGINE_BUILD_TOOLS=OFF`, `RUNIC_BUILD_SANDBOX=OFF` and presentation off. The standalone build therefore configures the helpers (and, from CORE-1, `Runic::Core`) and never Flecs, GLM, Jolt or a presentation library ([03 § Platform modules](../system/03-dependency-rules.md#platform-modules)) |
| Catalog | [`cmake/RunicPlatformCatalog.cmake`](../../cmake/RunicPlatformCatalog.cmake): Contracts, Transport and ServerBindings with the Engine interface targets each may link. Written in this contract for review |
| Modules | `RUNIC_MODULE_NAMESPACE RunicPlatform`; each C++ module is created by its first package (PCT-1, PTR-1, PBND-1) with `runic_add_module`, under `cpp/<Module>/` ([modules/README.md](../modules/README.md#directory-layout)) |
| Bootstrap target | `Runic::Platform` (`cpp/Core/Version.cpp`) stays until RunicGame stops linking it; its smoke test becomes the GoogleTest test `PlatformBootstrap.Version` |
| Tests | `RUNIC_PLATFORM_BUILD_TESTS` calls the Engine's `runic_enable_tests` (GoogleTest pinned once, in the Engine) |
| CPU baseline and warnings | The Engine's `RUNIC_CPU_BASELINE` and `RUNIC_WARNINGS_AS_ERRORS` apply to every Platform C++ target |
| Presets | `debug` (today), `release`, `ci-gcc`, `ci-clang`, each with build and test presets |

## CI

`.github/workflows/ci.yml`, on every push and pull request. The Engine submodule is public, so checkout needs no extra token.

| Job | Runs | Required |
| --- | --- | --- |
| `cpp-gcc`, `cpp-clang` | Checkout with submodules; `ci-gcc` / `ci-clang`: configure, build, `ctest` (bootstrap test and `tests/build/`) | Yes |
| `checks` | `ctest -L checks`: catalog sync, public-header scan, source-include scan | Yes |
| `docs` | The Engine's `DocsCheck` with this repository's rules (`cpp/<Module>/…` needs `cpp/<Module>/ARCHITECTURE.md` or `docs/modules/<Module>.md`; `go/…` needs the Go package's `ARCHITECTURE.md` or its module doc) | Yes (pull requests only) |
| `go` | `actions/setup-go` with `go-version-file: go.mod`; `go vet ./...`, `go build ./...`, `go test ./...` | Yes |

## Acceptance tests

`tests/build/` (registered when `RUNIC_PLATFORM_BUILD_TESTS` is ON in a top-level build, or run alone with `cmake -S tests/build -B build/build-tests -DRUNIC_ENGINE_DIR=…`). They use the Engine's drivers (`tests/build/RunFixture.cmake`, `RunScript.cmake`) and check scripts from the pinned Engine. Today every one fails.

| Test | Passes when |
| --- | --- |
| `build.platform_standalone` | This repository configures on its own, the Engine helpers run (`RUNIC: link checks passed`), and no Flecs, GLM, Jolt, GLFW, bgfx or ImGui build folder exists |
| `build.platform_bootstrap_gtest` | With tests on, the build passes and CTest discovers and passes `PlatformBootstrap.Version` |
| `checks.catalog_sync` | `cmake/RunicPlatformCatalog.cmake` equals the C++ rows of the Platform tables in `docs/system/03-dependency-rules.md` |
| `checks.public_header_scan` | No library type (GameNetworkingSockets, gRPC, NATS, Agones SDK, Prometheus client, Protobuf) appears in any `Public/` header |
| `checks.source_include_scan` | No file includes another module's `Source/` |

Plus the `go` CI job passing on today's Go code.

## Owner actions

- **Repository visibility.** This repository is still private while its docs and license say public ([current-state.md](../current-state.md#owner-action-required-repository-visibility)). It does not block BUILD-1, but RunicGame's CI needs a token to check it out while it stays private.
- **Go toolchain.** `go.mod` requires Go 1.26.0; CI installs it from `go.mod`. Local machines need it too.

## After merge

Update in the same pull request: [docs/current-state.md](../current-state.md) (BUILD-1 done; the new Engine pin), [docs/modules/README.md](../modules/README.md) (slice 0 note) and this file's status.
