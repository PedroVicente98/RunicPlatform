cmake_minimum_required(VERSION 3.24)

project(RunicFabric VERSION 0.1.0 LANGUAGES CXX)

option(RUNIC_FABRIC_BUILD_TESTS "Build RunicFabric bootstrap tests" ${PROJECT_IS_TOP_LEVEL})

add_library(runic_fabric STATIC)
add_library(Runic::Fabric ALIAS runic_fabric)
target_sources(runic_fabric PRIVATE cpp/Core/Version.cpp)
target_include_directories(runic_fabric PUBLIC
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/cpp/include>"
)
target_compile_features(runic_fabric PUBLIC cxx_std_20)
set_target_properties(runic_fabric PROPERTIES CXX_EXTENSIONS OFF)

if(RUNIC_FABRIC_BUILD_TESTS)
    enable_testing()
    add_executable(runic_fabric_smoke tests/Bootstrap.cpp)
    target_link_libraries(runic_fabric_smoke PRIVATE Runic::Fabric)
    set_target_properties(runic_fabric_smoke PROPERTIES CXX_EXTENSIONS OFF)
    add_test(NAME runic_fabric.bootstrap COMMAND runic_fabric_smoke)
endif()
