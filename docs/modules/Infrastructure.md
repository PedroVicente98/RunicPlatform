# Infrastructure

This file is the contract of the Platform Infrastructure module: the local development stack, Agones fleets, Kubernetes manifests, and the Prometheus and Grafana monitoring setup.

| Field | Value |
| --- | --- |
| Language | Configuration and scripts (container compose files, Kubernetes and Agones manifests, Prometheus configuration, Grafana dashboards as JSON) |
| Directory | `infra/` (new; proposal): `infra/local/` (PINF-1), `infra/agones/`, `infra/kubernetes/`, `infra/monitoring/` (PINF-2) |
| CMake target or Go package | None; no build target |
| Depends on | Nothing at build time. At runtime it starts PostgreSQL and NATS (PINF-1), and deploys GameServer fleets with the LifecycleLayer (PBND-2) and the exporter (PBND-3) (PINF-2) |
| Status | Not started |

When PINF-1 starts, this file's content moves into `infra/ARCHITECTURE.md` with the section list from [../system/02-module-contract.md](../system/02-module-contract.md), and this file then links to it.

## Purpose

Run everything the Platform and the Game need outside the simulation: locally with one command, and in a cluster with Agones and Kubernetes, watched from one Grafana panel (ARCH § Platform and operations).

## Owns

- The local development stack: PostgreSQL and NATS started by one command (PINF-1). Gameplay work never needs Kubernetes: a developer runs GameServer directly, without a lifecycle layer or with the LifecycleLayer's local stub mode (PBND-2), and, only when a feature needs them, local NATS and Go services.
- Agones fleets for GameServer: one region per simulation pod by default; pods request whole vCPUs (PINF-2).
- Kubernetes manifests for Platform services and building blocks, and the deployment pattern Game services reuse (PINF-2).
- Prometheus scraping of the GameServer exporters (PBND-3), the Go services (through the SDK) and Agones (PINF-2).
- Grafana as the single operations panel: Platform dashboards (time per clock domain and system, tick backlog, players, entities, bandwidth per client, handoffs, ghosts; Agones fleets, allocations and game-server states), with logs joining the same panel (PINF-2).

## Does not own

| Responsibility | Owner |
| --- | --- |
| Recording simulation metrics | Every GameServer, in the Core metrics registry (CORE-2); the Engine Diagnostics layer (NET-7) adds network and replication metrics |
| Exporting simulation metrics | Platform ServerBindings (PBND-3 publishes the Core registry) |
| Agones SDK calls inside the server | Platform ServerBindings (PBND-2) |
| Placement decisions (which region runs where, when to move or resize) | Platform CoreServices (World Coordinator) |
| Dashboards for game metrics | RunicGame |
| Live inspection of a running server | Engine Editor attach (development and staging only) |

## Depends on / never depends on

| May depend on | Never depends on |
| --- | --- |
| Container images of the Platform services and the Game's executables and services, built elsewhere | RunicGame rules or content in manifests or dashboards (game dashboards live in RunicGame) |
| Agones, Kubernetes, Prometheus, Grafana, PostgreSQL, NATS | Any requirement that gameplay development run Kubernetes |
| — | A debug or attach endpoint on production servers; production exposes metrics only through the exporter |

## Rules

- Do: keep the local stack to one command, and keep it optional for gameplay work.
- Do: size simulation pods in whole vCPUs; the simulation sizes its worker pool from them.
- Do: keep Grafana the single operations panel; Agones, simulations and Go services all report to the same Prometheus.
- Never: put game values (names, regions, rules) into Platform manifests; games supply their own values.
- Never: route per-tick traffic through any infrastructure component; clients and simulations talk directly.
- Never: use pinned exclusive cores except for hot fleets after profiling (they block in-place resize).

## Interfaces it implements or exposes (sketch)

Illustrative only; PINF-1 and PINF-2 fix the files and commands.

```text
infra/
├── local/
│   └── compose.yaml          # PostgreSQL + NATS; started by one command (PINF-1)
├── agones/
│   └── gameserver-fleet.yaml # fleet template; the game fills in its image and values
├── kubernetes/
│   └── services/             # Platform core services and building blocks
├── monitoring/
│   ├── prometheus/           # scrape configuration
│   └── grafana/dashboards/   # Platform dashboards as JSON
└── ARCHITECTURE.md
```

| Placement rule (ARCH § Platform and operations: simulation placement) | Mechanism |
| --- | --- |
| One region per simulation pod by default; quiet neighbors may share a pod, and several simulations may share one process | Fleet configuration |
| Grow in place | Kubernetes in-place pod resize; the simulation picks up the new worker count at a safe point |
| Move to a bigger machine | The World Coordinator starts a new pod and hands the region off; Kubernetes never moves a running process |
| Busy areas | A busy area such as a city gets its own simulation through an Engine AuthorityPartition (DSIM-5), placed like any other simulation |
| Placement by load and traffic | The World Coordinator (PCS-7) scores nodes by load, memory and inter-simulation traffic and moves high-traffic pairs onto one node by move-by-handoff, up to a per-node cap; node sizes and caps are fleet configuration |
| Instances | Agones-allocated game servers from fleets |
| Regional datacenters | One Kubernetes cluster with Agones per datacenter; accounts are global |

## Work packages

Copied from ARCH § Modules, work packages and the implementation contract (Platform), revision 502. Each package is one Claude Code session and one pull request inside `infra/`.

| ID | Package | Done when | Needs | Slice |
| --- | --- | --- | --- | --- |
| PINF-1 | Local development stack (PostgreSQL, NATS) started by one command | The stack starts and the service tests pass against it | — | 26 |
| PINF-2 | Agones fleets, Kubernetes manifests, Prometheus and Grafana dashboards | A fleet runs in a development cluster, servers report Ready, and Grafana shows time per tick domain | PBND-2, PBND-3 | 39 |

## Acceptance tests

| Package | Test | Passes when |
| --- | --- | --- |
| PINF-1 | One command | The stack starts with one command and the PSDK-2 service tests pass against it |
| PINF-1 | Teardown | The stack stops and leaves nothing running |
| PINF-2 | Fleet | A GameServer fleet runs in a development cluster; servers report Ready (through PBND-2) and drain cleanly |
| PINF-2 | Panel | Grafana shows time per tick domain, Go service metrics and Agones fleet state on one panel (slice 39) |

## Contract-session items

- The container tool for the local stack (for example Docker Compose or Podman) is chosen in PINF-1.
- Where container images for Platform services are built and published is not specified in ARCH.
- Log collection ("logs join the same panel") names no tool in ARCH; PINF-2 proposes one.
