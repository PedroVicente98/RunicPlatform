---
# obsidian-graph: generated tags and aliases
tags:
  - repo/platform
  - source/arch
  - type/module
  - lang/go
  - slice/26
aliases:
  - "Go SDK"
---

# GoSDK

This file is the contract of the Platform Go SDK: the service skeleton, configuration, gRPC and NATS wiring, PostgreSQL persistence, transactions, migrations, idempotency store and metrics that every Platform and Game Go service is built on.

| Field | Value |
| --- | --- |
| Language | Go |
| Directory | `go/sdk/` (one directory per package, `internal/` for private code, tests beside the code) |
| Go package | `<module path>/go/sdk/...`; module path is the placeholder `runic.local/platform` (OQ-9[^oq-9]) |
| Depends on | Platform Contracts[^platform-contracts] (generated Go code); gRPC, NATS and PostgreSQL client libraries; a metrics library |
| Status | Not started |

When PSDK-1 starts, this file's content moves into `go/sdk/ARCHITECTURE.md` with the section list from [../system/02-module-contract.md](../system/02-module-contract.md), and this file then links to it.

## Purpose

Make every Go service the same kind of program, so that services differ only in their rules. Platform core services[^platform-coreservices], Platform building blocks[^platform-buildingblocks] and every RunicGame service use this SDK (ARCH[^arch] § Platform and operations: services). The SDK owns transactions and the idempotency store (OQ-16[^oq-16] decided); services own their data and rules. Game services store every kind of durable state through it, including durable water state (for example a lock or water level that must survive restarts), which then reaches the simulation through the service port; the Platform has no water-specific service (ARCH § Water system).

## Owns

| Package (proposal) | Contents | Work package |
| --- | --- | --- |
| `go/sdk/service` | Service skeleton: start, stop, health, graceful shutdown | PSDK-1 |
| `go/sdk/config` | Configuration loading and validation | PSDK-1 |
| `go/sdk/rpc` | gRPC server and client wiring, request context, deadlines | PSDK-1 |
| `go/sdk/metrics` | Service metrics exported to Prometheus | PSDK-1 |
| `go/sdk/persistence` | PostgreSQL access, transactions, migrations | PSDK-2 |
| `go/sdk/idempotency` | Idempotency store: an operation ID commits once, in the same transaction as its effect | PSDK-2 |
| `go/sdk/messaging` | NATS publish and subscribe; JetStream only where replay is needed | PSDK-3 |

## Does not own

| Responsibility | Owner |
| --- | --- |
| Any service's data model, API or rules | The service (Platform CoreServices[^platform-coreservices], BuildingBlocks[^platform-buildingblocks], or RunicGame services) |
| Message definitions | Platform Contracts[^platform-contracts] |
| Starting PostgreSQL and NATS locally | Platform Infrastructure[^platform-infrastructure] (PINF-1) |
| The C++ side of service calls from a simulation | Platform ServerBindings[^platform-serverbindings] (PBND-1 for gRPC, PBND-4 for NATS) |
| Quest progress, characters, inventory rules, economy and every other game rule | RunicGame services |

## Depends on / never depends on

| May depend on | Never depends on |
| --- | --- |
| Platform Contracts[^platform-contracts] (generated Go code; PSDK-1 needs PCT-1) | Platform CoreServices[^platform-coreservices] or BuildingBlocks[^platform-buildingblocks] (they depend on the SDK, not the reverse) |
| gRPC, NATS and PostgreSQL client libraries; a Prometheus metrics library | RunicEngine (Go services need no Engine code) |
| — | RunicGame code, names or rules |
| — | Any realtime, per-tick path: the SDK is never on replication, ghost or combat traffic |

## Rules

- Do: make every durable change an operation with an ID; the idempotency check and the effect commit in one transaction.
- Do: use gRPC for calls that need an answer and NATS for publish and subscribe with no answer; JetStream only where replay is required.
- Do: export every service's metrics through the SDK so they join the single Grafana panel.
- Do: keep the SDK generic; tests use neutral sample services.
- Never: add a game rule, a game table or a game name to the SDK.
- Never: give a service a shortcut around the idempotency store for durable writes.
- Never: make a simulation wait on a database; simulations reach services only through the ServicesBridgeLayer[^platform-serverbindings], asynchronously.

## Interfaces it implements or exposes (sketch)

Illustrative only; each package's contract session fixes the API.

```go
// Illustrative, not a frozen API.
package service

type Config struct {
	Name        string
	GRPCAddress string
	MetricsAddr string
	DatabaseURL string // optional; used by persistence
	NATSURL     string // optional; used by messaging
}

// Run starts the service, registers its gRPC handlers and blocks until shutdown.
func Run(ctx context.Context, cfg Config, register func(*grpc.Server)) error

package persistence

// InTx runs fn in one PostgreSQL transaction.
func (db *DB) InTx(ctx context.Context, fn func(tx Tx) error) error

package idempotency

// Once applies fn exactly once per operation ID inside tx; a repeat returns the stored result.
func Once[T any](ctx context.Context, tx persistence.Tx, op OperationID, fn func() (T, error)) (T, error)
```

## Work packages

Copied from ARCH[^arch] § Modules, work packages and the implementation contract (Platform), revision 502. Each package is one Claude Code session and one pull request inside `go/sdk/`.

| ID | Package | Done when | Needs | Slice |
| --- | --- | --- | --- | --- |
| PSDK-1 | Go service skeleton: configuration, gRPC wiring, metrics | A sample service answers a gRPC call and reports metrics | PCT-1[^platform-contracts] | 26 |
| PSDK-2 | Persistence: PostgreSQL, transactions, migrations, idempotency store | A retried operation commits once | PSDK-1 | 26 |
| PSDK-3 | NATS wiring: publish, subscribe, JetStream where replay is needed | A fact published once is consumed once per subscriber | PSDK-1 | 30 |

## Acceptance tests

| Package | Test | Passes when |
| --- | --- | --- |
| PSDK-1 | Sample service | A sample service answers a gRPC call and its metrics are scraped |
| PSDK-2 | Retried operation | A retried operation commits once, against the PINF-1[^platform-infrastructure] local stack |
| PSDK-2 | Migrations | Migrations apply in order on an empty database and are no-ops on an up-to-date one |
| PSDK-3 | Fan-out | A fact published once is consumed once per subscriber |
| All | Neutrality review | No game name, rule or value in code or tests |

Slice 26 runnable result: a Go service writes to PostgreSQL idempotently on the local stack (PINF-1, PSDK-1, PSDK-2).

## Contract-session items

- OQ-9[^oq-9] (still open): the canonical Go module path. See [../system/11-open-questions.md](../system/11-open-questions.md).
- `go.mod` declares `go 1.26.0`; every machine and CI runner that builds the SDK needs that toolchain.
- The existing placeholder package `go/platform/` is replaced or removed by PSDK-1; it holds no code.

<!-- obsidian-graph:start -->

---

## Connections

*Generated for the Obsidian graph. The numbered markers in the text jump to the footnotes below, which link the notes they refer to.*

- **Depends on:** [[../modules/Contracts|Contracts]]
- **Depended on by:** [[../modules/CoreServices|CoreServices]] · [[../modules/BuildingBlocks|BuildingBlocks]]
- **Packages that need it:** [[../modules/ServerBindings|ServerBindings]] · [[../../../RunicGame/docs/game-packages|Game work packages]]
- **See also:** [[../modules/README|Platform module catalog]] · [[../../../RunicEngine/docs/system/03-dependency-rules|03 — Dependency rules]] · [[../../../RunicEngine/docs/system/12-work-packages|12 — Work packages]] · [[../current-state|Platform current state]]

[^oq-9]: [[../system/11-open-questions#OQ-9 — Platform naming: canonical Go module path|OQ-9]] — open question or decision
[^platform-contracts]: [[../modules/Contracts|Contracts]] — Platform module · Protobuf
[^platform-coreservices]: [[../modules/CoreServices|CoreServices]] — Platform module · Go
[^platform-buildingblocks]: [[../modules/BuildingBlocks|BuildingBlocks]] — Platform module · Go
[^arch]: #source/arch — ARCH, "RunicEngine — Technical Architecture v3": the architecture source of truth (a project document, not a note in this vault)
[^oq-16]: [[../system/11-open-questions#OQ-16 — Quest storage placement (decided 2026-10-09)|OQ-16]] — open question or decision
[^platform-infrastructure]: [[../modules/Infrastructure|Infrastructure]] — Platform module · configuration
[^platform-serverbindings]: [[../modules/ServerBindings|ServerBindings]] — Platform module · C++
