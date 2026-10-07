cmake_minimum_required(VERSION 3.24)

project(RunicPlatform VERSION 0.1.0 LANGUAGES CXX)

option(RUNIC_PLATFORM_BUILD_TESTS "Build RunicPlatform bootstrap tests" ${PROJECT_IS_TOP_LEVEL})

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
endif()
