---
# obsidian-graph: generated tags and aliases
tags:
  - repo/platform
  - source/arch
  - type/module
  - lang/cpp
  - slice/12
aliases:
  - "RunicPlatform::Transport"
  - "Platform Transport"
---

# Transport

This file is the contract of the Platform Transport module: the GameNetworkingSockets implementation of the Engine transport interface, connect-ticket checks and the connection set behind a player's WorldSession.

| Field | Value |
| --- | --- |
| Language | C++20 |
| Directory | `cpp/Transport/` with `Public/`, `Source/`, `Tests/`, `ARCHITECTURE.md`, `CMakeLists.txt` |
| CMake target | `RunicPlatform::Transport` (namespace `RunicPlatform::Transport`) |
| Depends on | Engine `Runic::NetworkTransport`[^engine-network] (header-only interface target from Network, NET-1: the transport interface and the connect-ticket hook, Core types only); Platform Contracts[^platform-contracts] (the connect-ticket format); GameNetworkingSockets (private) |
| Status | Not started |

When the first contract session creates `cpp/Transport/`, this file's content moves into `cpp/Transport/ARCHITECTURE.md` with the section list from [../system/02-module-contract.md](../system/02-module-contract.md), and this file then links to it.

## Purpose

Carry bytes between processes on the realtime path. Clients talk directly to their simulation, and neighbor simulations talk directly to each other over the cheapest channel for where they run, through the Engine's transport interface. This module is the Platform's implementation of that interface on GameNetworkingSockets: reliable and unreliable messages, encryption and congestion control over UDP (ARCH[^arch] § Networking: stack, sessions and responsiveness).

## Owns

- The GameNetworkingSockets implementation of the Engine transport interface (PTR-1), for client ↔ simulation and simulation ↔ simulation connections.
- GameNetworkingSockets setup, threads, sockets and connection handles, all hidden in `Source/`.
- Delivery classes the Engine asks for: unreliable sequenced, reliable, reliable ordered.
- Connect-ticket verification inside the simulation process (PTR-2): signature, expiry and key ID, checked locally against a configured set of public keys, with no service call. Until PCS-1[^platform-coreservices] issues real tickets (slice 27), tickets are test-signed with a local key (from slice 12); PCS-1 then signs with rotating keys whose public halves the simulations load.
- The connection set behind one WorldSession (PTR-3): one authoritative connection plus up to three candidate connections near borders, promotion with no loading screen, and the connection roles Primary, WarmCandidate, Dormant and Retiring.
- Simulation-to-simulation links (PTR-3) that carry the ghost deltas and transfer messages the Engine encodes.
- Link channels chosen by locality (PTR-4): an in-memory queue when both simulations run in one process, a local socket or shared-memory channel on one machine, GameNetworkingSockets between machines. The link picks its channel from the peers' placement, and DistributedSimulation[^engine-distributedsimulation] semantics never change with the channel.
- Per-connection statistics (bytes, loss, round-trip time) reported through the Engine transport interface, so the Engine's Diagnostics layer can record them in the Core metrics registry (proposal; the NET-1[^engine-network] contract decides the shape).

## Does not own

| Responsibility | Owner |
| --- | --- |
| Wire encoding of every realtime message, envelope included: inputs, snapshots, quantization, deltas, ghost deltas, transfer messages | Engine `Runic::Network`[^engine-network] |
| Ingress and egress queues, the Network layer, interest, priority budgets, prediction and reconciliation | Engine `Runic::Network` |
| Authority state, epochs, ghost state, transfer protocol, foreign interactions | Engine `Runic::DistributedSimulation`[^engine-distributedsimulation] |
| Which simulations are handoff candidates for a border | Platform CoreServices[^platform-coreservices] (World Coordinator, PCS-2) |
| Where simulations run (placement by load and traffic) | Platform CoreServices (World Coordinator, PCS-7) |
| Issuing connect tickets and rotating their signing keys; accounts; entitlements | Platform CoreServices (PCS-1) |
| The connect-ticket format and service message definitions | Platform Contracts[^platform-contracts] (PCT-1) |
| Game messages and any game rule | RunicGame |

Transport carries bytes. It never decides what a message means, who is authoritative, or what a player may do.

## Depends on / never depends on

| May depend on | Never depends on |
| --- | --- |
| `Runic::NetworkTransport`[^engine-network] only (header-only; its headers include only Core[^engine-core] types) | `Runic::Network` itself, `Runic::Simulation`[^engine-simulation], Flecs, Jolt, any gameplay module, any Engine `Source/` folder |
| Platform Contracts[^platform-contracts] (`RunicPlatform::Contracts`; PTR-1 needs PCT-1) | RunicGame, in code, tests or docs |
| GameNetworkingSockets, linked PRIVATE and never visible in `Public/` | gRPC, NATS, databases, Agones, Protobuf framing of realtime messages: nothing of these on the realtime path |
| A signature library for tickets, linked PRIVATE (chosen in the PTR-2 contract session) | Platform Go code; GLFW, bgfx, RmlUi, ImGui, audio or editor code (the module is headless and also links into the client) |

The dependency points one way: Transport includes Engine interface headers; the Engine never includes Transport. Because `Runic::NetworkTransport` is header-only with Core types only, building and testing Transport configures Core and never Flecs, Jolt or the gameplay modules.

## Rules

- Do: implement exactly the Engine transport interface as NET-1[^engine-network] defines it; report any change it needs to the Engine instead of working around it.
- Do: run network I/O on Transport's own threads and only enqueue into the Engine's ingress queues; read egress from the Engine's queues.
- Do: verify connect tickets locally (signature, expiry, key ID against the configured public keys) before any other message from that connection is accepted.
- Never: call the simulation thread, touch Flecs or block a tick from an I/O callback.
- Never: add a broker, a service call or a database lookup to per-tick traffic, ticket checks included.
- Never: wrap or re-encode realtime messages; `Runic::Network` encodes them, envelope included, and Transport carries the bytes.
- Never: let a GameNetworkingSockets type appear in a public header.
- Never: let gameplay code see addresses; the WorldSession stays the same while connections change.
- Never: let a link's channel change what crosses it; the same bytes, ordering and delivery classes on every channel.

## Interfaces it implements or exposes (sketch)

Illustrative only; the Engine's NET-1[^engine-network] contract session defines the real transport interface (shipped as `Runic::NetworkTransport`), and PTR-1 implements it.

```cpp
// cpp/Transport/Public/GnsTransport.hpp — illustrative, not a frozen API.
namespace RunicPlatform::Transport {

struct GnsTransportConfig {
    std::uint16_t listenPort = 0;         // 0 on clients
    std::uint32_t ioThreads  = 1;
};

// Implements the Engine transport interface; GameNetworkingSockets stays in Source/.
std::unique_ptr<Runic::Network::Transport> CreateGnsTransport(const GnsTransportConfig& config);

// Implements the Engine connect-ticket hook (PTR-2): signature, expiry and key ID; no service call.
class TicketVerifier final : public Runic::Network::ConnectTicketHook {
public:
    explicit TicketVerifier(TicketKeySet publicKeys);     // local test key until PCS-1; then PCS-1's rotating keys
    TicketCheck Verify(std::span<const std::byte> ticket, WallClockTime now) const override;
};

// PTR-3: the connection set behind one WorldSession.
enum class ConnectionRole { Primary, WarmCandidate, Dormant, Retiring };

} // namespace RunicPlatform::Transport
```

Control operations on the connection set (PTR-3): prepare, wake, promote, sleep, retire, drop. The Platform tells the client which to apply; gameplay code never reasons about addresses (ARCH[^arch] § Networking: replication, interest and handoff).

| Traffic it carries | Delivery |
| --- | --- |
| Movement input and transform state | Unreliable, sequenced; the latest wins |
| Skill and interaction commands | Reliable or acknowledged per command type |
| Facts | Reliable |
| Snapshots | Unreliable deltas against the last acknowledged state |
| Handoff and authority control | Reliable, ordered, with authority epochs |

## Work packages

Copied from ARCH[^arch] § Modules, work packages and the implementation contract (Platform), revision 502. Each package is one Claude Code session and one pull request inside `cpp/Transport/`.

| ID | Package | Done when | Needs | Slice |
| --- | --- | --- | --- | --- |
| PTR-1 | GameNetworkingSockets transport implementing the Engine transport interface | A client and a local server exchange reliable and unreliable messages | NET-1[^engine-network], PCT-1[^platform-contracts] | 12 |
| PTR-2 | Connect-ticket verification inside the simulation (signature, expiry, key ID) against a configured set of public keys; tickets are test-signed with a local key until PCS-1[^platform-coreservices] issues real ones | Bad or expired tickets are rejected with no service call | PTR-1 | 12 |
| PTR-3 | Candidate connections (up to three), promotion, simulation-to-simulation links | Promotion happens with no loading screen | PTR-2, DSIM-3[^engine-distributedsimulation] | 36 |
| PTR-4 | Simulation links chosen by locality: an in-memory queue in one process, a local socket or shared-memory channel on one machine, GameNetworkingSockets between machines | The same transfer test passes on every channel with identical results; the link picks its channel from the peers' placement | PTR-3 | 44+ |

## Acceptance tests

| Package | Test | Passes when |
| --- | --- | --- |
| PTR-1 | Loopback exchange | A client and a local server exchange reliable and unreliable messages through the Engine transport interface |
| PTR-1 | Engine ping and echo | The Engine's NET-1[^engine-network] ping and echo tests pass with this transport in place of the loopback transport |
| PTR-1 | Headless | The module builds and links with no graphics, UI, audio or editor library |
| PTR-1 | Standalone build | The module configures against the pinned Engine with only `Runic::NetworkTransport` (and the Core types it uses); Flecs, Jolt and the gameplay modules are not configured |
| PTR-2 | Ticket rejection | Bad-signature, wrong-simulation, expired and unknown-key-ID tickets are rejected; the test runs with no service process |
| PTR-2 | Ticket acceptance | A ticket signed with the local test key is accepted and the session opens (slice 12 runnable result) |
| PTR-2 | Key set | A ticket signed with any key in the configured set is accepted; a key removed from the set no longer verifies |
| PTR-3 | Promotion | A WorldSession promotes a candidate to Primary and drops the others with no loading screen |
| PTR-3 | Simulation links | Ghost deltas and transfer messages encoded by the Engine cross a simulation-to-simulation link; a message with a stale epoch is dropped by the Engine, not by Transport |
| PTR-4 | Links by locality | The same transfer test passes over the in-memory, local and network channels with identical results; the link picks its channel from the peers' placement |

## Contract-session items

- The exact transport interface and connect-ticket hook come from the Engine NET-1[^engine-network] contract (`Runic::NetworkTransport`); PTR-1 waits for it. The Engine commit pinned today does not provide that target yet ([../current-state.md](../current-state.md)).
- The connect-ticket fields and signature scheme are written in Contracts[^platform-contracts] (PCT-1) and implemented here in PTR-2; PCS-1[^platform-coreservices] issues tickets in the same format.
- How the configured public-key set reaches a simulation (configuration file, environment, or a load at start) is fixed in the PTR-2 contract session together with PCS-1; it is never a per-ticket service call.

<!-- obsidian-graph:start -->

---

## Connections

*Generated for the Obsidian graph. The numbered markers in the text jump to the footnotes below, which link the notes they refer to.*

- **Depends on:** [[../../../RunicEngine/docs/modules/Network|Network]] · [[../modules/Contracts|Contracts]]
- **Its packages need:** [[../../../RunicEngine/docs/modules/DistributedSimulation|DistributedSimulation]]
- **Packages that need it:** [[../modules/CoreServices|CoreServices]]
- **See also:** [[../modules/README|Platform module catalog]] · [[../../../RunicEngine/docs/system/03-dependency-rules|03 — Dependency rules]] · [[../../../RunicEngine/docs/system/12-work-packages|12 — Work packages]] · [[../current-state|Platform current state]]

[^engine-network]: [[../../../RunicEngine/docs/modules/Network|Network]] — Engine module · Networking
[^platform-contracts]: [[../modules/Contracts|Contracts]] — Platform module · Protobuf
[^arch]: #source/arch — ARCH, "RunicEngine — Technical Architecture v3": the architecture source of truth (a project document, not a note in this vault)
[^platform-coreservices]: [[../modules/CoreServices|CoreServices]] — Platform module · Go
[^engine-distributedsimulation]: [[../../../RunicEngine/docs/modules/DistributedSimulation|DistributedSimulation]] — Engine module · Networking
[^engine-core]: [[../../../RunicEngine/docs/modules/Core|Core]] — Engine module · Foundation
[^engine-simulation]: [[../../../RunicEngine/docs/modules/Simulation|Simulation]] — Engine module · Simulation core
