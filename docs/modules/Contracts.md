# Contracts

This file is the contract of the Platform Contracts module: the Protobuf envelopes and service APIs shared by C++ and Go, generated for both languages.

| Field | Value |
| --- | --- |
| Language | Protobuf schemas; generated C++ and Go |
| Directory | `proto/` (schema sources); generated code in the git-ignored `cpp/generated/` and `go/generated/` (already reserved in `.gitignore`) |
| CMake target or Go package | `RunicPlatform::Contracts` (generated C++); Go package under `<module path>/go/generated/` (module path is the placeholder `runic.local/platform`, see Open items) |
| Depends on | Nothing inside the Platform; the Protobuf compiler and runtime, and gRPC code generation for service APIs |
| Status | Not started (`proto/README.md` placeholder only) |

When PCT-1 starts, this file's content moves into `proto/ARCHITECTURE.md` with the section list from [../system/02-module-contract.md](../system/02-module-contract.md), and this file then links to it.

## Purpose

Give every Platform and Game process one definition of the messages they exchange outside the per-tick replication payloads: envelopes and service APIs, versioned, generated for C++ and Go. Games add their own messages in their own repository on the same tooling (ARCH § Repositories, build targets and processes — Platform modules).

## Owns

- Protobuf envelopes (ARCH § Networking: stack, sessions and responsiveness: "Protobuf defines the envelopes and service messages").
- Service APIs of the Platform core services and building blocks: accounts and connect tickets, World Coordinator, world directives, instance allocation, chat and party groups, item ledger, currency wallets.
- The generic durable-operation shape the services bridge carries: an operation with a stable operation ID, and an accepted result.
- Plain ID fields on the wire: GlobalEntityId, SimulationId, TickId, AuthorityEpoch, and the player and account IDs the services need (for example GlobalPlayerId).
- Code generation for C++ and Go, wired into CMake and the Go build, and the rule that generated code is never edited by hand.
- Schema versioning and compatibility rules.

## Does not own

| Responsibility | Owner |
| --- | --- |
| High-frequency replication payloads (bit-packed, quantized snapshots, deltas, ghost deltas, transfer messages) | Engine `Runic::Network` |
| The Engine's plain ID and time types themselves | Engine `Runic::Core` (CORE-1) |
| Game messages and game service APIs | RunicGame (on the same tooling) |
| Sending, receiving, retrying | Transport (realtime), ServerBindings and GoSDK (services) |
| Any game rule, value or name | RunicGame |

## Depends on / never depends on

| May depend on | Never depends on |
| --- | --- |
| `protoc`, the Protobuf runtime and the gRPC generator plugins (versions pinned in PCT-1) | Any other Platform module |
| — | RunicEngine code or headers |
| — | RunicGame messages, names or content |

Every other Platform module may depend on Contracts.

## Rules

- Do: put stable, global IDs in schemas. Local Flecs entity IDs never appear in a schema; use GlobalEntityId and the other plain ID types.
- Do: give every durable request an operation ID so retries are safe.
- Do: keep every message generic. Tests and examples use neutral names (`engine:test_ability`, `game:<something>` only as a format example).
- Do: version every schema; changes stay backward compatible within a major version.
- Never: edit generated code; never commit it into the handwritten source folders.
- Never: define a game message here. Games add theirs in their own repository.
- Never: move per-tick replication encoding into Protobuf; the Engine owns it.

## Interfaces it implements or exposes (sketch)

Illustrative only; PCT-1's contract session fixes the real files and names.

```text
proto/
├── runic/platform/envelope/v1/envelope.proto     # envelope, operation ID, result status
├── runic/platform/ids/v1/ids.proto               # GlobalEntityId, SimulationId, TickId, AuthorityEpoch, player and account IDs
├── runic/platform/accounts/v1/accounts.proto     # login, entitlements, connect tickets (PCS-1)
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
| Envelopes and session control | Transport (realtime path) |
| Requests that need an answer | gRPC, through ServerBindings and GoSDK |
| Facts and directives with no answer | NATS, through ServerBindings and GoSDK |

## Work packages

Copied from ARCH § Modules, work packages and the implementation contract (Platform).

| ID | Package | Done when | Needs | Slice |
| --- | --- | --- | --- | --- |
| PCT-1 | Protobuf envelopes and service APIs; C++ and Go code generation | Both languages round-trip the same message | BUILD-1 | 12 |

Later packages (Transport, GoSDK, CoreServices, BuildingBlocks) add the service APIs they need inside this module's folder as part of their own contract sessions, or as a follow-up Contracts package; each such change is reviewed as a Contracts change.

## Acceptance tests

| Package | Test | Passes when |
| --- | --- | --- |
| PCT-1 | Cross-language round trip | A message encoded in C++ decodes in Go to the same values, and the reverse |
| PCT-1 | Build integration | The CMake build generates the C++ code and `go build ./...` builds the Go code, with no hand-edited generated file |
| PCT-1 | ID check | No schema field holds a local entity ID; IDs use the plain ID messages |
| PCT-1 | Neutrality review | No game name, rule or value appears in a schema or test |

## Open items

- OQ-9 (still open): the canonical Go module path, `runic.local/platform` (placeholder) or `github.com/PedroVicente98/RunicPlatform`. Generated Go import paths depend on it. See [../system/11-open-questions.md](../system/11-open-questions.md).
- `.gitignore` excludes `go/generated/`, but Go consumers that fetch the module cannot run `protoc`. PCT-1 decides whether generated Go code is committed (and where) or produced by a documented step.
- How the Protobuf and gRPC toolchains are acquired for CMake (system package or fetched) is decided in PCT-1, within the dependency rules of BUILD-1.
- GlobalPlayerId is not defined in ARCH v3, which names only GlobalEntityId, SimulationId, TickId and AuthorityEpoch; PCT-1 proposes the player and account ID types.
