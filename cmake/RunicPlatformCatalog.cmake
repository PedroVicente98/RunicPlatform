# RunicPlatform C++ module catalog: the C++ rows of RunicDocs › Architecture › Repositories, build targets and
# processes › Platform modules. Platform C++ modules link only Engine interface targets.
# Third parties are library IDs mapped to targets by the package that adds each library; all stay PRIVATE.
# Go modules (Go SDK, Core services, Building blocks) and Infrastructure are not CMake targets.
# Changing a row is an owner decision recorded in ARCH first; checks.catalog_sync keeps this file equal to 03.

set(RUNIC_MODULE_NAMESPACE RunicPlatform)

runic_catalog_module(Contracts
    GROUP Platform
    THIRD_PARTY protobuf
    HEADLESS yes)
runic_catalog_module(Transport
    GROUP Platform
    ALLOWS Runic::NetworkTransport RunicPlatform::Contracts
    THIRD_PARTY gns ticket-signature
    HEADLESS yes)
runic_catalog_module(ServerBindings
    GROUP Platform
    ALLOWS Runic::Core Runic::Application Runic::SimulationPort RunicPlatform::Contracts
    THIRD_PARTY grpc nats agones prometheus
    HEADLESS yes)
