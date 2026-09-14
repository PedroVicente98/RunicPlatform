#include <Runic/Fabric/Version.hpp>

#include <string_view>

int main() { return std::string_view{Runic::Fabric::Version()} == "0.1.0" ? 0 : 1; }
