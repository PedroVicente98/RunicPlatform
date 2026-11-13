# go/ — the Platform's Go code

One Go module (`go.mod` at the repository root, module path `runic.local/platform` until the owner decides the
canonical path: RunicDocs › Architecture › Open questions), with Go's own layout: one directory per package,
`internal/` for private code, tests beside the code, the standard `testing` package. Folders are lowercase because
they are Go packages.

| Folder | Platform module | First package |
| --- | --- | --- |
| [`sdk/`](sdk/README.md) | GoSDK | PSDK-1 (slice 26) |
| [`services/`](services/README.md) | CoreServices | PCS-1 (slice 27) |
| [`blocks/`](blocks/README.md) | BuildingBlocks | PBB-1 (slice 28) |
| [`cmd/`](cmd/README.md) | The executables of the services and blocks, one folder per binary | PSDK-1 (slice 26) |

Generated Go code from `proto/` goes to the git-ignored `go/generated/`. `go/platform/` is the bootstrap placeholder
package and leaves with the first real one.
