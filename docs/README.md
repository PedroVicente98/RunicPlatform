# RunicPlatform documentation

This file is the entry point to the RunicPlatform docs: what to read first, and what each file and folder holds.

RunicPlatform is the public (MIT) networking, services and infrastructure repository of a three-repository MMORPG project. It supplies mechanisms, never game policy: the GameNetworkingSockets transport behind the Engine transport interface, Protobuf contracts, C++ server bindings, a Go SDK, core services, building blocks and infrastructure.

## Source and authority

| Item | Value |
| --- | --- |
| Architecture source | ARCH: "RunicEngine — Technical Architecture v3" (revision 369, exported 2026-10-11) |
| Rule | These docs are generated from ARCH. When a doc and ARCH disagree, ARCH wins; report the difference instead of choosing silently. |
| Earlier docs | The v0 docs (built from "Appendix J") were replaced on 2026-10-09; do not use v0 module names (Realtime, ServiceRuntime, Persistence, Identity, WorldControl, Orchestration, Observability, NetworkAdapter). |

## Start here

1. [system/01-architecture-overview.md](system/01-architecture-overview.md) — the three repositories, ownership and principles.
2. [system/02-module-contract.md](system/02-module-contract.md) and [system/03-dependency-rules.md](system/03-dependency-rules.md) — module shape and what may depend on what.
3. [architecture.md](architecture.md) — how RunicPlatform is organized and connects to the Engine and the Game.
4. [current-state.md](current-state.md) — what exists today, the gaps, owner actions and next steps.
5. [modules/README.md](modules/README.md) — the seven Platform modules, their packages and slices.
6. [system/12-work-packages.md](system/12-work-packages.md) and [system/10-ai-development-workflow.md](system/10-ai-development-workflow.md) — how one work package is done.
7. [system/05-distributed-simulation.md](system/05-distributed-simulation.md) and [system/07-service-backed-systems.md](system/07-service-backed-systems.md) — the two areas the Platform serves most.

Open questions are in [system/11-open-questions.md](system/11-open-questions.md); terms are in [system/glossary.md](system/glossary.md).

## Layout of this folder

| Path | Content | Scope |
| --- | --- | --- |
| `system/` | Cross-repository architecture, roadmap, work packages, open questions | Mirrored in RunicEngine and RunicGame; edit all three copies together |
| `architecture.md` | RunicPlatform structure, dependency direction, paths, server layers, tickets, monitoring, Go services, repository wiring | This repository |
| `current-state.md` | What exists, gaps against v3, owner actions, next packages | This repository |
| `modules/` | One contract per Platform module (7) and the catalog | This repository |

## Rules for every session

- Do: read the files above before changing anything, and work on one package in one module.
- Do: update the module contract, the catalog status and `current-state.md` in the same pull request as the code.
- Never: put RunicGame rules, names, numbers or content into this repository; it is public.
- Never: edit `system/` in one repository only.
- Never: resolve an open question silently; ask the owner.
