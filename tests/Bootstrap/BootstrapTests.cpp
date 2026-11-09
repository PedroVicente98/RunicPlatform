#include <Runic/Platform/Version.hpp>

#include <gtest/gtest.h>

#include <string_view>

// The bootstrap smoke test as a GoogleTest test (BUILD-1). It goes with the bootstrap target.
TEST(PlatformBootstrap, Version) { EXPECT_EQ(std::string_view{Runic::Platform::Version()}, "0.1.0"); }
