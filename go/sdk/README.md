# go/sdk/ — GoSDK

Packages: PSDK-1, PSDK-2, PSDK-3

The Go SDK every service is built on: the service skeleton, configuration, gRPC and NATS wiring, persistence, transactions, migrations, the idempotency store, metrics.

| Package | Holds | Packages |
| --- | --- | --- |
| [`service/`](service/README.md) | The service skeleton: start-up, shutdown, health. | PSDK-1 (slice 26) |
| [`config/`](config/README.md) | Service configuration. | PSDK-1 (slice 26) |
| [`rpc/`](rpc/README.md) | gRPC wiring for calls that need an answer. | PSDK-1 (slice 26) |
| [`metrics/`](metrics/README.md) | Service metrics for Prometheus. | PSDK-1 (slice 26) |
| [`store/`](store/README.md) | Persistence on PostgreSQL and transactions. | PSDK-2 (slice 26) |
| [`migrate/`](migrate/README.md) | Schema migrations. | PSDK-2 (slice 26) |
| [`idempotency/`](idempotency/README.md) | The idempotency store: an operation with a stable ID applies once. | PSDK-2 (slice 26) |
| [`messaging/`](messaging/README.md) | NATS wiring: publish, subscribe, JetStream where replay is needed. | PSDK-3 (slice 30) |

`go/sdk/ARCHITECTURE.md` (the contract) is written by the first package. Sources: RunicDocs › Architecture ›
Repositories, build targets and processes › Platform modules; Platform and operations (as of 2026-11-13).
