# RunicPlatform current state

This file records what exists in the repository today, how far it is from Technical Architecture v3, and what comes next.

Updated 2026-10-13, on branch `docs/v3-regeneration`, when the docs were brought up to ARCH (Technical Architecture v3) revision 502 (worlds and world transitions, simulation links by locality, placement by load and traffic, directives with a duration). Before that they reached revision 369 on 2026-10-11 (with an intermediate update to revision 306 the same day). They were first regenerated from revision 263 on 2026-10-09. Update this file in the same pull request as any code that changes it.

## Owner action required: repository visibility

> **The GitHub repository `PedroVicente98/RunicPlatform` is currently private, while every doc and `README.md` call it public and the `LICENSE` is MIT.** The owner must choose one:
>
> 1. make the repository public, or
> 2. change the docs and the README to describe it as private (and decide whether the MIT `LICENSE` stays).
>
> This change does not alter the license or the visibility. Until the owner decides, the public-repository rule still applies: no RunicGame rules, names, numbers or content in this repository, tests and docs included.

## Summary

Bootstrap only. The repository proves that a C++ library and a Go module build. None of the seven v3 modules exists yet; no work package is merged. On this branch the docs were regenerated from ARCH v3 and updated to revision 306, and RunicEngine was pinned as a submodule for standalone C++ builds.

## What exists

| Item | Details |
| --- | --- |
| C++ build | `CMakeLists.txt`: `project(RunicPlatform VERSION 0.1.0)`, CMake 3.24+, static library `runic_platform` with alias `Runic::Platform`, include root `cpp/include`, C++20, no extensions. Option `RUNIC_PLATFORM_BUILD_TESTS` (default: top-level build only). |
| C++ code | `cpp/include/Runic/Platform/Version.hpp` and `cpp/Core/Version.cpp`: a disposable `Runic::Platform::Version()` returning `"0.1.0"`. |
| C++ test | `tests/Bootstrap.cpp`, registered as CTest `runic_platform.bootstrap`; checks the version string. Plain executable, no test framework. |
| Presets | `CMakePresets.json`: `debug` configure, build and test presets (Ninja, `build/debug`). |
| Go | `go.mod`: placeholder module `runic.local/platform`, `go 1.26.0`. `go/platform/doc.go`: a documentation-only package `platform`. No tests, no dependencies. |
| Schemas | `proto/README.md` placeholder; no `.proto` file and no code generation. `.gitignore` already reserves `proto/generated/`, `cpp/generated/` and `go/generated/`. |
| Engine pin (added in this change) | `.gitmodules` entry `external/RunicEngine` → `https://github.com/PedroVicente98/RunicEngine.git`, gitlink at RunicEngine `fb84529a58e827a10ee2bf1517e6005429db814a` (RunicEngine `main` on 2026-10-09). The submodule is not checked out by default; run `git submodule update --init external/RunicEngine` to fetch it. |
| `RUNIC_ENGINE_DIR` (added in this change) | CMake cache path, defined only when no Engine target exists yet (so a RunicGame superproject is never affected). Default: `external/RunicEngine` when it has a `CMakeLists.txt`, otherwise `../RunicEngine`. Nothing uses it yet; the Engine is not added to the build. |
| Docs | `docs/` regenerated from ARCH v3 on this branch and updated to revision 502: [architecture.md](architecture.md), [modules/README.md](modules/README.md) and seven module contracts. `docs/system/` is shared with the other two repositories; this repository's copy is replaced by the coordinator and is not edited here. |
| License | MIT (`LICENSE`). See the owner action above. |

## Gaps against v3

| Area | Today | v3 target | Reference |
| --- | --- | --- | --- |
| Modules | 0 of 7 | Transport, Contracts, ServerBindings, GoSDK, CoreServices, BuildingBlocks, Infrastructure | [modules/README.md](modules/README.md) |
| C++ targets and namespaces | One bootstrap target `Runic::Platform`, namespace `Runic::Platform` | One target per module, `RunicPlatform::<Module>`, namespace matching the module | ARCH § Modules, work packages and the implementation contract (module contract) |
| Module layout | `cpp/Core/`, `cpp/include/` | `cpp/<Module>/{Public,Source,Tests}` + `ARCHITECTURE.md` + `CMakeLists.txt` via `runic_add_module` | [modules/README.md](modules/README.md#directory-layout) |
| Build skeleton | No module helper, no CI, no headless or forbidden-dependency check, no CPU baseline | BUILD-1: `runic_add_module`, presets, CI, one test framework for all three repositories, automated checks, x86-64-v3 (AVX2, FMA) | ARCH § Modules, work packages and the implementation contract (Engine: foundation, BUILD-1) |
| Test framework | Plain executable returning 0 or 1 | The C++ framework chosen in BUILD-1 (the BUILD-1 session asks the owner); Go uses `testing` | OQ-7 in [system/11-open-questions.md](system/11-open-questions.md) |
| Engine dependency | Pinned (`external/RunicEngine`) but unused | Transport links `Runic::NetworkTransport` from PTR-1; ServerBindings links `Runic::Core`, `Runic::Application` and `Runic::SimulationPort` from PBND-1 | [architecture.md](architecture.md#repository-wiring) |
| Engine interface targets | The pinned Engine commit `fb84529` defines `Runic::Core` (include root only), `Runic::Runtime` and `Runic::Presentation`. Configuring it always fetches Flecs, glm and Jolt (`runic_engine_dependencies()`), so a standalone Platform build that added it today would configure Flecs and Jolt | Header-only `Runic::NetworkTransport` (NET-1, slice 12) and `Runic::SimulationPort` (SIM-5, slice 27) with Core types only, and an Engine configuration that builds only Core, Application and those two targets for the Platform. This is Engine work (BUILD-1, NET-1, SIM-5); if those contracts do not provide such a configuration, PTR-1 or PBND-1 reports it to the Engine instead of working around it | ARCH § Modules, work packages and the implementation contract (Platform) |
| Jolt and CPU baseline | The pinned Engine fetches Jolt 5.2.0 with its SIMD paths off; the Platform links no Jolt | Jolt 5.6.0 in double precision with its AVX2 path, on an x86-64-v3 baseline, delivered by Engine BUILD-1 and PHYS-1. The Platform's part of BUILD-1 sets the x86-64-v3 baseline for its own C++ and still never links Jolt | ARCH § Decisions log (Jolt version, CPU baseline) |
| Contracts | `proto/` placeholder | Protobuf service APIs, published facts and the connect-ticket format with C++ and Go generation (PCT-1); never per-tick traffic | [modules/Contracts.md](modules/Contracts.md) |
| Go module path | Placeholder `runic.local/platform` | Canonical path still open | OQ-9 in [system/11-open-questions.md](system/11-open-questions.md) |
| Go toolchain | `go.mod` requires Go 1.26.0 | Every machine and CI runner needs it | — |
| README | Was titled "RunicPlatform - ADD AGONES" with bootstrap-era scope | Rewritten in this change from v3 | [../README.md](../README.md) |

## Consumers of today's targets

RunicGame links `Runic::Platform` and includes `<Runic/Platform/Version.hpp>`, finding this repository through its `RUNIC_PLATFORM_DIR` (default `../RunicPlatform`). It adds the Engine before the Platform, so the Engine targets already exist when this repository's `CMakeLists.txt` runs and `RUNIC_ENGINE_DIR` is left alone. Renaming or removing `Runic::Platform` needs a coordinated RunicGame change.

## Verification of this change (2026-10-09)

| Check | Result |
| --- | --- |
| `cmake -S . -B build/check -G Ninja && cmake --build build/check && ctest --test-dir build/check --output-on-failure` | Pass (CMake 3.28, GCC 13.3): library and smoke test build; `runic_platform.bootstrap` passes. With the submodule not checked out, `RUNIC_ENGINE_DIR` resolves to `../RunicEngine`. |
| `RUNIC_ENGINE_DIR` default and guard | Checked in scratch builds: `external/RunicEngine` is chosen when it has a `CMakeLists.txt`; `-DRUNIC_ENGINE_DIR=<path>` wins; a superproject that defines `Runic::Runtime` first keeps its own cache value and the block prints nothing. |
| `go build ./... && go test ./...` | Not run as declared: the machine has Go 1.24.7, `go.mod` requires 1.26.0 and the toolchain download is offline. With a temporary `go 1.24` modfile, `go build`, `go vet` and `go test` pass (no test files). |

## Verification of the revision 369 update (2026-10-11)

| Check | Result |
| --- | --- |
| Package rows in `docs/modules/*.md` against ARCH revision 369 | Every PCT, PTR, PSDK, PBND, PCS, PBB and PINF row matches ARCH word for word (PBND-4 and PCS-6 added at revision 306; PBB-3 added and PBB-2 moved to slice 33a at revision 369) |
| Relative links in `docs/` outside `docs/system/` | No broken file or anchor link |
| Public-repository rule (search for game names, statuses, places, numbers and monetization terms outside `docs/system/`) | No hit |
| Code and build files | Unchanged in this update |

## Next steps

Work packages are taken in roadmap order; each one is a single session and pull request inside one module, contract first.

| Order | Slice | Packages | Needs before starting |
| --- | --- | --- | --- |
| 0 | 0. Build skeleton | BUILD-1 (all three repositories; this repository's part: module helper, presets, CI, test framework, checks, CPU baseline, CI use of the Engine pin) | — |
| 1 | 12. Transport | PCT-1 (Contracts) | BUILD-1 |
| 2 | 12. Transport | PTR-1 (Transport) | NET-1 (Engine), PCT-1 |
| 3 | 12. Transport | PTR-2 (Transport) | PTR-1 |
| 4 | 26. Service foundation | PINF-1 (Infrastructure) | — |
| 5 | 26. Service foundation | PSDK-1 (GoSDK) | PCT-1 |
| 6 | 26. Service foundation | PSDK-2 (GoSDK) | PSDK-1 |

PCT-1 can run alongside the Engine's NET-1, and PINF-1 can start at any time. Before PCT-1, the owner should settle OQ-9 (canonical Go module path), because generated Go import paths depend on it. PTR-1 also needs the Engine pin moved to a commit that has `Runic::NetworkTransport` (NET-1); moving the pin is its own reviewed change.

After slice 26, the Platform packages follow the roadmap: PCS-1 and PBND-1 (slice 27; PBND-1 needs PCT-1, APP-1 and SIM-5), PBB-1 (28), PSDK-3 and PBND-4 (30), PCS-2 and PTR-3 (36), PBND-2, PBND-3 and PINF-2 (39), PBB-2 (33a), PCS-3 (43), then PTR-4, PCS-4, PCS-5, PCS-6, PCS-7 and PBB-3 (44+).
