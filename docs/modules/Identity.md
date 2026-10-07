# Identity

> **Contract seed.** When the `Identity/` module is created, copy this file to
> `Identity/ARCHITECTURE.md`; from then on that file is authoritative.
> Purpose, Owns, Does not own, Allowed dependencies, and Primary consumers come
> from Appendix J §J.5.7. Other sections are derived and are proposals until
> confirmed.

| Field | Value |
| --- | --- |
| Directory | `Identity/` |
| Implementation | Go service + C++ validation helpers for simulations/clients (proposal, [OQ-9](../system/11-open-questions.md#oq-9)) |
| Roadmap phase | 4 — first multiplayer |
| Status | Not started |

## Purpose

Reusable authentication, session, and identity primitives and validation
infrastructure.

## Owns

- Account/session tokens.
- Service identity.
- `GlobalPlayerId` semantics.
- Validation and signing helpers.
- Auth context propagation.

## Does not own

RunicGame character progression or game-specific permissions.

## Allowed dependencies

- Contracts.

## Forbidden dependencies

RunicGame; Persistence policy beyond what token/session storage needs (decide
with the owner); Realtime/ServiceRuntime internals (they depend on Identity).

## Primary consumers

Realtime, ServiceRuntime, WorldControl (signed directives), Game services.

## Integration points (derived)

- Realtime validates session tokens on connect and verifies signed
  connection/transfer directives. [J.8.7]
- ServiceRuntime propagates player and service identity in request context.
- Game CharacterService maps `GlobalPlayerId` to characters (Game semantics).

## Acceptance tests (Stage A, derived)

- [ ] Issue and validate a session token; reject expired or tampered tokens.
- [ ] Service-to-service identity for internal calls.
- [ ] Sign and verify a connection directive.
- [ ] C++ validation helper validates the same tokens as the Go service.

## Open questions

- Account system scope (external identity providers, account database) is not
  specified.
