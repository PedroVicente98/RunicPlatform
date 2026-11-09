# BUILD-1 acceptance tests for RunicPlatform (contract: docs/build/BUILD-1.md; canonical contract in
# RunicEngine docs/build/BUILD-1.md). They use the drivers and check scripts of the pinned Engine.
#
# Added by the Platform when RUNIC_PLATFORM_BUILD_TESTS is ON, or run on their own:
#   cmake -S tests/build -B build/build-tests -G Ninja [-DRUNIC_ENGINE_DIR=../RunicEngine]
#   ctest --test-dir build/build-tests

cmake_minimum_required(VERSION 3.24)
get_filename_component(RUNIC_PLATFORM_SOURCE "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    project(RunicPlatformBuildTests LANGUAGES NONE)
    enable_testing()
    if(EXISTS "${RUNIC_PLATFORM_SOURCE}/external/RunicEngine/CMakeLists.txt")
        set(_engine_default "${RUNIC_PLATFORM_SOURCE}/external/RunicEngine")
    else()
        set(_engine_default "${RUNIC_PLATFORM_SOURCE}/../RunicEngine")
    endif()
    set(RUNIC_ENGINE_DIR "${_engine_default}" CACHE PATH "RunicEngine source tree")
endif()
get_filename_component(RUNIC_BUILD_TESTS_ENGINE "${RUNIC_ENGINE_DIR}" ABSOLUTE
    BASE_DIR "${RUNIC_PLATFORM_SOURCE}")

set(DRIVERS "${RUNIC_BUILD_TESTS_ENGINE}/tests/build")
set(CHECKS "${RUNIC_BUILD_TESTS_ENGINE}/cmake/checks")
set(WORK "${CMAKE_CURRENT_BINARY_DIR}/work")

# The standalone Platform build: configures the Engine helpers and never Flecs, GLM, Jolt or Godot;
# the deferred link checks run.
add_test(NAME build.platform_standalone
    COMMAND "${CMAKE_COMMAND}"
        "-DFIXTURE=${RUNIC_PLATFORM_SOURCE}"
        "-DWORK=${WORK}/platform_standalone"
        "-DENGINE=${RUNIC_BUILD_TESTS_ENGINE}"
        "-DEXPECT=pass"
        "-DEXPECT_REGEX=RUNIC: link checks passed"
        "-DARGS=-DRUNIC_PLATFORM_BUILD_TESTS=OFF"
        "-DABSENT=_deps/flecs-build|_deps/glm-build|_deps/jolt-build|godot-cpp|godot"
        "-DGENERATOR=${CMAKE_GENERATOR}"
        -P "${DRIVERS}/RunFixture.cmake")

# The bootstrap smoke test runs as a GoogleTest test discovered by CTest.
add_test(NAME build.platform_bootstrap_gtest
    COMMAND "${CMAKE_COMMAND}"
        "-DFIXTURE=${RUNIC_PLATFORM_SOURCE}"
        "-DWORK=${WORK}/platform_bootstrap_gtest"
        "-DENGINE=${RUNIC_BUILD_TESTS_ENGINE}"
        "-DEXPECT=pass"
        "-DARGS=-DRUNIC_PLATFORM_BUILD_TESTS=ON"
        "-DTEST_REGEX=PlatformBootstrap\\.Version"
        "-DGENERATOR=${CMAKE_GENERATOR}"
        -P "${DRIVERS}/RunFixture.cmake")
set_tests_properties(build.platform_standalone build.platform_bootstrap_gtest PROPERTIES LABELS build)

# The catalog equals the Platform rows of docs/system/03; the repository passes both scans.
add_test(NAME checks.catalog_sync
    COMMAND "${CMAKE_COMMAND}"
        "-DSCRIPT=${CHECKS}/CatalogSync.cmake" "-DEXPECT=pass"
        "-DARGS=-DCATALOG=${RUNIC_PLATFORM_SOURCE}/cmake/RunicPlatformCatalog.cmake|-DDOCS=${RUNIC_PLATFORM_SOURCE}/docs/system/03-dependency-rules.md|-DTABLE=platform"
        -P "${DRIVERS}/RunScript.cmake")
add_test(NAME checks.public_header_scan
    COMMAND "${CMAKE_COMMAND}"
        "-DSCRIPT=${CHECKS}/PublicHeaderScan.cmake" "-DEXPECT=pass"
        "-DARGS=-DROOT=${RUNIC_PLATFORM_SOURCE}|-DCATALOG=${RUNIC_PLATFORM_SOURCE}/cmake/RunicPlatformCatalog.cmake"
        -P "${DRIVERS}/RunScript.cmake")
add_test(NAME checks.source_include_scan
    COMMAND "${CMAKE_COMMAND}"
        "-DSCRIPT=${CHECKS}/SourceIncludeScan.cmake" "-DEXPECT=pass"
        "-DARGS=-DROOT=${RUNIC_PLATFORM_SOURCE}"
        -P "${DRIVERS}/RunScript.cmake")
add_test(NAME checks.workflow_pins
    COMMAND "${CMAKE_COMMAND}"
        "-DSCRIPT=${CHECKS}/WorkflowPinCheck.cmake" "-DEXPECT=pass"
        "-DARGS=-DROOT=${RUNIC_PLATFORM_SOURCE}"
        -P "${DRIVERS}/RunScript.cmake")
set_tests_properties(checks.catalog_sync checks.public_header_scan checks.source_include_scan checks.workflow_pins
    PROPERTIES LABELS checks)
