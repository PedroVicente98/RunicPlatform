# Future shared protocols

This directory is reserved for generic infrastructure schemas once a vertical
slice needs them. Protocol Buffers, gRPC, generated bindings, and schema tooling
are intentionally deferred. There are no protocol definitions or code generation
steps in the bootstrap.

Generic coordination messages belong here; proprietary game events and their
schemas belong in RunicGame. C++ simulations remain authoritative for realtime
world state, with Go processes providing separate coordination and services.
