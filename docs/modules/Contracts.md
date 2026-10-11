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

Give every Platform and Game process one definition of the messages they exchange off the realtime connection: service APIs, published facts and the connect-ticket format, versioned and generated for C++ and Go. Games add their own messages in their own repository on the same tooling (ARCH § Repositories, build targets and processes — Platform modules).

Contracts never carry per-tick traffic. `Runic::Network` encodes every message on the realtime connection, envelope included: inputs, snapshots, deltas and simulation-link messages (ARCH § Networking: stack, sessions and responsiveness).

## Owns

- Service APIs of the Platform core services and building blocks: accounts and connect tickets, World Coordinator, world directives, instance allocation, chat and party groups, admission, item ledger, currency wallets.
- Fact messages published over NATS (published facts and world directives).
- The connect-ticket format: issued by the accounts service (PCS-1), verified inside the simulation by Transport (PTR-2).
- The generic durable-operation shape the services bridge carries: an operation with a stable operation ID, and an accepted result.
- Plain ID fields on the wire: GlobalEntityId, GlobalPlayerId (CORE-1; issued by PCS-1), SimulationId, TickId, AuthorityEpoch.
- Code generation for C++ and Go, wired into CMake and the Go build, and the rule that generated code is never edited by hand.
- Schema versioning and compatibility rules.

## Does not own

| Responsibility | Owner |
| --- | --- |
| Every realtime message, envelope included: inputs, bit-packed and quantized snapshots, deltas, ghost deltas, transfer messages | Engine `Runic::Network` |
| The Engine's plain ID and time types themselves | Engine `Runic::Core` (CORE-1) |
| Game messages and game service APIs | RunicGame (on the same tooling) |
| Sending, receiving, retrying | Transport (realtime bytes), ServerBindings and GoSDK (services) |
| Any game rule, value or name | RunicGame |

## Depends on / never depends on

| May depend on | Never depends on |
| --- | --- |
| `protoc`, the Protobuf runtime and the gRPC generator plugins (versions pinned in PCT-1) | Any other Platform module |
| — | RunicEngine code or headers |
| — | RunicGame messages, names or content |

Transport, ServerBindings, GoSDK and, through the SDK, CoreServices and BuildingBlocks depend on Contracts.

## Rules

- Do: put stable, global IDs in schemas. Local Flecs entity IDs never appear in a schema; use GlobalEntityId, GlobalPlayerId and the other plain ID types.
- Do: give every durable request an operation ID so retries are safe.
- Do: keep every message generic. Tests and examples use neutral names (`engine:test_ability`, `game:<something>` only as a format example).
- Do: version every schema; changes stay backward compatible within a major version.
- Never: edit generated code; never commit it into the handwritten source folders.
- Never: define a game message here. Games add theirs in their own repository.
- Never: define a realtime or per-tick message (input, snapshot, delta, simulation-link message or their envelope); `Runic::Network` encodes those.

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
| Requests that need an answer | gRPC, through ServerBindings (PBND-1) and GoSDK (PSDK-1) |
| Published facts and world directives, no answer | NATS, through ServerBindings (PBND-4) and GoSDK (PSDK-3) |
| Connect ticket | Issued over gRPC by PCS-1; presented by the client first on the realtime connection and verified by Transport (PTR-2) |

## Work packages

Copied from ARCH § Modules, work packages and the implementation contract (Platform), revision 369.

| ID | Package | Done when | Needs | Slice |
| --- | --- | --- | --- | --- |
| PCT-1 | Protobuf service APIs, fact messages and the connect-ticket format; C++ and Go code generation | Both languages round-trip the same message | BUILD-1 | 12 |

Later packages (Transport, ServerBindings, GoSDK, CoreServices, BuildingBlocks) add the service APIs they need inside this module's folder as part of their own contract sessions, or as a follow-up Contracts package; each such change is reviewed as a Contracts change.

## Acceptance tests

| Package | Test | Passes when |
| --- | --- | --- |
| PCT-1 | Cross-language round trip | A message encoded in C++ decodes in Go to the same values, and the reverse |
| PCT-1 | Build integration | The CMake build generates the C++ code and `go build ./...` builds the Go code, with no hand-edited generated file |
| PCT-1 | ID check | No schema field holds a local entity ID; IDs use the plain ID messages |
| PCT-1 | Scope review | No schema defines a realtime or per-tick message |
| PCT-1 | Neutrality review | No game name, rule or value appears in a schema or test |

## Contract-session items

- OQ-9 (still open): the canonical Go module path, `runic.local/platform` (placeholder) or `github.com/PedroVicente98/RunicPlatform`. Generated Go import paths depend on it. See [../system/11-open-questions.md](../system/11-open-questions.md).
- `.gitignore` excludes `go/generated/`, but Go consumers that fetch the module cannot run `protoc`. PCT-1 decides whether generated Go code is committed (and where) or produced by a documented step.
- How the Protobuf and gRPC toolchains are acquired for CMake (system package or fetched) is decided in PCT-1, within the dependency rules of BUILD-1.
