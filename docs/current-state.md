# RunicPlatform — current state

Snapshot taken when the architecture docs were imported (October 2026, commit
`3c1fe0a`). Update this file whenever a module or migration step lands.

## Summary

**Phase 0 (bootstrap) only.** The repository proves that a C++ library and a Go
module build. No catalog module exists. The repository was renamed from
RunicFabric, but the code still uses the old name.

## What exists

| Item | Details |
| --- | --- |
| C++ build | `CMakeLists.txt`: `project(RunicFabric VERSION 0.1.0)`, static library `runic_fabric` with alias `Runic::Fabric`, include root `cpp/include`, C++20. Option `RUNIC_FABRIC_BUILD_TESTS` (default = top-level). |
| C++ code | `cpp/include/Runic/Fabric/Version.hpp` + `cpp/Core/Version.cpp`: disposable `Runic::Fabric::Version()` returning `"0.1.0"`. |
| C++ test | `tests/Bootstrap.cpp` → CTest `runic_fabric.bootstrap` (checks the version string). |
| Presets | `debug` (Ninja) configure/build/test presets. |
| Go | `go.mod`: module `runic.local/fabric`, `go 1.26.0`. `go/fabric/doc.go`: documentation-only package. |
| Schemas | `proto/README.md` placeholder; Protobuf/gRPC deferred. `.gitignore` already reserves `proto/generated/`, `cpp/generated/`, `go/generated/`. |
| README | Title "RunicPlatform - ADD AGONES" (Agones is now covered by the [Orchestration](modules/Orchestration.md) module). States that NATS/PostgreSQL/Redis/deployment are deferred and Kubernetes is not required (still true until phase 16). |
| License | MIT. |

## Gaps against the target architecture

| Area | Today | Target | Reference |
| --- | --- | --- | --- |
| Name | `RunicFabric`, `Runic::Fabric`, `runic.local/fabric` | RunicPlatform naming | [OQ-13](system/11-open-questions.md#oq-13) |
| Layout | `cpp/`, `go/`, `proto/` by language | One folder per module (Contracts, Realtime, …) | [J.2.2], [OQ-9](system/11-open-questions.md#oq-9) |
| Modules | 0 of 8 | See [modules/README.md](modules/README.md) | [J.5] |
| Engine seam | README: "Fabric has no dependency on either repository" | Realtime integrates Engine NetworkAdapter; direction undecided | [OQ-1](system/11-open-questions.md#oq-1) |
| Scope wording | README lists "generic infrastructure" incl. services | Domain services are RunicGame code; Platform offers runtime/persistence primitives | [J.1.3] |

## Consumers that depend on today's targets

RunicGame links `Runic::Fabric` and includes `<Runic/Fabric/Version.hpp>`.
Renaming the target or namespace requires a coordinated RunicGame change.

## Suggested next steps (proposal — confirm with the owner)

1. Decide [OQ-9](system/11-open-questions.md#oq-9) (language split, layout,
   naming) and [OQ-13](system/11-open-questions.md#oq-13) (rename), then apply
   the rename across RunicPlatform and RunicGame in one change.
2. Nothing else in Platform is needed before Engine phases 1–3; the next
   Platform work is **phase 4** (Contracts, Realtime, Identity), after
   [OQ-1](system/11-open-questions.md#oq-1) is decided.
3. Update `README.md` to point to `docs/` and drop the "ADD AGONES" title note
   once Orchestration is tracked here.
