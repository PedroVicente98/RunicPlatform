---
# obsidian-graph: generated tags and aliases
tags:
  - repo/platform
  - source/arch
  - type/module
  - lang/protobuf
  - slice/12
aliases:
  - "RunicPlatform::Contracts"
  - "Platform Contracts"
---

# Contracts

This file is the contract of the Platform Contracts module: the Protobuf service APIs, published facts and connect-ticket format shared by C++ and Go, generated for both languages.

| Field | Value |
| --- | --- |
| Language | Protobuf schemas; generated C++ and Go |
| Directory | `proto/` (schema sources); generated code in the git-ignored `cpp/generated/` and `go/generated/` (already reserved in `.gitignore`) |
| CMake target or Go package | `RunicPlatform::Contracts` (generated C++); Go package under `<module path>/go/generated/` (module path is the placeholder `runic.local/platform`, see Contract-session items) |
| Depends on | Nothing inside the Platform; the Protobuf compiler and runtime, and gRPC code generation for service APIs |
| Status | Not started (`proto/README.md` placeholder only) |

When PCT-1 starts, this file's content moves into `proto/ARCHITECTURE.md` with the section list from [../system/02-module-contract.md](../system/02-module-contract.md), and this file then links to it.

## Purpose

Give every Platform and Game process one definition of the messages they exchange off the realtime connection: service APIs, published facts and the connect-ticket format, versioned and generated for C++ and Go. Games add their own messages in their own repository on the same tooling (ARCH[^arch] § Repositories, build targets and processes — Platform modules).

Contracts never carry per-tick traffic. `Runic::Network`[^engine-network] encodes every message on the realtime connection, envelope included: inputs, snapshots, deltas and simulation-link messages (ARCH § Networking: stack, sessions and responsiveness).

## Owns

- Service APIs of the Platform core services[^platform-coreservices] and building blocks[^platform-buildingblocks]: accounts and connect tickets, World Coordinator, world directives, instance allocation, chat and party groups, admission, item ledger, currency wallets.
- Fact messages published over NATS (published facts and world directives).
- The connect-ticket format: issued by the accounts service (PCS-1), verified inside the simulation by Transport[^platform-transport] (PTR-2).
- The generic durable-operation shape the services bridge[^platform-serverbindings] carries: an operation with a stable operation ID, and an accepted result.
- Plain ID fields on the wire: GlobalEntityId, GlobalPlayerId (CORE-1[^engine-core]; issued by PCS-1), SimulationId, TickId, AuthorityEpoch.
- Code generation for C++ and Go, wired into CMake and the Go build, and the rule that generated code is never edited by hand.
- Schema versioning and compatibility rules.

## Does not own

| Responsibility | Owner |
| --- | --- |
| Every realtime message, envelope included: inputs, bit-packed and quantized snapshots, deltas, ghost deltas, transfer messages | Engine `Runic::Network`[^engine-network] |
| The Engine's plain ID and time types themselves | Engine `Runic::Core`[^engine-core] (CORE-1) |
| Game messages and game service APIs | RunicGame (on the same tooling) |
| Sending, receiving, retrying | Transport[^platform-transport] (realtime bytes), ServerBindings[^platform-serverbindings] and GoSDK[^platform-gosdk] (services) |
| Any game rule, value or name | RunicGame |

## Depends on / never depends on

| May depend on | Never depends on |
| --- | --- |
| `protoc`, the Protobuf runtime and the gRPC generator plugins (versions pinned in PCT-1) | Any other Platform module |
| — | RunicEngine code or headers |
| — | RunicGame messages, names or content |

Transport[^platform-transport], ServerBindings[^platform-serverbindings], GoSDK[^platform-gosdk] and, through the SDK, CoreServices[^platform-coreservices] and BuildingBlocks[^platform-buildingblocks] depend on Contracts.

## Rules

- Do: put stable, global IDs in schemas. Local Flecs entity IDs never appear in a schema; use GlobalEntityId, GlobalPlayerId and the other plain ID types.
- Do: give every durable request an operation ID so retries are safe.
- Do: keep every message generic. Tests and examples use neutral names (`engine:test_ability`, `game:<something>` only as a format example).
- Do: version every schema; changes stay backward compatible within a major version.
- Never: edit generated code; never commit it into the handwritten source folders.
- Never: define a game message here. Games add theirs in their own repository.
- Never: define a realtime or per-tick message (input, snapshot, delta, simulation-link message or their envelope); `Runic::Network`[^engine-network] encodes those.

## Interfaces it implements or exposes (sketch)

Illustrative only; PCT-1's contract session fixes the real files and names.

```text
proto/
├── runic/platform/operations/v1/operation.proto  # durable operation, operation ID, result status
├── runic/platform/ids/v1/ids.proto               # GlobalEntityId, GlobalPlayerId, SimulationId, TickId, AuthorityEpoch
├── runic/platform/tickets/v1/connect_ticket.proto # connect-ticket format (PCS-1 issues, PTR-2 verifies)
├── runic/platform/accounts/v1/accounts.proto     # login, entitlements (PCS-1)
├── runic/platform/coordinator/v1/coordinator.proto
├── runic/platform/directives/v1/directives.proto
├── runic/platform/ledger/v1/ledger.proto
├── runic/platform/wallets/v1/wallets.proto
└── ARCHITECTURE.md
```

```protobuf
// Illustrative, not a frozen schema.
message OperationId { uint64 simulation_id = 1; uint64 sequence = 2; }

message DurableOperation {
  OperationId id = 1;
  string kind = 2;                      // namespaced, e.g. "engine:test_operation"
  google.protobuf.Any payload = 3;      // the game defines its payloads in its own repository
}
```

| Message family | Carried by |
| --- | --- |
| Requests that need an answer | gRPC, through ServerBindings[^platform-serverbindings] (PBND-1) and GoSDK[^platform-gosdk] (PSDK-1) |
| Published facts and world directives[^platform-coreservices], no answer | NATS, through ServerBindings (PBND-4) and GoSDK (PSDK-3) |
| Connect ticket | Issued over gRPC by PCS-1; presented by the client first on the realtime connection and verified by Transport[^platform-transport] (PTR-2) |

## Work packages

Copied from ARCH[^arch] § Modules, work packages and the implementation contract (Platform), revision 502.

| ID | Package | Done when | Needs | Slice |
| --- | --- | --- | --- | --- |
| PCT-1 | Protobuf service APIs, fact messages and the connect-ticket format; C++ and Go code generation | Both languages round-trip the same message | BUILD-1[^doc-build-build-1] | 12 |

Later packages (Transport[^platform-transport], ServerBindings[^platform-serverbindings], GoSDK[^platform-gosdk], CoreServices[^platform-coreservices], BuildingBlocks[^platform-buildingblocks]) add the service APIs they need inside this module's folder as part of their own contract sessions, or as a follow-up Contracts package; each such change is reviewed as a Contracts change.

## Acceptance tests

| Package | Test | Passes when |
| --- | --- | --- |
| PCT-1 | Cross-language round trip | A message encoded in C++ decodes in Go to the same values, and the reverse |
| PCT-1 | Build integration | The CMake build generates the C++ code and `go build ./...` builds the Go code, with no hand-edited generated file |
| PCT-1 | ID check | No schema field holds a local entity ID; IDs use the plain ID messages |
| PCT-1 | Scope review | No schema defines a realtime or per-tick message |
| PCT-1 | Neutrality review | No game name, rule or value appears in a schema or test |

## Contract-session items

- OQ-9[^oq-9] (still open): the canonical Go module path, `runic.local/platform` (placeholder) or `github.com/PedroVicente98/RunicPlatform`. Generated Go import paths depend on it. See [../system/11-open-questions.md](../system/11-open-questions.md).
- `.gitignore` excludes `go/generated/`, but Go consumers that fetch the module cannot run `protoc`. PCT-1 decides whether generated Go code is committed (and where) or produced by a documented step.
- How the Protobuf and gRPC toolchains are acquired for CMake (system package or fetched) is decided in PCT-1, within the dependency rules of BUILD-1[^doc-build-build-1].

<!-- obsidian-graph:start -->

---

## Connections

*Generated for the Obsidian graph. The numbered markers in the text jump to the footnotes below, which link the notes they refer to.*

- **Depended on by:** [[../modules/Transport|Transport]] · [[../modules/ServerBindings|ServerBindings]] · [[../modules/GoSDK|GoSDK]] · [[../modules/CoreServices|CoreServices]] · [[../modules/BuildingBlocks|BuildingBlocks]]
- **Its packages need:** [[../build/BUILD-1|Platform BUILD-1 contract]]
- **See also:** [[../modules/README|Platform module catalog]] · [[../../../RunicEngine/docs/system/03-dependency-rules|03 — Dependency rules]] · [[../../../RunicEngine/docs/system/12-work-packages|12 — Work packages]] · [[../current-state|Platform current state]]

[^arch]: #source/arch — ARCH, "RunicEngine — Technical Architecture" (v4, in the RunicDocs vault): the architecture source of truth
[^engine-network]: [[../../../RunicEngine/docs/modules/Network|Network]] — Engine module · Networking
[^platform-coreservices]: [[../modules/CoreServices|CoreServices]] — Platform module · Go
[^platform-buildingblocks]: [[../modules/BuildingBlocks|BuildingBlocks]] — Platform module · Go
[^platform-transport]: [[../modules/Transport|Transport]] — Platform module · C++
[^platform-serverbindings]: [[../modules/ServerBindings|ServerBindings]] — Platform module · C++
[^engine-core]: [[../../../RunicEngine/docs/modules/Core|Core]] — Engine module · Foundation
[^platform-gosdk]: [[../modules/GoSDK|GoSDK]] — Platform module · Go
[^doc-build-build-1]: [[../build/BUILD-1|Platform BUILD-1 contract]] — RunicPlatform doc
[^oq-9]: [[../system/11-open-questions#OQ-9 — Platform naming: canonical Go module path|OQ-9]] — open question or decision
