# Transport

This file is the contract of the Platform Transport module: the GameNetworkingSockets implementation of the Engine transport interface, connect-ticket checks and the connection set behind a player's WorldSession.

| Field | Value |
| --- | --- |
| Language | C++20 |
| Directory | `cpp/Transport/` with `Public/`, `Source/`, `Tests/`, `ARCHITECTURE.md`, `CMakeLists.txt` |
| CMake target | `RunicPlatform::Transport` (namespace `RunicPlatform::Transport`) |
| Depends on | Engine `Runic::Network` public interface (transport interface, connect-ticket hook); Platform Contracts; GameNetworkingSockets (private) |
| Status | Not started |

When the first contract session creates `cpp/Transport/`, this file's content moves into `cpp/Transport/ARCHITECTURE.md` with the section list from [../system/02-module-contract.md](../system/02-module-contract.md), and this file then links to it.

## Purpose

Carry bytes between processes on the realtime path. Clients talk directly to their simulation, and neighbor simulations talk directly to each other, through the Engine's transport interface. This module is the Platform's implementation of that interface on GameNetworkingSockets: reliable and unreliable messages, encryption and congestion control over UDP (ARCH § Networking: stack, sessions and responsiveness).

## Owns

- The GameNetworkingSockets implementation of the Engine transport interface (PTR-1), for client ↔ simulation and simulation ↔ simulation connections.
- GameNetworkingSockets setup, threads, sockets and connection handles, all hidden in `Source/`.
- Delivery classes the Engine asks for: unreliable sequenced, reliable, reliable ordered.
- Connect-ticket verification inside the simulation process (PTR-2): signature and expiry, checked locally with no service call. Until PCS-1 issues real tickets (slice 27), tickets are test-signed with a local key (from slice 12).
- The connection set behind one WorldSession (PTR-3): one authoritative connection plus up to three candidate connections near borders, promotion with no loading screen, and the connection roles Primary, WarmCandidate, Dormant and Retiring.
- Simulation-to-simulation links (PTR-3) that carry the ghost deltas and transfer messages the Engine encodes.
- Per-connection statistics (bytes, loss, round-trip time) reported through the Engine transport interface, so the Engine's Diagnostics layer can collect them (proposal; the NET-1 contract decides the shape).

## Does not own

| Responsibility | Owner |
| --- | --- |
| Wire encoding: snapshots, quantization, deltas, ghost deltas, transfer messages | Engine `Runic::Network` |
| Ingress and egress queues, the Network layer, interest, priority budgets, prediction and reconciliation | Engine `Runic::Network` |
| Authority state, epochs, ghost state, transfer protocol, foreign interactions | Engine `Runic::DistributedSimulation` |
| Which simulations are handoff candidates for a border | Platform CoreServices (World Coordinator, PCS-2) |
| Issuing connect tickets, accounts, entitlements | Platform CoreServices (PCS-1) |
| Envelope and service message definitions | Platform Contracts |
| Game messages and any game rule | RunicGame |

Transport carries bytes. It never decides what a message means, who is authoritative, or what a player may do.

## Depends on / never depends on

| May depend on | Never depends on |
| --- | --- |
| Public headers of `Runic::Network` (transport interface, connect-ticket hook) | Any Engine `Source/` folder; any other Engine module's internals |
| Platform Contracts (`RunicPlatform::Contracts`; PTR-1 needs PCT-1) | RunicGame, in code, tests or docs |
| GameNetworkingSockets, linked PRIVATE and never visible in `Public/` | gRPC, NATS, databases, Agones: nothing of these on the realtime path |
| A signature library for tickets, linked PRIVATE (chosen in the PTR-2 contract session) | Platform Go code; GLFW, bgfx, RmlUi, ImGui, audio or editor code (the module is headless and also links into the client) |

The dependency points one way: Transport includes Engine interface headers; the Engine never includes Transport.

## Rules

- Do: implement exactly the Engine transport interface as NET-1 defines it; report any change it needs to the Engine instead of working around it.
- Do: run network I/O on Transport's own threads and only enqueue into the Engine's ingress queues; read egress from the Engine's queues.
- Do: verify connect tickets locally (signature, expiry) before any other message from that connection is accepted.
- Never: call the simulation thread, touch Flecs or block a tick from an I/O callback.
- Never: add a broker, a service call or a database lookup to per-tick traffic, ticket checks included.
- Never: let a GameNetworkingSockets type appear in a public header.
- Never: let gameplay code see addresses; the WorldSession stays the same while connections change.

## Interfaces it implements or exposes (sketch)

Illustrative only; the Engine's NET-1 contract session defines the real transport interface, and PTR-1 implements it.

```cpp
// cpp/Transport/Public/GnsTransport.hpp — illustrative, not a frozen API.
namespace RunicPlatform::Transport {

struct GnsTransportConfig {
    std::uint16_t listenPort = 0;         // 0 on clients
    std::uint32_t ioThreads  = 1;
};

// Implements the Engine transport interface; GameNetworkingSockets stays in Source/.
std::unique_ptr<Runic::Network::Transport> CreateGnsTransport(const GnsTransportConfig& config);

// Implements the Engine connect-ticket hook (PTR-2): signature and expiry only, no service call.
class TicketVerifier final : public Runic::Network::ConnectTicketHook {
public:
    explicit TicketVerifier(TicketKeySet keys);           // local test key until PCS-1
    TicketCheck Verify(std::span<const std::byte> ticket, WallClockTime now) const override;
};

// PTR-3: the connection set behind one WorldSession.
enum class ConnectionRole { Primary, WarmCandidate, Dormant, Retiring };

} // namespace RunicPlatform::Transport
```

Control operations on the connection set (PTR-3): prepare, wake, promote, sleep, retire, drop. The Platform tells the client which to apply; gameplay code never reasons about addresses (ARCH § Networking: replication, interest and handoff).

| Traffic it carries | Delivery |
| --- | --- |
| Movement input and transform state | Unreliable, sequenced; the latest wins |
| Skill and interaction commands | Reliable or acknowledged per command type |
| Facts | Reliable |
| Snapshots | Unreliable deltas against the last acknowledged state |
| Handoff and authority control | Reliable, ordered, with authority epochs |

## Work packages

Copied from ARCH § Modules, work packages and the implementation contract (Platform). Each package is one Claude Code session and one pull request inside `cpp/Transport/`.

| ID | Package | Done when | Needs | Slice |
| --- | --- | --- | --- | --- |
| PTR-1 | GameNetworkingSockets transport implementing the Engine transport interface | A client and a local server exchange reliable and unreliable messages | NET-1, PCT-1 | 12 |
| PTR-2 | Connect-ticket verification inside the simulation (signature and expiry); tickets are test-signed with a local key until PCS-1 issues real ones | Bad or expired tickets are rejected with no service call | PTR-1 | 12 |
| PTR-3 | Candidate connections (up to three), promotion, simulation-to-simulation links | Promotion happens with no loading screen | PTR-2, DSIM-3 | 36 |

## Acceptance tests

| Package | Test | Passes when |
| --- | --- | --- |
| PTR-1 | Loopback exchange | A client and a local server exchange reliable and unreliable messages through the Engine transport interface |
| PTR-1 | Engine ping and echo | The Engine's NET-1 ping and echo tests pass with this transport in place of the loopback transport |
| PTR-1 | Headless | The module builds and links with no graphics, UI, audio or editor library |
| PTR-2 | Ticket rejection | Bad-signature, wrong-simulation and expired tickets are rejected; the test runs with no service process |
| PTR-2 | Ticket acceptance | A ticket signed with the local test key is accepted and the session opens (slice 12 runnable result) |
| PTR-3 | Promotion | A WorldSession promotes a candidate to Primary and drops the others with no loading screen |
| PTR-3 | Simulation links | Ghost deltas and transfer messages encoded by the Engine cross a simulation-to-simulation link; a message with a stale epoch is dropped by the Engine, not by Transport |

## Open items

- The exact transport interface and connect-ticket hook come from the Engine NET-1 contract; PTR-1 waits for it.
- The ticket format (fields, signature scheme, key rotation) is not fixed in ARCH. The PTR-2 contract session proposes it in Contracts, and PCS-1 must issue tickets in the same format.
- How a simulation receives the public key that verifies real tickets after PCS-1 is not specified in ARCH.
- ARCH says Protobuf defines the realtime envelope while the Engine Network owns all wire encoding; whether Transport wraps Engine-encoded payloads in a Contracts envelope is settled in the PCT-1 and PTR-1 contract sessions.
- `Runic::Network` itself depends on Application, Simulation, DistributedSimulation, Gameplay and Perception. Building Transport tests against the pinned Engine therefore configures those modules too; the PTR-1 contract session confirms that only the interface headers are needed.
