# RunicPlatform. Its part of the BUILD-1 build skeleton: cmake/README.md (slice 0).
cmake_minimum_required(VERSION 3.24)
project(RunicPlatform VERSION 0.1.0 LANGUAGES CXX)

# Tells a superproject (RunicGame) that the Platform is configured, so it is added once.
set_property(GLOBAL PROPERTY RUNIC_PLATFORM_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")

option(RUNIC_PLATFORM_BUILD_TESTS "RunicPlatform tests (GoogleTest) and the BUILD-1 acceptance tests" ${PROJECT_IS_TOP_LEVEL})

# ---- RunicEngine: the helpers and the interface targets the C++ bindings link ----------------------------------
# CI and standalone builds use the submodule pinned at external/RunicEngine; daily work points RUNIC_ENGINE_DIR at a
# sibling checkout. A superproject that already added the Engine (RunicGame adds it first) owns Engine resolution:
# this block then does nothing and never touches its cache. The standalone build turns the bundles, the Engine's
# tests, its tools and Godot off, and configures only the Engine modules the Platform links (RUNIC_ENGINE_MODULES:
# none yet), so it configures the helpers and never Flecs, GLM, Jolt or Godot. The first Platform package that links
# Runic::Core, Runic::Application or an interface target names it there; a third party those modules link (GLM for
# Core) is then fetched by need (BUILD-2).
get_property(_runic_engine_added GLOBAL PROPERTY RUNIC_ENGINE_SOURCE_DIR SET)
if(NOT _runic_engine_added)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/external/RunicEngine/CMakeLists.txt")
        set(_runic_platform_engine_default "${CMAKE_CURRENT_SOURCE_DIR}/external/RunicEngine")
    else()
        set(_runic_platform_engine_default "${CMAKE_CURRENT_SOURCE_DIR}/../RunicEngine")
    endif()
    set(RUNIC_ENGINE_DIR "${_runic_platform_engine_default}"
        CACHE PATH "Path to the RunicEngine source tree (default: external/RunicEngine if populated, else ../RunicEngine)")
    get_filename_component(RUNIC_ENGINE_DIR "${RUNIC_ENGINE_DIR}" ABSOLUTE BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    if(NOT EXISTS "${RUNIC_ENGINE_DIR}/cmake/RunicModule.cmake")
        message(FATAL_ERROR
            "RunicEngine with the BUILD-1 helpers was not found at '${RUNIC_ENGINE_DIR}'.\n"
            "Fetch the pinned submodule (git submodule update --init external/RunicEngine) or pass "
            "-DRUNIC_ENGINE_DIR=/path/to/RunicEngine (the *-siblings presets use ../RunicEngine).")
    endif()
    set(RUNIC_ENGINE_BUILD_TESTS OFF CACHE BOOL "The Engine's own tests run in the Engine")
    set(RUNIC_ENGINE_BUILD_TOOLS OFF CACHE BOOL "No RunicEditor in the Platform")
    set(RUNIC_ENGINE_ENABLE_PRESENTATION OFF CACHE BOOL "The Platform never links Godot")
    set(RUNIC_ENGINE_MODULES "" CACHE STRING "The Engine modules the Platform links (none yet)")
    add_subdirectory("${RUNIC_ENGINE_DIR}" "${CMAKE_BINARY_DIR}/dependencies/engine")
endif()
unset(_runic_engine_added)

list(APPEND CMAKE_MODULE_PATH "${RUNIC_ENGINE_DIR}/cmake")
include(RunicModule)
set(RUNIC_MODULE_NAMESPACE RunicPlatform)
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunicPlatformCatalog.cmake")
if(RUNIC_PLATFORM_BUILD_TESTS)
    runic_enable_tests()
endif()

# ---- C++ modules: cpp/<Module>/ and proto/ (Contracts) -------------------------------------------------------------
# Modules from the catalog (BUILD-2): each joins the build when its first package (PCT-1, PTR-1, PBND-1) adds its
# CMakeLists.txt; no package edits this file for it.
runic_add_catalog_modules(ROOT cpp LAYOUT NAME FOLDERS Contracts=proto)

# The bootstrap target Runic::Platform went with slice 1 (decision D1), once RunicGame stopped linking it; the first
# C++ module is Contracts (PCT-1, slice 12).

# ---- Tests ------------------------------------------------------------------------------------------------------
if(RUNIC_PLATFORM_BUILD_TESTS)
    # BUILD-1 acceptance tests (contract: cmake/README.md).
    if(PROJECT_IS_TOP_LEVEL AND NOT RUNIC_BUILD_TESTS_NESTED)
        add_subdirectory(tests/build)
    endif()
endif()
