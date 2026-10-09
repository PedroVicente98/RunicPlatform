# BuildingBlocks

This file is the contract of the Platform building blocks: the item ledger and currency wallets, Go services that provide durable item and currency mechanisms with no game rules.

| Field | Value |
| --- | --- |
| Language | Go |
| Directory | `go/blocks/ledger/` and `go/blocks/wallets/`, with `internal/` for private code and tests beside the code; executables in `go/cmd/<service>/` (proposal) |
| Go package | `<module path>/go/blocks/...`; module path is the placeholder `runic.local/platform` (OQ-9) |
| Depends on | Platform GoSDK; Platform Contracts (service APIs) |
| Status | Not started |

When PBB-1 starts, this file's content moves into `go/blocks/ARCHITECTURE.md` with the section list from [../system/02-module-contract.md](../system/02-module-contract.md), and this file then links to it.

## Purpose

Give games a durable owner for items and currencies whose only promise is correctness: nothing is duplicated or lost, every change is an operation with an ID, and transfers are atomic. What an item is, who may move it and why is decided by the game's own services on top (ARCH § Platform and operations: services).

## Owns

| Block | Owns | Work package |
| --- | --- | --- |
| Item ledger | Item instances, containers, slots, atomic transfers, operation IDs | PBB-1 |
| Currency wallets | Balances and atomic transfers | PBB-2 |

- The ledger's and wallets' tables, gRPC APIs (defined in Contracts) and metrics.
- Concurrency control that keeps concurrent transfers from duplicating or losing anything.
- Deduplication by operation ID through the SDK idempotency store.

## Does not own

| Responsibility | Owner |
| --- | --- |
| Item definitions, stats, stacking, binding, equip and trade limits, loot rules | RunicGame (data and its inventory service) |
| Currencies' meaning, sources, sinks and any economy rule | RunicGame services |
| The runtime item and container mirror inside the simulation | Engine `Runic::Gameplay` (GPL-4) |
| Deciding whether a transfer is allowed | The calling game service; the ledger only checks that the transfer is consistent |
| Transactions and the idempotency store | Platform GoSDK |

## Depends on / never depends on

| May depend on | Never depends on |
| --- | --- |
| Platform GoSDK | RunicEngine (Go services need no Engine code) |
| Platform Contracts | RunicGame code, names, item tables or rules |
| — | Platform CoreServices' tables |
| — | The realtime path: the ledger is reached through services, never on per-tick traffic |

## Rules

- Do: make every change an operation with an ID; a retried operation commits once.
- Do: keep transfers atomic: an item leaves one slot and enters another in one transaction, or nothing changes.
- Do: treat item and container contents as opaque payloads that the game defines.
- Never: add stacking, binding, trade limits, item value or tier rules, or any other game rule.
- Never: let a simulation write the ledger directly; simulations send durable operations through the ServicesBridgeLayer to a game service, which calls the ledger.

## Interfaces it implements or exposes (sketch)

Illustrative only; PBB-1 and PBB-2 fix the APIs in Contracts.

```protobuf
// Illustrative, not a frozen schema.
service ItemLedger {
  rpc CreateContainer(CreateContainerRequest) returns (Container);
  rpc Grant(GrantRequest) returns (LedgerResult);       // op_id, container, slot, opaque item payload
  rpc Transfer(TransferRequest) returns (LedgerResult); // op_id, from(container, slot), to(container, slot)
  rpc Remove(RemoveRequest) returns (LedgerResult);
  rpc Read(ReadContainerRequest) returns (Container);
}

service CurrencyWallets {
  rpc Transfer(WalletTransferRequest) returns (WalletResult); // op_id, from, to, currency id, amount
  rpc Balance(BalanceRequest) returns (Balance);
}
```

## Work packages

Copied from ARCH § Modules, work packages and the implementation contract (Platform). Each package is one Claude Code session and one pull request inside its block directory.

| ID | Package | Done when | Needs | Slice |
| --- | --- | --- | --- | --- |
| PBB-1 | Item ledger: containers, slots, atomic transfers, operation IDs; mechanisms only | Concurrent transfers never duplicate or lose an item | PSDK-2 | 28 |
| PBB-2 | Currency wallets; mechanisms only | Defined when the expansion slices are planned | PSDK-2 | 44+ |

## Acceptance tests

| Package | Test | Passes when |
| --- | --- | --- |
| PBB-1 | Concurrent transfers | Many concurrent transfers of the same items never duplicate or lose one |
| PBB-1 | Replay | A transfer replayed with the same operation ID changes nothing |
| PBB-1 | Slice 28 | Kill, loot, log out, keep the item (with GPL-4, GSVC-2 and GSRV-1; GSVC-2 and GSRV-1 are defined in RunicGame) |
| PBB-2 | — | Defined when the expansion slices are planned |
| All | Neutrality review | No game name, rule or value in code or tests |

## Open items

- ARCH has game services move items and currency together atomically through "the ledger and wallets", but the ledger and wallets are separate blocks. How one operation spans both (one service and database, or a two-phase protocol) is decided before PBB-2.
- Whether the ledger runs only as its own service or can also be linked as a library into a game service is not stated; ARCH lists building blocks among the Platform services.
