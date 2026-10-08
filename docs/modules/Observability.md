# Observability

> **Contract seed.** When the `Observability/` module is created, copy this file
> to `Observability/ARCHITECTURE.md`; from then on that file is authoritative.
> Purpose, Owns, Does not own, Allowed dependencies, and Primary consumers come
> from Appendix J §J.5.8. Other sections are derived and are proposals until
> confirmed.

| Field | Value |
| --- | --- |
| Directory | `Observability/` |
| Implementation | Go + C++ hooks (proposal, [OQ-9](../system/11-open-questions.md#oq-9)) |
| Roadmap phase | 16 — production orchestration (basic logging/metrics may land earlier when a module needs them) |
| Status | Not started |

## Purpose

Shared operational telemetry and diagnostics infrastructure.

## Owns

- Metrics.
- Structured logs.
- Traces.
- Dashboard/export hooks.
- Service/simulation operational health views.

## Does not own

Gameplay analytics policy, unless explicitly built as a Game service.

## Allowed dependencies

May be depended on by every Platform module without creating gameplay
dependencies. It depends on no other Platform module.

## Forbidden dependencies

RunicGame; RunicEngine (Engine's Core logging hooks are bridged to Observability
by the executable, not by a library dependency).

## Primary consumers

All Platform modules; RunicGame server and service executables.

## Threading model (derived)

Emission from a simulation thread must be non-blocking (buffered, exported
off-thread) so telemetry never delays a tick. [J.7.2]

## Acceptance tests (Stage A, derived)

- [ ] Structured log with context fields.
- [ ] Counter/histogram metrics exported.
- [ ] Trace context propagates across a ServiceRuntime call.
- [ ] Simulation tick-duration metric recorded without blocking the tick.

## Open questions

- Telemetry stack (e.g. OpenTelemetry/Prometheus) not chosen.
