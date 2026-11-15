# go/ — the Platform's Go code

One Go module (`go.mod` at the repository root, module path `runic.local/platform` until the owner decides the
canonical path: RunicDocs › Architecture › Open questions), with Go's own layout: one directory per package,
`internal/` for private code, tests beside the code, the standard `testing` package. Folders are lowercase because
they are Go packages.

`platform/` is the only folder today: the bootstrap placeholder package, which leaves with the first real one.
Generated Go code from `proto/` goes to the git-ignored `go/generated/`.

## Planned folders

Not created yet: each folder appears with its first package, which takes the folder's README from the `layout` branch
(`git checkout origin/layout -- go/<folder>/README.md`; decided 2026-11-14).

| Folder | Platform module | First package |
| --- | --- | --- |
| `sdk/` | GoSDK | PSDK-1 (slice 26) |
| `services/` | CoreServices | PCS-1 (slice 27) |
| `blocks/` | BuildingBlocks | PBB-1 (slice 28) |
| `cmd/` | The executables of the services and blocks, one folder per binary | PSDK-1 (slice 26) |
