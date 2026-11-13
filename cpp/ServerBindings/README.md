# RunicPlatform::ServerBindings

Headless: yes · Packages: PBND-1, PBND-2, PBND-3, PBND-4, PBND-5

The server bindings that implement the Engine's Layer interface and the Simulation's service port: the services-bridge and lifecycle layers and the metrics exporter. They depend only on Engine interface targets (Runic::Core, Runic::Application, Runic::SimulationPort) and Contracts.

| Folder | Holds | Packages |
| --- | --- | --- |
| `Public/` | The module's API, by path under `Public/`; no library types. | every package that adds API |
| [`Source/ServicesBridge/`](Source/ServicesBridge/README.md) | The ServicesBridgeLayer: implements the Engine service port with asynchronous gRPC calls (completions queued for safe ticks) and NATS (durable facts from the outbox… | PBND-1 (slice 27), PBND-4 (slice 30) |
| [`Source/Lifecycle/`](Source/Lifecycle/README.md) | The LifecycleLayer: Agones SDK ready, health and shutdown, with a local stub mode for development without Agones. | PBND-2 (slice 39) |
| [`Source/MetricsExporter/`](Source/MetricsExporter/README.md) | The Prometheus exporter that publishes the Core metrics registry. | PBND-3 (slice 39) |
| [`Source/BehaviorSummaries/`](Source/BehaviorSummaries/README.md) | Behavior summaries from the service port published to NATS on a lossy stream; never blocks a tick. | PBND-5 (slice 39) |
| `Tests/`, `ARCHITECTURE.md`, `CMakeLists.txt` | Tests, the contract and the `runic_add_module(...)` call, from the first package. | the first package |

Every folder exists from the start (decided 2026-11-12). Sources: RunicDocs › Architecture › Repositories, build
targets and processes › Platform modules; Networking stack, sessions and responsiveness; Platform and operations
(as of 2026-11-13).
