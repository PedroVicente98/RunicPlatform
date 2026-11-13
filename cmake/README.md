# cmake/ — RunicPlatform's build (its part of BUILD-1)

This file is RunicPlatform's part of the BUILD-1 contract. The canonical contract — the CMake helpers, the checks, the decisions and the shared acceptance tests — is [RunicEngine cmake/README.md](https://github.com/PedroVicente98/RunicEngine/blob/main/cmake/README.md); approve both together.

| Field | Value |
| --- | --- |
| Package | BUILD-1 (slice 0), Stage A |
| Needs | RunicEngine's BUILD-1 merged first (this repository uses its helpers through the Engine pin) |
| Status | **Done** in slice 0 and committed on `main`. The Engine pin (`external/RunicEngine`) still points at `fb84529`, older than BUILD-1; local builds use the sibling `../RunicEngine` until the pin moves |

## What BUILD-1 delivers here

| Item | Rule |
| --- | --- |
| Engine pin | `external/RunicEngine` moves to the merge commit of RunicEngine's BUILD-1. `RUNIC_ENGINE_DIR` keeps today's behavior (submodule when populated, else `../RunicEngine`; a superproject that already added the Engine wins) |
| Engine in the build | The Platform now adds the Engine with `add_subdirectory`, with `RUNIC_ENGINE_BUNDLES=OFF`, `RUNIC_ENGINE_BUILD_TESTS=OFF`, `RUNIC_ENGINE_BUILD_TOOLS=OFF`, `RUNIC_BUILD_SANDBOX=OFF` and presentation off. The standalone build therefore configures the helpers (and, from CORE-1, `Runic::Core`) and never Flecs, GLM, Jolt or Godot (03 § Platform modules (RunicDocs › Repositories, build targets and processes › Platform modules)) |
| Catalog | [`cmake/RunicPlatformCatalog.cmake`](RunicPlatformCatalog.cmake): Contracts, Transport and ServerBindings with the Engine interface targets each may link. Written in this contract for review |
| Modules | `RUNIC_MODULE_NAMESPACE RunicPlatform`; each C++ module is created by its first package (PCT-1, PTR-1, PBND-1) with `runic_add_module`, under `cpp/<Module>/` (modules/README.md (the READMEs of `cpp/`, `proto/`, `go/` and `infra/`)) |
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
| `docs` | The Engine's `DocsCheck` with this repository's rules (a code change under `cpp/<Module>/` needs `cpp/<Module>/ARCHITECTURE.md`; under `go/<area>/`, `go/<area>/ARCHITECTURE.md`) | Yes (pull requests only) |
| `go` | `actions/setup-go` with `go-version-file: go.mod`; `go vet ./...`, `go build ./...`, `go test ./...` | Yes |

## Acceptance tests

`tests/build/` (registered when `RUNIC_PLATFORM_BUILD_TESTS` is ON in a top-level build, or run alone with `cmake -S tests/build -B build/build-tests -DRUNIC_ENGINE_DIR=…`). They use the Engine's drivers (`tests/build/RunFixture.cmake`, `RunScript.cmake`) and check scripts from the pinned Engine. Today every one fails.

| Test | Passes when |
| --- | --- |
| `build.platform_standalone` | This repository configures on its own, the Engine helpers run (`RUNIC: link checks passed`), and no Flecs, GLM, Jolt, godot-cpp or Godot build folder exists |
| `build.platform_bootstrap_gtest` | With tests on, the build passes and CTest discovers and passes `PlatformBootstrap.Version` |
| `checks.catalog_sync` | `cmake/RunicPlatformCatalog.cmake` equals the C++ rows of RunicDocs' Platform modules table (skipped without a RunicDocs checkout; CI checks it out) |
| `checks.public_header_scan` | No library type (GameNetworkingSockets, gRPC, NATS, Agones SDK, Prometheus client, Protobuf) appears in any `Public/` header |
| `checks.source_include_scan` | No file includes another module's `Source/` |
| `checks.workflow_pins` | Every Action in `.github/workflows/` is pinned to a full commit SHA (BUILD-1 security requirement) |

Plus the `go` CI job passing on today's Go code: `go vet`, `go build`, `go test` and `govulncheck` (pinned v1.9.0; "No vulnerabilities found" locally).

## Owner actions

- **Repository visibility.** This repository is still private while its docs and license say public (current-state.md). It does not block BUILD-1, but RunicGame's CI needs a token to check it out while it stays private.
- **Go toolchain.** `go.mod` requires Go 1.26.0; CI installs it from `go.mod`. Local machines need it too.

## After merge

After slice 0: move `external/RunicEngine` to an Engine commit that holds slice 0 once it is on `main`.
