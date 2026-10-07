# Contracts

> **Contract seed.** When the `Contracts/` module is created, copy this file to
> `Contracts/ARCHITECTURE.md`; from then on that file is authoritative.
> Purpose, Owns, Does not own, Allowed dependencies, and Primary consumers come
> from Appendix J §J.5.1 and §J.7.2. Other sections are derived and are proposals
> until confirmed.

| Field | Value |
| --- | --- |
| Directory | `Contracts/` |
| Implementation | Schema sources + generated C++ and Go bindings (proposal, [OQ-9](../system/11-open-questions.md#oq-9)) |
| Roadmap phase | 4 — first multiplayer (grows with every phase that adds traffic) |
| Status | Not started (`proto/` placeholder exists; Protobuf deferred) |

## Purpose

Versioned protocol and service schemas shared across processes.

## Owns

- Identity and message IDs.
- Realtime packet schemas.
- Service Protobuf schemas.
- Event schemas (wire form of facts).
- Transfer and control contracts.

## Does not own

Game policy; persistence implementation; transport implementation.
RunicGame-specific payload schemas live in RunicGame and travel through Platform
mechanisms.

## Allowed dependencies

None inside Platform — Contracts is the **foundation** for every Platform module
and for RunicGame service/client bindings. Schema tooling (e.g. protoc) only.

## Forbidden dependencies

Any other Platform module, RunicEngine implementation code, RunicGame.

## Primary consumers

Platform modules, RunicEngine bindings (NetworkAdapter integration), RunicGame
server/client integrations.

## Public surface (conceptual)

```text
Contracts/
├── api_or_pkg/     # schema sources and generated public packages
├── internal/
├── tests/
└── build/deploy metadata as appropriate
```

Message classes the schemas must cover [J.7.2]:

| Class | Examples |
| --- | --- |
| Command / Intent | MoveInput, UseSkill, Interact |
| Event / Fact | EntityKilled, DamageApplied (wire form) |
| State / Replication | Transform, velocity, HP, ghost delta, snapshot delta |
| Request / Reply | ConsumeItem, LoadCharacter, CommitTrade, ValidateSession |
| Transfer / Snapshot | PlayerTransferSnapshot, region bootstrap, recovery snapshot |
| Control | AssignPartition, DrainSimulation, AuthorityCommit, connection-role changes |

The examples above name game-flavored messages to illustrate the classes; only
generic infrastructure messages are defined here.

## Data ownership (derived)

- Schemas carry `GlobalEntityId`/`GlobalPlayerId`, never local Flecs IDs.
- Every schema is versioned; evolution is backward compatible within a major
  version.
- Generated code is never hand-edited and stays in the git-ignored
  `*/generated/` folders.

## Integration points (derived)

Realtime serializes these schemas; ServiceRuntime exposes service schemas over
gRPC/NATS; Engine NetworkAdapter maps simulation data to/from them through the
binding decided in [OQ-1](../system/11-open-questions.md#oq-1).

## Acceptance tests (Stage A, derived)

- [ ] Schemas generate C++ and Go bindings in the build.
- [ ] Round-trip encode/decode tests in both languages, including cross-language.
- [ ] Each message has a stable ID and version.
- [ ] Review check: no game-specific types or rules in Platform schemas.

## Open questions

- Schema technology for realtime packets (Protobuf vs. a custom compact format)
  is not decided; Appendix J names Protobuf for **service** schemas.
- [OQ-1](../system/11-open-questions.md#oq-1), [OQ-2](../system/11-open-questions.md#oq-2).
