# infra/ — Infrastructure

The Platform's infrastructure as configuration: the local development stack, Agones fleets, Kubernetes manifests,
dashboards and the edge. Nothing here is a build target.

| Folder | Holds | Packages |
| --- | --- | --- |
| [`local/`](local/README.md) | The local development stack (PostgreSQL, NATS) started by one command; the Run button keeps it up | PINF-1 (slice 26) |
| [`agones/`](agones/README.md) | Agones fleets for the simulations and instances | PINF-2 (slice 39) |
| [`kubernetes/`](kubernetes/README.md) | Kubernetes manifests | PINF-2 (slice 39) |
| [`monitoring/`](monitoring/README.md) | Prometheus and Grafana dashboards | PINF-2 (slice 39) |
| [`edge/`](edge/README.md) | Edge and DDoS protection | PINF-3 (slice 44+) |

Sources: RunicDocs › Architecture › Platform and operations (as of 2026-11-13).
