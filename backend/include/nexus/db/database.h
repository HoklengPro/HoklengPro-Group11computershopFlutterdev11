#pragma once

#include <string>

namespace nexus::db {

bool configureFromEnvironment();
bool isEnabled();
std::string connectionSummary();

}  // namespace nexus::db
