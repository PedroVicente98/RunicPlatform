# RunicPlatform::Transport

Headless: yes · Packages: PTR-1, PTR-2, PTR-3, PTR-4

The GameNetworkingSockets implementation of the Engine's transport interface (`Runic::NetworkTransport`): connect-ticket checks, authoritative and candidate connections, simulation-to-simulation links chosen by locality.

| Folder | Holds | Packages |
| --- | --- | --- |
| `Public/` | The module's API, by path under `Public/`; no library types. | every package that adds API |
| [`Source/GameNetworkingSockets/`](Source/GameNetworkingSockets/README.md) | The GameNetworkingSockets transport implementing the Engine transport interface (GameNetworkingSockets stays private). | PTR-1 (slice 12) |
| [`Source/ConnectTickets/`](Source/ConnectTickets/README.md) | Connect-ticket verification inside the simulation: signature, expiry and key ID against a configured set of public keys (test-signed with a local key until PCS-1). | PTR-2 (slice 12) |
| [`Source/CandidateConnections/`](Source/CandidateConnections/README.md) | Up to three candidate connections and their promotion during handoff. | PTR-3 (slice 36) |
| [`Source/SimulationLinks/`](Source/SimulationLinks/README.md) | Simulation-to-simulation links, chosen by locality: an in-memory queue in one process, a local socket or shared memory on one machine… | PTR-3 (slice 36), PTR-4 (slice 44+) |
| `Tests/`, `ARCHITECTURE.md`, `CMakeLists.txt` | Tests, the contract and the `runic_add_module(...)` call, from the first package. | the first package |

Every folder exists from the start (decided 2026-11-12). Sources: RunicDocs › Architecture › Repositories, build
targets and processes › Platform modules; Networking stack, sessions and responsiveness; Platform and operations
(as of 2026-11-13).
