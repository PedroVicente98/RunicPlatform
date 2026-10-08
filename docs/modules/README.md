# RunicPlatform module catalog

One contract per module. Each file follows the per-module `ARCHITECTURE.md`
contract ([system/02](../system/02-module-contract.md#the-per-module-architecturemd-contract-j33)).
When a module directory is created, its contract moves to
`<Module>/ARCHITECTURE.md` and the row below links there.

**Provenance legend.** *Purpose, Owns, Does not own, Allowed dependencies,
Primary consumers* come from Appendix J §J.5; sections marked **(derived)** and
all "Implementation" language choices are proposals until the owner confirms
them ([OQ-9](../system/11-open-questions.md#oq-9)).

| Module | Purpose (short) | Allowed dependencies | Likely language (proposal) | Phase | Status |
| --- | --- | --- | --- | --- | --- |
| [Contracts](Contracts.md) | Versioned protocol/service/event/control schemas, message IDs | — (foundation) | schemas + generated C++/Go | 4+ | Not started |
| [Realtime](Realtime.md) | Client↔sim and sim↔sim transport, sessions, connection roles | Contracts, Identity, Observability; Engine NetworkAdapter | C++ | 4 / 8 / 13 | Not started |
| [ServiceRuntime](ServiceRuntime.md) | gRPC/NATS, request context, async completion, idempotent requests | Contracts, Identity, Observability | Go (+ C++ async client) | 9 | Not started |
| [Persistence](Persistence.md) | DB adapters, transactions, migrations, locking, idempotency store | Observability | Go | 9 | Not started |
| [WorldControl](WorldControl.md) | Simulation/authority directories, partitions, handoff planning, load balancing | Contracts, Realtime control, Orchestration iface, Identity, Observability | Go | 13 / 14 | Not started |
| [Orchestration](Orchestration.md) | Agones/Kubernetes capacity and lifecycle | Observability | Go | 16 | Not started |
| [Identity](Identity.md) | Tokens, service identity, GlobalPlayerId, signing | Contracts | Go (+ C++ validation) | 4 | Not started |
| [Observability](Observability.md) | Metrics, logs, traces, health views | — | Go + C++ hooks | 16 (basic earlier) | Not started |
