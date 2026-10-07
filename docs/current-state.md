# RunicPlatform — current state

Snapshot taken when the architecture docs were imported (October 2026, commit
`3c1fe0a`), updated on 2026-10-07 after the RunicFabric → RunicPlatform rename.
Update this file whenever a module or migration step lands.

## Summary

**Phase 0 (bootstrap) only.** The repository proves that a C++ library and a Go
module build (both verified on 2026-10-07). No catalog module exists. The rename
from RunicFabric is complete ([OQ-13](system/11-open-questions.md#oq-13)).

## What exists

| Item | Details |
| --- | --- |
| C++ build | `CMakeLists.txt`: `project(RunicPlatform VERSION 0.1.0)`, static library `runic_platform` with alias `Runic::Platform`, include root `cpp/include`, C++20. Option `RUNIC_PLATFORM_BUILD_TESTS` (default = top-level). |
| C++ code | `cpp/include/Runic/Platform/Version.hpp` + `cpp/Core/Version.cpp`: disposable `Runic::Platform::Version()` returning `"0.1.0"`. |
| C++ test | `tests/Bootstrap.cpp` → CTest `runic_platform.bootstrap` (checks the version string). |
| Presets | `debug` (Ninja) configure/build/test presets. |
| Go | `go.mod`: placeholder module `runic.local/platform`, `go 1.26.0`. `go/platform/doc.go`: documentation-only package. |
| Schemas | `proto/README.md` placeholder; Protobuf/gRPC deferred. `.gitignore` already reserves `proto/generated/`, `cpp/generated/`, `go/generated/`. |
| README | Title "RunicPlatform - ADD AGONES" (Agones is now covered by the [Orchestration](modules/Orchestration.md) module). States that NATS/PostgreSQL/Redis/deployment are deferred and Kubernetes is not required (still true until phase 16). |
| License | MIT. |

## Gaps against the target architecture

| Area | Today | Target | Reference |
| --- | --- | --- | --- |
| Layout | `cpp/`, `go/`, `proto/` by language | One folder per module (Contracts, Realtime, …) | [J.2.2], [OQ-9](system/11-open-questions.md#oq-9) |
| Modules | 0 of 8 | See [modules/README.md](modules/README.md) | [J.5] |
| Engine seam | README: "Platform has no dependency on either repository" | Realtime integrates Engine NetworkAdapter; direction undecided | [OQ-1](system/11-open-questions.md#oq-1) |
| Scope wording | README lists "generic infrastructure" incl. services | Domain services are RunicGame code; Platform offers runtime/persistence primitives | [J.1.3] |

## Consumers that depend on today's targets

RunicGame links `Runic::Platform` and includes `<Runic/Platform/Version.hpp>`
(through `RUNIC_PLATFORM_DIR`, default `../RunicPlatform`). Renaming the target or
namespace again requires a coordinated RunicGame change.

## Suggested next steps (proposal — confirm with the owner)

1. Decide [OQ-9](system/11-open-questions.md#oq-9) (language split, module
   layout, per-module naming, canonical Go module path).
2. Nothing else in Platform is needed before Engine phases 1–3; the next
   Platform work is **phase 4** (Contracts, Realtime, Identity), after
   [OQ-1](system/11-open-questions.md#oq-1) is decided.
3. Update `README.md` to point to `docs/` and drop the "ADD AGONES" title note
   once Orchestration is tracked here.
