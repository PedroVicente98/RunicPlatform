# ServerBindings

This file is the contract of the Platform ServerBindings module: the C++ layers a GameServer composes to reach durable services, Agones and Prometheus without the Engine knowing any of them.

| Field | Value |
| --- | --- |
| Language | C++20 |
| Directory | `cpp/ServerBindings/` with `Public/`, `Source/`, `Tests/`, `ARCHITECTURE.md`, `CMakeLists.txt` |
| CMake target | `RunicPlatform::ServerBindings` (namespace `RunicPlatform::ServerBindings`) |
| Depends on | Engine interface targets only: `Runic::Application` (Layer), `Runic::SimulationPort` (header-only service port from Simulation, SIM-5; Core types only) and `Runic::Core` (metrics registry); Platform Contracts; gRPC, NATS client, Agones SDK and Prometheus client libraries (all private) |
| Status | Not started |

When the first contract session creates `cpp/ServerBindings/`, this file's content moves into `cpp/ServerBindings/ARCHITECTURE.md` with the section list from [../system/02-module-contract.md](../system/02-module-contract.md), and this file then links to it.

## Purpose

Only the Platform may talk to gRPC, NATS and Agones; the Engine never supplies infrastructure or communication layers (ARCH § Application and LayerStack). This module supplies the server-side pieces that do, as classes that implement Engine interfaces:

| Piece | Implements | Package |
| --- | --- | --- |
| ServicesBridgeLayer | The Engine Layer interface and the Simulation's service port (SIM-5): asynchronous gRPC calls, then NATS | PBND-1 (gRPC, slice 27), PBND-4 (NATS, slice 30) |
| LifecycleLayer | The Engine Layer interface, on the Agones SDK, with a local stub mode for development without Agones | PBND-2 |
| Prometheus exporter | Publishes the Core metrics registry (CORE-2): tick-domain timings, and the network and replication metrics the Engine Diagnostics layer (NET-7) records | PBND-3 |

The GameServer (RunicGame) composes its stack bottom to top: Network (Engine) → Simulation (Engine) → Services bridge (this module) → Lifecycle (this module) → Diagnostics (Engine).

## Owns

- ServicesBridgeLayer, gRPC part (PBND-1): drains the service port's outbox of durable operations (each with a stable operation ID), sends calls that need an answer asynchronously over gRPC, and queues completions into the port's inbox, which the simulation drains at safe ticks.
- ServicesBridgeLayer, NATS part (PBND-4): publishes durable facts from the outbox, and delivers world directives (PCS-3) and other subscriptions to the inbox at safe ticks.
- The bridge's I/O threads, gRPC channels, NATS connections, retry with the same operation ID, and timeouts.
- LifecycleLayer (PBND-2): Agones SDK Ready, health pings and shutdown; the server states Starting → Ready → Draining → Shutdown as seen by Agones; and a local stub mode, so a GameServer runs in development with no Agones.
- The Prometheus exporter (PBND-3): publishes the Core metrics registry and is the only metrics endpoint of a production GameServer (ARCH § Decisions log: development endpoints).
- Bridge, lifecycle and exporter metrics of their own (queue depths, call latency, failures).

## Does not own

| Responsibility | Owner |
| --- | --- |
| The service port interface, the outbox and inbox semantics, and when results are applied | Engine `Runic::Simulation` (SIM-5) |
| The Layer interface and LayerStack | Engine `Runic::Application` (APP-1) |
| Recording metrics: tick-domain timings (Engine Simulation, SIM-1) and network and replication metrics (Engine Diagnostics layer, NET-7) | Engine |
| The Editor attach channel and debug-shape stream | Engine Diagnostics layer in `Runic::Network` (NET-7) |
| The metrics registry | Engine `Runic::Core` (CORE-2) |
| What a world directive says and when | Platform CoreServices (PCS-3) and the RunicGame service that decides it |
| Region hand-off decisions during draining | Platform CoreServices (World Coordinator) and the Engine DistributedSimulation |
| Fleets, manifests, dashboards | Platform Infrastructure |
| What an operation means, its validation and its rules | The receiving service (RunicGame or Platform) |
| Which layers a server composes, in which order | RunicGame (GameServer) |

## Depends on / never depends on

| May depend on | Never depends on |
| --- | --- |
| Engine interface targets `Runic::Application` (Layer), `Runic::SimulationPort` (service port), `Runic::Core` (metrics registry) | `Runic::Simulation`, `Runic::Network` or any other Engine module target; any Engine `Source/` folder; Flecs, Jolt or any Engine library type |
| Platform Contracts | RunicGame, in code, tests or docs |
| gRPC, a NATS client, the Agones SDK, a Prometheus client: all PRIVATE, never in `Public/` | GLFW, bgfx, RmlUi, ImGui, audio or editor code (server-only, headless) |
| — | Platform Go code |

The dependency points one way: these layers include Engine interface headers; the Engine never includes them. Because `Runic::SimulationPort` is header-only with Core types only, building and testing ServerBindings configures Core and Application and never Flecs, Jolt or the gameplay modules.

## Rules

- Do: run every network call on the bridge's own threads; the layer's OnUpdate only moves items between queues.
- Do: deliver every completion to the service port's inbox; the simulation applies it at a safe tick.
- Do: resend a timed-out operation with the same operation ID; services deduplicate by it.
- Never: block a tick, wait for a reply on the simulation thread, or touch Flecs from an I/O callback.
- Never: put gRPC, NATS, Protobuf or a database on per-tick replication, ghost or combat traffic.
- Never: interpret an operation or apply a game rule in the bridge; it carries operations and results.
- Never: expose an attach or debug endpoint; production servers expose metrics only through the exporter.

## Interfaces it implements or exposes (sketch)

Illustrative only; the Engine contracts of APP-1, SIM-5 (`Runic::SimulationPort`) and CORE-2 define the interfaces these classes implement.

```cpp
// cpp/ServerBindings/Public/ServicesBridgeLayer.hpp — illustrative, not a frozen API.
namespace RunicPlatform::ServerBindings {

struct ServicesBridgeConfig {
    std::vector<ServiceEndpoint> grpcEndpoints;  // per operation kind (PBND-1)
    std::string natsUrl;                         // facts and subscriptions (PBND-4)
    std::chrono::milliseconds callTimeout{2000};
};

// Drains the service port outbox on I/O threads; completions go to the port inbox.
class ServicesBridgeLayer final : public Runic::Layer {
public:
    ServicesBridgeLayer(Runic::Simulation::ServicePort& port, ServicesBridgeConfig config);
    void OnAttach() override;                          // start I/O threads, connect
    void OnDetach() override;                          // flush, stop threads
    void OnUpdate(const Runic::FrameTime& time) override; // move queues only; never waits
};

class LifecycleLayer final : public Runic::Layer {     // Agones SDK: Ready, health, shutdown
public:
    explicit LifecycleLayer(LifecycleConfig config);   // config selects Agones or the local stub mode
};

class PrometheusExporter {                             // publishes the Runic::Core metrics registry
public:
    PrometheusExporter(const Runic::MetricsRegistry& registry, ExporterConfig config);
};

} // namespace RunicPlatform::ServerBindings
```

```text
Simulation (Engine)                 ServicesBridgeLayer (Platform)            Service (Go)
outbox: op{id, kind, payload} ───► I/O thread: gRPC call (PBND-1)  ───────► dedupe by op id, commit
                                   I/O thread: NATS publish (PBND-4) ───────► subscribers
inbox  ◄── completion queued ◄──── result or failure                    ◄─── accepted result
inbox  ◄── directive queued  ◄──── NATS subscription (PBND-4)           ◄─── world directives (PCS-3)
applied at a later safe tick
```

## Work packages

Copied from ARCH § Modules, work packages and the implementation contract (Platform), revision 369. Each package is one Claude Code session and one pull request inside `cpp/ServerBindings/`.

| ID | Package | Done when | Needs | Slice |
| --- | --- | --- | --- | --- |
| PBND-1 | ServicesBridgeLayer: implements the Engine service port with asynchronous gRPC calls; completions queued for safe ticks | A slow service never delays a tick | PCT-1, APP-1, SIM-5 | 27 |
| PBND-2 | LifecycleLayer: Agones SDK ready, health and shutdown, plus a local stub mode for development without Agones | Against the Agones local SDK server the layer reports Ready, sends health pings and drains on shutdown; the stub mode runs with no Agones | APP-1 | 39 |
| PBND-3 | Prometheus exporter that publishes the Core metrics registry (tick-domain timings, and the network metrics the Diagnostics layer records) | A scrape returns time per tick domain in Prometheus format | CORE-2, SIM-1 | 39 |
| PBND-4 | NATS in the services bridge: durable facts published from the outbox; world directives and other subscriptions delivered to the inbox at safe ticks | A fact published from a tick reaches a test subscriber once; a slow broker never delays a tick | PBND-1, PSDK-3 | 30 |

PBND-4 is listed last because ARCH numbers it last; it is built in slice 30, before PBND-2 and PBND-3 (slice 39).

## Acceptance tests

| Package | Test | Passes when |
| --- | --- | --- |
| PBND-1 | Slow service | A test gRPC service (generated from Contracts, PCT-1) that answers late never delays a tick; the result is applied at a later safe tick |
| PBND-1 | No I/O on the tick | Completions arrive only through the port's inbox; no callback touches Flecs |
| PBND-1 | Retry | A timed-out operation is resent with the same operation ID and the service applies it once |
| PBND-1 | Headless | The module builds and links with no graphics, UI, audio or editor library |
| PBND-1 | Standalone build | The module configures against the pinned Engine with only `Runic::Core`, `Runic::Application` and `Runic::SimulationPort`; Flecs, Jolt and the gameplay modules are not configured |
| PBND-4 | Publish once | A fact published from a tick reaches a test subscriber once |
| PBND-4 | Slow broker | A slow or unavailable NATS broker never delays a tick |
| PBND-4 | Subscription | A subscribed message (for example a test directive) reaches the inbox and is applied at a later safe tick, never from the NATS callback |
| PBND-2 | Lifecycle | Against the Agones local SDK server the layer reports Ready, sends health pings and drains on shutdown |
| PBND-2 | Stub mode | With the local stub mode the server starts, runs and shuts down with no Agones |
| PBND-3 | Export | A scrape returns time per tick domain from the Core metrics registry in Prometheus format |

The fleet and Grafana checks are not ServerBindings tests: PINF-2 proves them once PBND-2 and PBND-3 are merged.

## Contract-session items

- The service port interface comes from the Engine SIM-5 contract (`Runic::SimulationPort`); PBND-1 waits for it. The Engine commit pinned today does not provide that target yet ([../current-state.md](../current-state.md)).
- The gRPC, NATS, Agones SDK and Prometheus client libraries and how they are acquired are chosen in the contract sessions of PBND-1, PBND-4, PBND-2 and PBND-3, within the dependency rules of BUILD-1.
