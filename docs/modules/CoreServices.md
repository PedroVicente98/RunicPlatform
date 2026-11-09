---
# obsidian-graph: generated tags and aliases
tags:
  - repo/platform
  - source/arch
  - type/module
  - lang/go
  - slice/27
aliases:
  - "Core services"
  - "World Coordinator"
---

# CoreServices

This file is the contract of the Platform core services: accounts and entitlements, connect tickets, the World Coordinator, instance allocation, world directives, chat and party groups, and admission, all Go services on the Platform SDK.

| Field | Value |
| --- | --- |
| Language | Go |
| Directory | `go/services/<service>/` per service, with `internal/` for private code and tests beside the code; executables in `go/cmd/<service>/` (proposal) |
| Go package | `<module path>/go/services/...`; module path is the placeholder `runic.local/platform` (OQ-9[^oq-9]) |
| Depends on | Platform GoSDK[^platform-gosdk]; Platform Contracts[^platform-contracts] (service APIs) |
| Status | Not started |

When PCS-1 starts, this file's content moves into `go/services/ARCHITECTURE.md` with the section list from [../system/02-module-contract.md](../system/02-module-contract.md), and this file then links to it.

## Purpose

Supply the services every MMORPG needs and no single game should rewrite: who may log in and to which simulation, which simulation owns which region, where instances run, what world-wide directives apply when, and how players chat and group (ARCH[^arch] § Platform and operations).

## Owns

| Service (directory, proposal) | Owns | Work package |
| --- | --- | --- |
| Accounts (`go/services/accounts`) | Login; entitlements (access levels the game configures); issuing `GlobalPlayerId` (the CORE-1[^engine-core] plain player ID); signed, short-lived connect tickets for a player's simulation (including the destination simulation of a world transition, Engine NET-8[^engine-network]), signed with rotating keys whose public halves the simulations load | PCS-1 |
| World Coordinator (`go/services/coordinator`) | Worlds and the region-to-simulation map per world, neighbor topology, handoff candidates, drains, the world epoch that world time counts from (PCS-2); placement by load, memory and inter-simulation traffic, and placement requests to Agones (PCS-7) | PCS-2, PCS-7 |
| World directives (`go/services/directives`) | World-wide directives (for example weather, wind and current events) with an effective world time and a duration | PCS-3 |
| Instance allocation (`go/services/instances`) | Instances (for example dungeons and raids) allocated from Agones fleets | PCS-4 |
| Chat and party groups (`go/services/social`) | Social transport and party membership; group rules come from game data | PCS-5 |
| Admission (`go/services/admission`) | Per-world capacity limits, a login queue and cohort waves for staged launches; when and how a game uses them is its own decision | PCS-6 |

Every service owns its own tables, its gRPC API (defined in Contracts[^platform-contracts]) and its metrics.

## Does not own

| Responsibility | Owner |
| --- | --- |
| Verifying a ticket in the simulation (signature, expiry, key ID) | Platform Transport[^platform-transport] (PTR-2) |
| Delivering world directives into a simulation | Platform ServerBindings[^platform-serverbindings] (PBND-4: NATS subscription delivered to the service port's inbox at safe ticks) |
| Using the world epoch: world time, day and night | Engine `Runic::Environment`[^engine-environment] (ENV-1), which reads the epoch from configuration until PCS-2 ships (slice 36) |
| Authority semantics, epochs, ghosts, the transfer protocol | Engine `Runic::DistributedSimulation`[^engine-distributedsimulation] |
| The channel a simulation link uses (in-memory queue, local socket or shared memory, network) once placement is known | Platform Transport (PTR-4) |
| Leaving one world and joining another (checkpoint, then a new ticket) | Engine `Runic::Network`[^engine-network] (NET-8); the character checkpoint is a game service |
| Deciding when a storm or other world event happens | A RunicGame service; the Platform only delivers the directive |
| Applying a directive in the world | Engine (for example `Runic::Environment` applies an override at its effective time) |
| Characters, inventory rules, quest progress, guilds, mail, economy and every other game rule | RunicGame services |
| Group rules (sizes, roles, permissions) | Game data |
| Fleets, manifests and dashboards | Platform Infrastructure[^platform-infrastructure] |

## Depends on / never depends on

| May depend on | Never depends on |
| --- | --- |
| Platform GoSDK[^platform-gosdk] | RunicEngine (Go services need no Engine code) |
| Platform Contracts[^platform-contracts] | RunicGame code, names or rules |
| The Agones allocation API (World Coordinator placement and PCS-4) | Each other's tables; services talk through their APIs |
| — | The realtime path: no core service is on per-tick replication, ghost or combat traffic |

## Rules

- Do: build every service on the SDK; every durable change is an operation with an ID.
- Do: issue connect tickets the simulation can check locally (signature, expiry and key ID) with no call back to a service; rotate the signing keys and make their public halves available for the simulations to load.
- Do: give directives an effective world time a few seconds ahead and a duration, so every owning simulation applies them on the same tick and the baseline returns on the same tick when they end.
- Do: place simulations by load, memory and inter-simulation traffic; the distance between simulations comes from their regions' global coordinates. Pairs that exchange much traffic move onto one node by move-by-handoff, up to a per-node cap (PCS-7); a running simulation is never restarted to move it.
- Do: take entitlement names and group rules from configuration or game data, never from code.
- Never: put a game rule here; a game extends a service through data or builds its own service on the SDK.
- Never: put a core service in the hot path of a tick or of a handoff; a new open-world simulation is never allocated inside a handoff's critical path.
- Never: encode simulation ownership into the world partition; regions, sectors and cells stay fixed while ownership is a separate assignment.
- Never: name handoff candidates across worlds; worlds never share a border, so moving between them is a world transition, never a handoff.

## Interfaces it implements or exposes (sketch)

Illustrative only; the real APIs are defined in Contracts[^platform-contracts] by each package's contract session.

```protobuf
// Illustrative, not a frozen schema.
service Accounts {
  rpc Login(LoginRequest) returns (LoginReply);              // entitlements checked; GlobalPlayerId issued
  rpc IssueConnectTicket(TicketRequest) returns (ConnectTicket); // signed with the current rotating key
  rpc TicketPublicKeys(KeysRequest) returns (TicketKeySet);  // public halves the simulations load
}

service WorldCoordinator {
  rpc RegionMap(RegionMapRequest) returns (RegionMap);       // world → region → simulation
  rpc HandoffCandidates(BorderQuery) returns (CandidateList); // up to three candidates
  rpc Drain(DrainRequest) returns (DrainReply);
  rpc WorldEpoch(WorldEpochRequest) returns (WorldEpoch);    // world time counts from it
  rpc ReportLoad(LoadReport) returns (LoadAck);              // load, memory and link traffic (PCS-7)
}

service WorldDirectives {
  rpc Publish(Directive) returns (DirectiveAck);             // effective_world_time and duration required
}
```

```text
Session start (ARCH § Networking: stack, sessions and responsiveness)
1. Client logs in (Accounts) and receives a signed, short-lived connect ticket for its simulation.
2. Client connects directly to the simulation (Transport) and presents the ticket first.
3. Simulation checks signature, expiry and key ID locally against its loaded public keys; no service call in the hot path.
```

## Work packages

Copied from ARCH[^arch] § Modules, work packages and the implementation contract (Platform), revision 502. Each package is one Claude Code session and one pull request inside its service directory.

| ID | Package | Done when | Needs | Slice |
| --- | --- | --- | --- | --- |
| PCS-1 | Accounts and entitlements, GlobalPlayerId issue, login, connect tickets signed with rotating keys whose public halves the simulations load | Login returns a signed ticket the simulation accepts | PSDK-2[^platform-gosdk], PTR-2[^platform-transport] | 27 |
| PCS-2 | World Coordinator: worlds and region map, neighbor topology, handoff candidates, the world epoch | The Coordinator names the candidates for a border | PSDK-1 | 36 |
| PCS-3 | World directives with an effective time and a duration (weather, wind and current events) | A directive applies and expires at the same world time everywhere | PSDK-3, PBND-4[^platform-serverbindings] | 43 |
| PCS-4 | Instance allocation from Agones fleets | Defined when the expansion slices are planned | PCS-2, PINF-2[^platform-infrastructure] | 44+ |
| PCS-5 | Chat and party groups | Defined when the expansion slices are planned | PSDK-3 | 44+ |
| PCS-6 | Admission: per-world capacity limits, login queue and cohort waves for the launch phases | Defined when the expansion slices are planned | PCS-1 | 44+ |
| PCS-7 | Placement by load and traffic over Agones: scores by load, memory and inter-simulation traffic, with distance from the regions' global coordinates; moves high-traffic pairs onto one node by move-by-handoff, up to a per-node cap | Two simulations with heavy link traffic end on one node with no loading screen; no node passes its cap | PCS-2, PINF-2, PTR-4 | 44+ |

## Acceptance tests

| Package | Test | Passes when |
| --- | --- | --- |
| PCS-1 | Real ticket | Login returns a signed ticket that the PTR-2[^platform-transport] verifier in a simulation accepts (slice 27 runnable result, together with SIM-5[^engine-simulation], PBND-1[^platform-serverbindings] and GSVC-1[^doc-game-packages]; GSVC-1 is defined in RunicGame) |
| PCS-1 | Entitlements | A login without the required entitlement is refused |
| PCS-1 | Player ID | Login returns the account's `GlobalPlayerId`, the same one on every login |
| PCS-1 | Key rotation | After a key rotation, a simulation that loaded the new public half accepts tickets signed with the new key |
| PCS-2 | Candidates | The Coordinator names the candidates for a border (slice 36) |
| PCS-2 | World epoch | Two simulations that read the Coordinator's world epoch agree on world time |
| PCS-3 | Same world time | A directive applies and expires at the same world time in two simulations (slice 43) |
| PCS-7 | Placement by traffic | Two simulations with heavy link traffic end on one node by move-by-handoff with no loading screen; no node passes its cap |
| PCS-4, PCS-5, PCS-6 | — | Defined when the expansion slices are planned |
| All | Neutrality review | No game name, rule or value in code or tests |

## Contract-session items

- How the simulations load the public key halves (configuration at start, or a call at start and on rotation) is fixed in the PCS-1 contract session together with PTR-2[^platform-transport]; it is never a call per ticket.
- The world-epoch handover in slice 36: simulations that read the epoch from configuration before PCS-2 must read the same value the Coordinator then issues. The PCS-2 contract session states how the configured value and the issued one stay equal.

<!-- obsidian-graph:start -->

---

## Connections

*Generated for the Obsidian graph. The numbered markers in the text jump to the footnotes below, which link the notes they refer to.*

- **Depends on:** [[../modules/GoSDK|GoSDK]] · [[../modules/Contracts|Contracts]]
- **Its packages need:** [[../modules/Transport|Transport]] · [[../modules/ServerBindings|ServerBindings]] · [[../modules/Infrastructure|Infrastructure]]
- **Packages that need it:** [[../../../RunicEngine/docs/modules/Network|Network]] · [[../../../RunicGame/docs/game-packages|Game work packages]]
- **See also:** [[../modules/README|Platform module catalog]] · [[../../../RunicEngine/docs/system/03-dependency-rules|03 — Dependency rules]] · [[../../../RunicEngine/docs/system/12-work-packages|12 — Work packages]] · [[../current-state|Platform current state]]

[^oq-9]: [[../system/11-open-questions#OQ-9 — Platform naming: canonical Go module path|OQ-9]] — open question or decision
[^platform-gosdk]: [[../modules/GoSDK|GoSDK]] — Platform module · Go
[^platform-contracts]: [[../modules/Contracts|Contracts]] — Platform module · Protobuf
[^arch]: #source/arch — ARCH, "RunicEngine — Technical Architecture" (v4, in the RunicDocs vault): the architecture source of truth
[^engine-core]: [[../../../RunicEngine/docs/modules/Core|Core]] — Engine module · Foundation
[^engine-network]: [[../../../RunicEngine/docs/modules/Network|Network]] — Engine module · Networking
[^platform-transport]: [[../modules/Transport|Transport]] — Platform module · C++
[^platform-serverbindings]: [[../modules/ServerBindings|ServerBindings]] — Platform module · C++
[^engine-environment]: [[../../../RunicEngine/docs/modules/Environment|Environment]] — Engine module · World systems
[^engine-distributedsimulation]: [[../../../RunicEngine/docs/modules/DistributedSimulation|DistributedSimulation]] — Engine module · Networking
[^platform-infrastructure]: [[../modules/Infrastructure|Infrastructure]] — Platform module · configuration
[^engine-simulation]: [[../../../RunicEngine/docs/modules/Simulation|Simulation]] — Engine module · Simulation core
[^doc-game-packages]: [[../../../RunicGame/docs/game-packages|Game work packages]] — RunicGame work packages
