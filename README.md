# RunicPlatform - ADD AGONES

RunicPlatform is the public, MIT-licensed networking and distributed coordination
foundation for MMORPGs. Its C++ side will connect realtime clients directly to
authoritative C++ simulations. Its Go side will coordinate those simulations and
provide generic infrastructure as ordinary local processes first.

RunicEngine simulates the world; RunicPlatform connects and coordinates simulations;
the private RunicGame defines gameplay and content. Fabric has no dependency on
either repository and must never know proprietary gameplay rules. Future engine
integration belongs in narrow adapters. Go is outside the realtime movement and
combat path: `client -> C++ authoritative simulation`.

## Bootstrap boundaries

- `cpp/Core/` and `cpp/include/`: the dependency-free C++20 `Runic::Fabric` library.
  The version function is disposable build verification code.
- `go/fabric/`: a documentation-only Go package for future generic coordination.
- `proto/`: a placeholder for future shared infrastructure schemas.
- `tests/`: a consumer that verifies public-header inclusion and library linkage.

No transport, replication, service, gameplay, or protocol is implemented yet.
Protobuf, gRPC, NATS, PostgreSQL, Redis, and deployment tooling are deferred until
needed by a concrete slice. Kubernetes is not required. Future distributed
infrastructure events belong here; local simulation events belong in RunicEngine,
and proprietary distributed game events belong in RunicGame.

## C++ build

Requires CMake 3.24+, a C++20 compiler, and a supported native build tool.
From this repository:

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build
ctest --test-dir build --output-on-failure
```

With Ninja installed, an optional equivalent preset is available:

```sh
cmake --preset debug
cmake --build --preset debug
ctest --preset debug
```

`runic_fabric` is a static library, exposed to CMake consumers as `Runic::Fabric`.
`RUNIC_FABRIC_BUILD_TESTS` defaults to ON for a standalone build and OFF when
included with `add_subdirectory()`. RunicGame includes the sibling checkout using
its configurable `RUNIC_FABRIC_DIR` path and an explicit separate build directory.
Fabric introduces no window, renderer, editor, or Go requirement to a C++ build.

## Go build

Requires Go 1.26 or newer, as declared in `go.mod`. From this repository,
independently of CMake:

```sh
go build ./...
go test ./...
```

The bootstrap package has no tests, services, or external dependencies.
`runic.local/fabric` is a local placeholder module identity, not a published
remote. Once a public hosting path exists, update `go.mod` and imports to that
canonical module path before publishing tagged releases. A future sibling Go
consumer can use a local `go.work` file or a `replace` directive while developing;
there is currently no Go consumer or workspace requirement.

## Repository and acquisition

This is an independent Git repository beside RunicEngine and RunicGame. No remote
URL is assumed. Once a real remote exists, replace the placeholder and run:

```sh
git remote add origin <actual-RunicPlatform-remote-URL>
git push -u origin main
```

The sibling layout is the current development workflow. Later acquisition can
use tagged CMake FetchContent releases, submodules in a deliberate superproject
or dependency layout, or installed/package-manager packages once packaging is
added. No checkout duplication, fake submodule URL, or package installation/export
support is introduced by this bootstrap.
