# go/services/ — CoreServices

Packages: PCS-1, PCS-2, PCS-3, PCS-4, PCS-5, PCS-6, PCS-7

The core services every game shares: accounts and entitlements, the World Coordinator, world directives, instance allocation, chat and party groups, admission.

| Package | Holds | Packages |
| --- | --- | --- |
| [`accounts/`](accounts/README.md) | Accounts and entitlements, GlobalPlayerId issue, login, connect tickets signed with rotating keys whose public halves the simulations load. | PCS-1 (slice 27) |
| [`worldcoordinator/`](worldcoordinator/README.md) | The World Coordinator: worlds and the region map, neighbor topology, handoff candidates, the world epoch, and placement by load and traffic over Agones. | PCS-2 (slice 36), PCS-7 (slice 44+) |
| [`directives/`](directives/README.md) | World directives with an effective time and a duration (weather, wind and current events). | PCS-3 (slice 43) |
| [`instances/`](instances/README.md) | Instance allocation from Agones fleets. | PCS-4 (slice 44+) |
| [`chat/`](chat/README.md) | Chat and party groups. | PCS-5 (slice 44+) |
| [`admission/`](admission/README.md) | Admission: per-world capacity limits, the login queue and cohort waves for the launch phases. | PCS-6 (slice 44+) |

`go/services/ARCHITECTURE.md` (the contract) is written by the first package. Sources: RunicDocs › Architecture ›
Repositories, build targets and processes › Platform modules; Platform and operations (as of 2026-11-13).
