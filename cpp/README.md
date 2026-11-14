# cpp/ — the Platform's C++ modules

Each C++ module has the module shape of the three repositories (`README.md`, `ARCHITECTURE.md`, `CMakeLists.txt`,
`Public/`, `Source/<Subsystem>/`, `Tests/`) and a target `RunicPlatform::<Module>`.

| Folder | Target | First package |
| --- | --- | --- |
| [`Transport/`](Transport/README.md) | `RunicPlatform::Transport` | PTR-1 (slice 12) |
| [`ServerBindings/`](ServerBindings/README.md) | `RunicPlatform::ServerBindings` | PBND-1 (slice 27) |

Contracts (the Protobuf schemas) live in [`proto/`](../proto/README.md); their generated C++ goes to the git-ignored
`cpp/generated/`.

The bootstrap target `Runic::Platform` (`cpp/Core/`, `cpp/include/`) was removed in slice 1 (decision D1), once
RunicGame stopped linking it; Contracts (PCT-1, slice 12) is the first C++ module.
