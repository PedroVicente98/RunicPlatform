# CoreServices

This file is the contract of the Platform core services: accounts and entitlements, connect tickets, the World Coordinator, instance allocation, world directives, and chat and party groups, all Go services on the Platform SDK.

| Field | Value |
| --- | --- |
| Language | Go |
| Directory | `go/services/<service>/` per service, with `internal/` for private code and tests beside the code; executables in `go/cmd/<service>/` (proposal) |
| Go package | `<module path>/go/services/...`; module path is the placeholder `runic.local/platform` (OQ-9) |
| Depends on | Platform GoSDK; Platform Contracts (service APIs) |
| Status | Not started |

When PCS-1 starts, this file's content moves into `go/services/ARCHITECTURE.md` with the section list from [../system/02-module-contract.md](../system/02-module-contract.md), and this file then links to it.

## Purpose

Supply the services every MMORPG needs and no single game should rewrite: who may log in and to which simulation, which simulation owns which region, where instances run, what world-wide directives apply when, and how players chat and group (ARCH § Platform and operations).

## Owns

| Service (directory, proposal) | Owns | Work package |
| --- | --- | --- |
| Accounts (`go/services/accounts`) | Login; entitlements (access levels the game configures); signed, short-lived connect tickets for a player's simulation | PCS-1 |
| World Coordinator (`go/services/coordinator`) | Region-to-simulation map, neighbor topology, handoff candidates, drains, placement requests to Agones | PCS-2 |
| World directives (`go/services/directives`) | World-wide directives (for example weather events) with an effective world time | PCS-3 |
| Instance allocation (`go/services/instances`) | Instances (for example dungeons and raids) allocated from Agones fleets | PCS-4 |
| Chat and party groups (`go/services/social`) | Social transport and party membership; group rules come from game data | PCS-5 |

Every service owns its own tables, its gRPC API (defined in Contracts) and its metrics.

## Does not own

| Responsibility | Owner |
| --- | --- |
| Verifying a ticket in the simulation | Platform Transport (PTR-2) |
| Authority semantics, epochs, ghosts, the transfer protocol | Engine `Runic::DistributedSimulation` |
| Deciding when a storm or other world event happens | A RunicGame service; the Platform only delivers the directive |
| Applying a directive in the world | Engine (for example `Runic::Environment` applies an override at its effective time) |
| Characters, inventory rules, quest progress, guilds, mail, economy and every other game rule | RunicGame services |
| Group rules (sizes, roles, permissions) | Game data |
| Fleets, manifests and dashboards | Platform Infrastructure |

## Depends on / never depends on

| May depend on | Never depends on |
| --- | --- |
| Platform GoSDK | RunicEngine (Go services need no Engine code) |
| Platform Contracts | RunicGame code, names or rules |
| The Agones allocation API (World Coordinator placement and PCS-4) | Each other's tables; services talk through their APIs |
| — | The realtime path: no core service is on per-tick replication, ghost or combat traffic |

## Rules

- Do: build every service on the SDK; every durable change is an operation with an ID.
- Do: issue connect tickets the simulation can check locally (signature and expiry) with no call back to a service.
- Do: give directives an effective world time a few seconds ahead, so every owning simulation applies them on the same tick.
- Do: take entitlement names and group rules from configuration or game data, never from code.
- Never: put a game rule here; a game extends a service through data or builds its own service on the SDK.
- Never: put a core service in the hot path of a tick or of a handoff; a new open-world simulation is never allocated inside a handoff's critical path.
- Never: encode simulation ownership into the world partition; regions, sectors and cells stay fixed while ownership is a separate assignment.

## Interfaces it implements or exposes (sketch)

Illustrative only; the real APIs are defined in Contracts by each package's contract session.

```protobuf
// Illustrative, not a frozen schema.
service Accounts {
  rpc Login(LoginRequest) returns (LoginReply);              // entitlements checked here
  rpc IssueConnectTicket(TicketRequest) returns (ConnectTicket);
}

service WorldCoordinator {
  rpc RegionMap(RegionMapRequest) returns (RegionMap);       // region → simulation
  rpc HandoffCandidates(BorderQuery) returns (CandidateList); // up to three candidates
  rpc Drain(DrainRequest) returns (DrainReply);
}

service WorldDirectives {
  rpc Publish(Directive) returns (DirectiveAck);             // effective_world_time required
}
```

```text
Session start (ARCH § Networking: stack, sessions and responsiveness)
1. Client logs in (Accounts) and receives a signed, short-lived connect ticket for its simulation.
2. Client connects directly to the simulation (Transport) and presents the ticket first.
3. Simulation checks signature and expiry locally; no service call in the hot path.
```

## Work packages

Copied from ARCH § Modules, work packages and the implementation contract (Platform). Each package is one Claude Code session and one pull request inside its service directory.

| ID | Package | Done when | Needs | Slice |
| --- | --- | --- | --- | --- |
| PCS-1 | Accounts and entitlements, login, connect tickets | Login returns a signed ticket the simulation accepts | PSDK-2, PTR-2 | 27 |
| PCS-2 | World Coordinator: region map, neighbor topology, handoff candidates | The Coordinator names the candidates for a border | PSDK-1 | 36 |
| PCS-3 | World directives with an effective time (weather events) | A directive applies at the same world time everywhere | PSDK-3 | 43 |
| PCS-4 | Instance allocation from Agones fleets | Defined when the expansion slices are planned | PCS-2, PINF-2 | 44+ |
| PCS-5 | Chat and party groups | Defined when the expansion slices are planned | PSDK-3 | 44+ |

## Acceptance tests

| Package | Test | Passes when |
| --- | --- | --- |
| PCS-1 | Real ticket | Login returns a signed ticket that the PTR-2 verifier in a simulation accepts (slice 27 runnable result, together with SIM-5, PBND-1 and GSVC-1; GSVC-1 is defined in RunicGame) |
| PCS-1 | Entitlements | A login without the required entitlement is refused |
| PCS-2 | Candidates | The Coordinator names the candidates for a border (slice 36) |
| PCS-3 | Same world time | A directive applies at the same world time in two simulations (slice 43) |
| PCS-4, PCS-5 | — | Defined when the expansion slices are planned |
| All | Neutrality review | No game name, rule or value in code or tests |

## Open items

- ARCH says the World Coordinator issues the world epoch that world time counts from (ARCH § Environment: environment clock), but PCS-2 does not list it and arrives in slice 36, after ENV-1 (slice 25). Until then a world epoch must come from configuration; the owner confirms.
- ARCH § Environment calls override delivery "World Coordinator directives", while the package table puts directives in their own package (PCS-3). This contract treats them as a separate service; the PCS-3 contract session confirms.
- How directives reach simulations (NATS through the ServicesBridgeLayer is the likely path, since PCS-3 needs PSDK-3) is decided in the PCS-3 contract session.
- Key distribution for connect-ticket signatures (how simulations learn the verification key, and rotation) is not specified in ARCH.
- Admission mechanisms (entitlement checks at login, per-world capacity limits, admission waves by account cohort, a login queue per world) appear under slice 44+ with no package ID; they likely extend PCS-1.
- Durable water state (dam, lock or water-level states) is stored by the Platform "through a Game service" (ARCH § Water system); no Platform package names it, so it is read here as SDK persistence used by a RunicGame service.
