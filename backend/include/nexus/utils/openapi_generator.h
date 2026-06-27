#pragma once

#include <string>
#include <vector>

namespace nexus::utils {

/// OpenAPI 3 spec — curated static file plus any newly discovered routes.
std::string generateOpenApiYaml();

/// All registered HTTP paths (deduplicated, sorted).
std::vector<std::string> listRegisteredApiPaths();

}  // namespace nexus::utils
