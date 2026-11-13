# go/blocks/ — BuildingBlocks

Packages: PBB-1, PBB-2, PBB-3

Mechanisms with no game rules that game services build on: the item ledger and currency wallets, and transfers that move both in one transaction.

| Package | Holds | Packages |
| --- | --- | --- |
| [`ledger/`](ledger/README.md) | The item ledger: containers, slots, atomic transfers, operation IDs. | PBB-1 (slice 28), PBB-3 (slice 44+) |
| [`wallets/`](wallets/README.md) | Currency wallets: balances and atomic transfers with operation IDs. | PBB-2 (slice 33a), PBB-3 (slice 44+) |

`go/blocks/ARCHITECTURE.md` (the contract) is written by the first package. Sources: RunicDocs › Architecture ›
Repositories, build targets and processes › Platform modules; Platform and operations (as of 2026-11-13).
