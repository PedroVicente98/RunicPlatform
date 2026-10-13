---
# obsidian-graph: generated tags and aliases
tags:
  - repo/platform
  - source/arch
  - type/index
---

# RunicPlatform documentation

This file is the entry point to the RunicPlatform docs: what to read first, and what each file and folder holds.

RunicPlatform is the public (MIT) networking, services and infrastructure repository of a three-repository MMORPG project. It supplies mechanisms, never game policy: the GameNetworkingSockets transport behind the Engine transport interface, Protobuf contracts, C++ server bindings[^platform-serverbindings], a Go SDK[^platform-gosdk], core services[^platform-coreservices], building blocks[^platform-buildingblocks] and infrastructure.

## Source and authority

| Item | Value |
| --- | --- |
| Architecture source | ARCH[^arch]: "RunicEngine — Technical Architecture v3" (revision 502, exported 2026-10-13) |
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
| `build/` | This repository's part of the build packages: [BUILD-1](build/BUILD-1.md) (build skeleton, in review) | This repository |

## Rules for every session

- Do: read the files above before changing anything, and work on one package in one module.
- Do: update the module contract, the catalog status and `current-state.md` in the same pull request as the code.
- Never: put RunicGame rules, names, numbers or content into this repository; it is public.
- Never: edit `system/` in one repository only.
- Never: resolve an open question silently; ask the owner.

<!-- obsidian-graph:start -->

---

## Connections

*Generated for the Obsidian graph. The numbered markers in the text jump to the footnotes below, which link the notes they refer to.*

- **Start here:** [[../docs/architecture|Platform architecture]] · [[../docs/current-state|Platform current state]] · [[../docs/modules/README|Platform module catalog]] · [[../docs/build/BUILD-1|Platform BUILD-1 contract]] · [[../../RunicEngine/docs/system/01-architecture-overview|01 — Architecture overview]] · [[../../RunicEngine/docs/system/02-module-contract|02 — Module contract]] · [[../../RunicEngine/docs/system/03-dependency-rules|03 — Dependency rules]] · [[../../RunicEngine/docs/system/04-events-and-messages|04 — Events and messages]] · [[../../RunicEngine/docs/system/05-distributed-simulation|05 — Distributed simulation]] · [[../../RunicEngine/docs/system/06-gameplayflow-quests-cutscenes|06 — Gameplayflow quests cutscenes]] · [[../../RunicEngine/docs/system/07-service-backed-systems|07 — Service backed systems]] · [[../../RunicEngine/docs/system/08-implementation-roadmap|08 — Implementation roadmap]] · [[../../RunicEngine/docs/system/09-validation-scenarios|09 — Validation scenarios]] · [[../../RunicEngine/docs/system/10-ai-development-workflow|10 — Ai development workflow]] · [[../../RunicEngine/docs/system/11-open-questions|11 — Open questions]] · [[../../RunicEngine/docs/system/12-work-packages|12 — Work packages]] · [[../../RunicEngine/docs/system/README|System README]] · [[../../RunicEngine/docs/system/glossary|Glossary]]

[^platform-serverbindings]: [[../docs/modules/ServerBindings|ServerBindings]] — Platform module · C++
[^platform-gosdk]: [[../docs/modules/GoSDK|GoSDK]] — Platform module · Go
[^platform-coreservices]: [[../docs/modules/CoreServices|CoreServices]] — Platform module · Go
[^platform-buildingblocks]: [[../docs/modules/BuildingBlocks|BuildingBlocks]] — Platform module · Go
[^arch]: #source/arch — ARCH, "RunicEngine — Technical Architecture v3": the architecture source of truth (a project document, not a note in this vault)
