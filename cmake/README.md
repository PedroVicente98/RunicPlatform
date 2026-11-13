# cmake/ — RunicPlatform's build (its part of BUILD-1 and BUILD-2)

This file is RunicPlatform's part of the BUILD-1 and BUILD-2 contracts. The canonical contract — the CMake helpers, the checks, the decisions and the shared acceptance tests — is [RunicEngine cmake/README.md](https://github.com/PedroVicente98/RunicEngine/blob/main/cmake/README.md); approve both together.

| Field | Value |
| --- | --- |
| Package | BUILD-1 (slice 0), Stage A |
| Needs | RunicEngine's BUILD-1 merged first (this repository uses its helpers through the Engine pin) |
| Status | **Done** in slice 0 with BUILD-2, both merged into `main` by the slice 0 check; the Engine pin (`external/RunicEngine`) is at `2013e9b` (the Engine's BUILD-2 commit) |

## What BUILD-1 delivers here

| Item | Rule |
| --- | --- |
| Engine pin | `external/RunicEngine` pins an Engine commit on `main` that holds every package this repository needs. `RUNIC_ENGINE_DIR` keeps today's behavior (submodule when populated, else `../RunicEngine`; a superproject that already added the Engine wins) |
| Engine in the build | The Platform now adds the Engine with `add_subdirectory`, with `RUNIC_ENGINE_BUNDLES=OFF`, `RUNIC_ENGINE_BUILD_TESTS=OFF`, `RUNIC_ENGINE_BUILD_TOOLS=OFF`, `RUNIC_BUILD_SANDBOX=OFF` and presentation off. The standalone build therefore configures the helpers and never Flecs, GLM, Jolt or Godot (RunicDocs › Repositories, build targets and processes › Platform modules). Since BUILD-2 it configures only the Engine modules listed in `RUNIC_ENGINE_MODULES` (none yet) and the third parties they link (GLM, once Core is listed) |
| Catalog | [`cmake/RunicPlatformCatalog.cmake`](RunicPlatformCatalog.cmake): Contracts, Transport and ServerBindings with the Engine interface targets each may link |
| Modules | `RUNIC_MODULE_NAMESPACE RunicPlatform`; each C++ module is created by its first package (PCT-1, PTR-1, PBND-1) with `runic_add_module`, under `cpp/<Module>/` (Contracts: `proto/`; the folder map is in the READMEs of `cpp/`, `proto/`, `go/` and `infra/`), and joins the build through `runic_add_catalog_modules` (BUILD-2) |
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

`tests/build/` (registered when `RUNIC_PLATFORM_BUILD_TESTS` is ON in a top-level build, or run alone with `cmake -S tests/build -B build/build-tests -DRUNIC_ENGINE_DIR=…`). They use the Engine's drivers (`tests/build/RunFixture.cmake`, `RunScript.cmake`) and check scripts from the pinned Engine. All pass locally (7 of 7 with the `debug-siblings` preset).

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

- **Repository visibility.** This repository is still private while its docs and license say public. It does not block BUILD-1, but RunicGame's CI needs a token to check it out while it stays private.
- **Go toolchain.** `go.mod` requires Go 1.26.0; CI installs it from `go.mod`. Local machines need it too.

## What BUILD-2 changes here

The canonical part is the BUILD-2 section of [RunicEngine cmake/README.md](https://github.com/PedroVicente98/RunicEngine/blob/main/cmake/README.md).

| Item | Rule |
| --- | --- |
| Engine modules | The standalone build sets `RUNIC_ENGINE_MODULES` empty: no Engine module is configured, so the build stays helpers-only (`build.platform_standalone`). The first Platform package that links `Runic::Core`, `Runic::Application`, `Runic::NetworkTransport` or `Runic::SimulationPort` names it there (with what its row allows), and a third party it needs, such as GLM for Core, is then fetched by need; that package updates the test's `ABSENT` list in the same change |
| Platform modules | `runic_add_catalog_modules(ROOT cpp LAYOUT NAME FOLDERS Contracts=proto)` in `CMakeLists.txt`: Transport and ServerBindings join from `cpp/<Module>/CMakeLists.txt`, Contracts from `proto/CMakeLists.txt`, when their first packages add those files |
| Header paths | Every Platform module's `Public/` joins the unique-header-path check; in RunicGame's builds it is compared with the Engine's and the Game's |

## Submodule pin

`external/RunicEngine` is at `2013e9b`, the Engine's BUILD-2 commit. A pin moves in its own commit. During a slice,
this repository's slice branch may pin a commit of the Engine's slice branch; the slice check merges the branches into
`main` in Needs order (RunicEngine, RunicPlatform, RunicGame), by fast-forward or a merge commit, never squashed or
rebased, so the pinned commit stays on the Engine's `main` (RunicGame pins this repository's commit in turn).
