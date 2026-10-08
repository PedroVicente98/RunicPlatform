# Persistence

> **Contract seed.** When the `Persistence/` module is created, copy this file to
> `Persistence/ARCHITECTURE.md`; from then on that file is authoritative.
> Purpose, Owns, Does not own, Allowed dependencies, Primary consumers, and the
> `IdempotencyStore` sketch come from Appendix J §J.5.4 and §J.10.5. Other
> sections are derived and are proposals until confirmed.

| Field | Value |
| --- | --- |
| Directory | `Persistence/` |
| Implementation | Go (proposal, [OQ-9](../system/11-open-questions.md#oq-9)) |
| Roadmap phase | 9 — durable service foundation |
| Status | Not started (database choice deferred; README mentions PostgreSQL/Redis as candidates) |

## Purpose

Reusable durable storage and transaction primitives.

## Owns

- Database pools and adapters.
- Transactions.
- Migrations framework.
- Versioning.
- Optimistic and explicit locking primitives.
- Idempotency store.
- Repository helpers.

## Does not own

Which items may be traded; quest progression rules; auction pricing policy.

## Allowed dependencies

- Observability.

## Forbidden dependencies

RunicGame domain types or rules; Realtime; any simulation code.

## Primary consumers

Private RunicGame services (via their Go code), Platform modules that need
durable state (e.g. Identity, WorldControl directories if persisted).

## Public surface (conceptual)

```go
type IdempotencyStore interface {
    Begin(ctx context.Context, key OperationID) (Decision, error)
    Complete(ctx context.Context, key OperationID, result Result) error
}
```

Quest-shaped stores (`QuestStore`) are discussed in
[OQ-16](../system/11-open-questions.md#oq-16); proposal: defined by the Game
QuestService on top of these primitives.

## Data ownership (derived)

Owns connection pools and the idempotency records. Domain tables/schemas belong
to the Game service that defines them; Persistence provides migrations
machinery, not game schemas.

## Integration points (derived)

Game services open transactions, use locking/versioning, and record idempotency
decisions around every durable mutation (item grants, trades, quest rewards).

## Acceptance tests (Stage A, derived)

- [ ] Transaction commit and rollback.
- [ ] Optimistic version conflict is detected and reported.
- [ ] `Begin` on a completed key returns the stored result; concurrent `Begin`
      on the same key admits exactly one executor.
- [ ] Migrations apply in order and are recorded.
- [ ] Tests run against a local database instance.

## Open questions

- Database engine(s) not chosen.
- [OQ-16](../system/11-open-questions.md#oq-16).
