cmake_minimum_required(VERSION 3.24)

project(RunicPlatform VERSION 0.1.0 LANGUAGES CXX)

option(RUNIC_PLATFORM_BUILD_TESTS "Build RunicPlatform bootstrap tests" ${PROJECT_IS_TOP_LEVEL})

# RunicEngine source tree for the C++ bindings (Transport, ServerBindings), which
# include Engine public headers only. CI and standalone builds use the submodule
# pinned at external/RunicEngine; daily work points RUNIC_ENGINE_DIR at a sibling
# checkout. No target needs the Engine before PTR-1 and PBND-1, so it is not added
# to the build yet. A superproject that already provides the Engine targets
# (RunicGame adds the Engine first) owns Engine resolution: this block then does
# nothing and never touches its cache.
if(NOT TARGET Runic::Core AND NOT TARGET Runic::Runtime)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/external/RunicEngine/CMakeLists.txt")
        set(_runic_platform_engine_default "${CMAKE_CURRENT_SOURCE_DIR}/external/RunicEngine")
    else()
        set(_runic_platform_engine_default "${CMAKE_CURRENT_SOURCE_DIR}/../RunicEngine")
    endif()
    set(RUNIC_ENGINE_DIR "${_runic_platform_engine_default}"
        CACHE PATH "Path to the RunicEngine source tree used by the Platform C++ bindings")
    unset(_runic_platform_engine_default)
    message(STATUS "RunicPlatform: RUNIC_ENGINE_DIR = ${RUNIC_ENGINE_DIR} (not built until PTR-1/PBND-1)")
endif()

add_library(runic_platform STATIC)
add_library(Runic::Platform ALIAS runic_platform)
target_sources(runic_platform PRIVATE cpp/Core/Version.cpp)
target_include_directories(runic_platform PUBLIC
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/cpp/include>"
)
target_compile_features(runic_platform PUBLIC cxx_std_20)
set_target_properties(runic_platform PROPERTIES CXX_EXTENSIONS OFF)

if(RUNIC_PLATFORM_BUILD_TESTS)
    enable_testing()
    add_executable(runic_platform_smoke tests/Bootstrap.cpp)
    target_link_libraries(runic_platform_smoke PRIVATE Runic::Platform)
    set_target_properties(runic_platform_smoke PROPERTIES CXX_EXTENSIONS OFF)
    add_test(NAME runic_platform.bootstrap COMMAND runic_platform_smoke)

    # BUILD-1 acceptance tests (contract: docs/build/BUILD-1.md). They fail until BUILD-1 is implemented.
    if(PROJECT_IS_TOP_LEVEL AND NOT RUNIC_BUILD_TESTS_NESTED)
        add_subdirectory(tests/build)
    endif()
endif()
