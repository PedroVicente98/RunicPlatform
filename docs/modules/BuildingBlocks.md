---
# obsidian-graph: generated tags and aliases
tags:
  - repo/platform
  - source/arch
  - type/module
  - lang/go
  - slice/28
aliases:
  - "Building blocks"
  - "Item ledger"
  - "Currency wallets"
---

# BuildingBlocks

This file is the contract of the Platform building blocks: the item ledger and currency wallets, Go services that provide durable item and currency mechanisms with no game rules.

| Field | Value |
| --- | --- |
| Language | Go |
| Directory | `go/blocks/ledger/` and `go/blocks/wallets/`, with `internal/` for private code and tests beside the code; executables in `go/cmd/<service>/` (proposal) |
| Go package | `<module path>/go/blocks/...`; module path is the placeholder `runic.local/platform` (OQ-9[^oq-9]) |
| Depends on | Platform GoSDK[^platform-gosdk]; Platform Contracts[^platform-contracts] (service APIs) |
| Status | Not started |

When PBB-1 starts, this file's content moves into `go/blocks/ARCHITECTURE.md` with the section list from [../system/02-module-contract.md](../system/02-module-contract.md), and this file then links to it.

## Purpose

Give games a durable owner for items and currencies whose only promise is correctness: nothing is duplicated or lost, every change is an operation with an ID, and transfers are atomic, including transfers that move items and currency together in one transaction. What an item is, who may move it and why is decided by the game's own services on top (ARCH[^arch] § Platform and operations: services).

## Owns

| Block | Owns | Work package |
| --- | --- | --- |
| Item ledger | Item instances, containers, slots, atomic transfers, operation IDs | PBB-1 |
| Currency wallets | Balances and atomic transfers with operation IDs | PBB-2 |
| One-transaction transfers | Transfers that move ledger items and wallet currency together in one transaction | PBB-3 |

- The ledger's and wallets' tables, gRPC APIs (defined in Contracts[^platform-contracts]) and metrics.
- Concurrency control that keeps concurrent transfers from duplicating or losing anything.
- Deduplication by operation ID through the SDK idempotency store.

## Does not own

| Responsibility | Owner |
| --- | --- |
| Item definitions, stats, stacking, binding, equip and trade limits, loot rules | RunicGame (data and its inventory service) |
| Currencies' meaning, sources, sinks and any economy rule | RunicGame services |
| The runtime item and container mirror inside the simulation | Engine `Runic::Gameplay`[^engine-gameplay] (GPL-4) |
| Deciding whether a transfer is allowed | The calling game service; the ledger only checks that the transfer is consistent |
| Transactions and the idempotency store | Platform GoSDK[^platform-gosdk] |

## Depends on / never depends on

| May depend on | Never depends on |
| --- | --- |
| Platform GoSDK[^platform-gosdk] | RunicEngine (Go services need no Engine code) |
| Platform Contracts[^platform-contracts] | RunicGame code, names, item tables or rules |
| — | Platform CoreServices[^platform-coreservices]' tables |
| — | The realtime path: the ledger is reached through services, never on per-tick traffic |

## Rules

- Do: make every change an operation with an ID; a retried operation commits once.
- Do: keep transfers atomic: an item leaves one slot and enters another in one transaction, or nothing changes.
- Do: commit a transfer that moves items and currency (for example both sides of a trade) in one transaction under one operation ID (PBB-3); never split it into two operations that can half-succeed.
- Do: treat item and container contents as opaque payloads that the game defines.
- Never: add stacking, binding, trade limits, item value or tier rules, or any other game rule.
- Never: let a simulation write the ledger directly; simulations send durable operations through the ServicesBridgeLayer[^platform-serverbindings] to a game service, which calls the ledger.

## Interfaces it implements or exposes (sketch)

Illustrative only; PBB-1, PBB-2 and PBB-3 fix the APIs in Contracts[^platform-contracts].

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
  rpc Exchange(ExchangeRequest) returns (ExchangeResult);     // op_id; ledger items and wallet currency
                                                              // move in one transaction (PBB-3)
}
```

## Work packages

Copied from ARCH[^arch] § Modules, work packages and the implementation contract (Platform), revision 502. Each package is one Claude Code session and one pull request inside its block directory.

| ID | Package | Done when | Needs | Slice |
| --- | --- | --- | --- | --- |
| PBB-1 | Item ledger: containers, slots, atomic transfers, operation IDs; mechanisms only | Concurrent transfers never duplicate or lose an item | PSDK-2[^platform-gosdk] | 28 |
| PBB-2 | Currency wallets: balances and atomic transfers with operation IDs; mechanisms only | A balance changes once per operation ID under concurrent requests | PSDK-2 | 33a |
| PBB-3 | One-transaction transfers that move ledger items and wallet currency together; mechanisms only | Defined when the expansion slices are planned | PBB-1, PBB-2 | 44+ |

## Acceptance tests

| Package | Test | Passes when |
| --- | --- | --- |
| PBB-1 | Concurrent transfers | Many concurrent transfers of the same items never duplicate or lose one |
| PBB-1 | Replay | A transfer replayed with the same operation ID changes nothing |
| PBB-1 | Slice 28 | Kill, loot, log out, keep the item (with GPL-4[^engine-gameplay], GSVC-2[^doc-game-packages] and GSRV-1; GSVC-2 and GSRV-1 are defined in RunicGame) |
| PBB-2 | Concurrent wallet operations | A balance changes once per operation ID under concurrent requests |
| PBB-2 | Slice 33a | The exploration prototype runs end to end (with GSRV-5, GSRV-6, GSVC-5 and GCL-4, defined in RunicGame) |
| PBB-3 | — | Defined when the expansion slices are planned |
| All | Neutrality review | No game name, rule or value in code or tests |

## Contract-session items

- PBB-3's one-transaction transfers commit ledger and wallet changes in the same PostgreSQL transaction (through the SDK, PSDK-2[^platform-gosdk]). The PBB-1 and PBB-2 contract sessions lay out the ledger's and wallets' storage so PBB-3 can do that without a second protocol.
- Whether the ledger and wallets run only as their own services or can also be linked as libraries into a game service is decided in the PBB-1 contract session.

<!-- obsidian-graph:start -->

---

## Connections

*Generated for the Obsidian graph. The numbered markers in the text jump to the footnotes below, which link the notes they refer to.*

- **Depends on:** [[../modules/GoSDK|GoSDK]] · [[../modules/Contracts|Contracts]]
- **Packages that need it:** [[../../../RunicGame/docs/game-packages|Game work packages]]
- **See also:** [[../modules/README|Platform module catalog]] · [[../../../RunicEngine/docs/system/03-dependency-rules|03 — Dependency rules]] · [[../../../RunicEngine/docs/system/12-work-packages|12 — Work packages]] · [[../current-state|Platform current state]]

[^oq-9]: [[../system/11-open-questions#OQ-9 — Platform naming: canonical Go module path|OQ-9]] — open question or decision
[^platform-gosdk]: [[../modules/GoSDK|GoSDK]] — Platform module · Go
[^platform-contracts]: [[../modules/Contracts|Contracts]] — Platform module · Protobuf
[^arch]: #source/arch — ARCH, "RunicEngine — Technical Architecture v3": the architecture source of truth (a project document, not a note in this vault)
[^engine-gameplay]: [[../../../RunicEngine/docs/modules/Gameplay|Gameplay]] — Engine module · GameplayAPI
[^platform-coreservices]: [[../modules/CoreServices|CoreServices]] — Platform module · Go
[^platform-serverbindings]: [[../modules/ServerBindings|ServerBindings]] — Platform module · C++
[^doc-game-packages]: [[../../../RunicGame/docs/game-packages|Game work packages]] — RunicGame work packages
