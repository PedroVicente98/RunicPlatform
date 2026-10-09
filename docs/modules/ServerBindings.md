# ServerBindings

This file is the contract of the Platform ServerBindings module: the C++ layers a GameServer composes to reach durable services, Agones and Prometheus without the Engine knowing any of them.

| Field | Value |
| --- | --- |
| Language | C++20 |
| Directory | `cpp/ServerBindings/` with `Public/`, `Source/`, `Tests/`, `ARCHITECTURE.md`, `CMakeLists.txt` |
| CMake target | `RunicPlatform::ServerBindings` (namespace `RunicPlatform::ServerBindings`) |
| Depends on | Engine public headers of `Runic::Application` (Layer), `Runic::Simulation` (service port) and `Runic::Core` (metrics registry); Platform Contracts; gRPC, NATS client, Agones SDK and Prometheus client libraries (all private) |
| Status | Not started |

When the first contract session creates `cpp/ServerBindings/`, this file's content moves into `cpp/ServerBindings/ARCHITECTURE.md` with the section list from [../system/02-module-contract.md](../system/02-module-contract.md), and this file then links to it.

## Purpose

Only the Platform may talk to gRPC, NATS and Agones; the Engine never supplies infrastructure or communication layers (ARCH § Application and LayerStack). This module supplies the server-side pieces that do, as classes that implement Engine interfaces:

| Piece | Implements | Package |
| --- | --- | --- |
| ServicesBridgeLayer | The Engine Layer interface and the Simulation's service port (SIM-5) | PBND-1 |
| LifecycleLayer | The Engine Layer interface, on the Agones SDK | PBND-2 |
| Prometheus exporter | Publishes the metrics the Engine Diagnostics layer collects (NET-7) from the Core metrics registry | PBND-3 |

The GameServer (RunicGame) composes its stack bottom to top: Network (Engine) → Simulation (Engine) → Services bridge (this module) → Lifecycle (this module) → Diagnostics (Engine).

## Owns

- ServicesBridgeLayer: drains the service port's outbox of durable operations (each with a stable operation ID), sends them asynchronously over gRPC (calls that need an answer) or NATS (publish with no answer), and queues completions into the port's inbox, which the simulation drains at safe ticks.
- The bridge's I/O threads, gRPC channels, NATS connections, retry with the same operation ID, and timeouts.
- LifecycleLayer: Agones SDK Ready, health pings and shutdown; the server states Starting → Ready → Draining → Shutdown as seen by Agones.
- The Prometheus exporter: the only metrics endpoint of a production GameServer (ARCH § Decisions log: development endpoints).
- Bridge, lifecycle and exporter metrics of their own (queue depths, call latency, failures).

## Does not own

| Responsibility | Owner |
| --- | --- |
| The service port interface, the outbox and inbox semantics, and when results are applied | Engine `Runic::Simulation` (SIM-5) |
| The Layer interface and LayerStack | Engine `Runic::Application` (APP-1) |
| Collecting simulation metrics; the Editor attach channel | Engine Diagnostics layer in `Runic::Network` (NET-7) |
| The metrics registry | Engine `Runic::Core` (CORE-2) |
| Region hand-off decisions during draining | Platform CoreServices (World Coordinator) and the Engine DistributedSimulation |
| Fleets, manifests, dashboards | Platform Infrastructure |
| What an operation means, its validation and its rules | The receiving service (RunicGame or Platform) |
| Which layers a server composes, in which order | RunicGame (GameServer) |

## Depends on / never depends on

| May depend on | Never depends on |
| --- | --- |
| Public headers of `Runic::Application` (Layer), `Runic::Simulation` (service port), `Runic::Core` (metrics registry) | Any Engine `Source/` folder; Flecs, Jolt or any Engine library type |
| Platform Contracts | RunicGame, in code, tests or docs |
| gRPC, a NATS client, the Agones SDK, a Prometheus client: all PRIVATE, never in `Public/` | GLFW, bgfx, RmlUi, ImGui, audio or editor code (server-only, headless) |
| — | Platform Go code |

The dependency points one way: these layers include Engine interface headers; the Engine never includes them.

## Rules

- Do: run every network call on the bridge's own threads; the layer's OnUpdate only moves items between queues.
- Do: deliver every completion to the service port's inbox; the simulation applies it at a safe tick.
- Do: resend a timed-out operation with the same operation ID; services deduplicate by it.
- Never: block a tick, wait for a reply on the simulation thread, or touch Flecs from an I/O callback.
- Never: put gRPC, NATS or a database on per-tick replication, ghost or combat traffic.
- Never: interpret an operation or apply a game rule in the bridge; it carries operations and results.
- Never: expose an attach or debug endpoint; production servers expose metrics only through the exporter.

## Interfaces it implements or exposes (sketch)

Illustrative only; the Engine contracts of APP-1, SIM-5 and CORE-2 define the interfaces these classes implement.

```cpp
// cpp/ServerBindings/Public/ServicesBridgeLayer.hpp — illustrative, not a frozen API.
namespace RunicPlatform::ServerBindings {

struct ServicesBridgeConfig {
    std::vector<ServiceEndpoint> grpcEndpoints;  // per operation kind
    std::string natsUrl;
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
    explicit LifecycleLayer(LifecycleConfig config);   // a local stub mode for development
};

class PrometheusExporter {                             // reads Runic::Core metrics registry
public:
    PrometheusExporter(const Runic::MetricsRegistry& registry, ExporterConfig config);
};

} // namespace RunicPlatform::ServerBindings
```

```text
Simulation (Engine)                 ServicesBridgeLayer (Platform)            Service (Go)
outbox: op{id, kind, payload} ───► I/O thread: gRPC call / NATS publish ───► dedupe by op id, commit
inbox  ◄── completion queued ◄──── result or failure                    ◄─── accepted result
applied at a later safe tick
```

## Work packages

Copied from ARCH § Modules, work packages and the implementation contract (Platform). Each package is one Claude Code session and one pull request inside `cpp/ServerBindings/`.

| ID | Package | Done when | Needs | Slice |
| --- | --- | --- | --- | --- |
| PBND-1 | ServicesBridgeLayer: implements the Engine service port with asynchronous gRPC and NATS; completions queued for safe ticks | A slow service never delays a tick | PSDK-1, APP-1, SIM-5 | 27 |
| PBND-2 | LifecycleLayer: Agones SDK ready, health and shutdown | The fleet marks the server Ready and drains it cleanly | APP-1 | 39 |
| PBND-3 | Prometheus exporter that publishes the metrics the Engine Diagnostics layer collects | Grafana shows time per tick domain | CORE-2, NET-7 | 39 |

## Acceptance tests

| Package | Test | Passes when |
| --- | --- | --- |
| PBND-1 | Slow service | A sample service (built on PSDK-1) that answers late never delays a tick; the result is applied at a later safe tick |
| PBND-1 | No I/O on the tick | Completions arrive only through the port's inbox; no callback touches Flecs |
| PBND-1 | Retry | A timed-out operation is resent with the same operation ID and the service applies it once |
| PBND-1 | Headless | The module builds and links with no graphics, UI, audio or editor library |
| PBND-2 | Lifecycle | The fleet marks the server Ready and drains it cleanly; with the local stub, the server starts with no Agones |
| PBND-3 | Export | Time per tick domain from the Core metrics registry appears in Prometheus and in Grafana |

## Open items

- PBND-1 talks NATS in slice 27, while the Go-side NATS wiring (PSDK-3) arrives in slice 30. The PBND-1 contract session decides whether slice 27 needs only the gRPC path.
- PBND-1 needs PSDK-1, a Go package, presumably as the sample service its tests call; the contract session confirms how a C++ test starts that service.
- PBND-2 is tested against a fleet, but the fleet manifests come from PINF-2, which needs PBND-2. The PBND-2 tests can use the Agones local SDK server; PINF-2 then proves the fleet.
- PBND-3 is done when Grafana shows the metric, but the dashboards come from PINF-2, which needs PBND-3. Same resolution as above.
- ARCH asks for a local lifecycle stub for gameplay work without Kubernetes (ARCH § Platform and operations: local development) but assigns it to no package; proposal: PBND-2 provides it.
- The catalog lists `Runic::Core` (metrics registry) as the exporter's input while PBND-3 needs NET-7 (Diagnostics layer, in `Runic::Network`). The PBND-3 contract session confirms which Engine header the exporter reads.
