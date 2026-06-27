#include "nexus/utils/openapi_generator.h"

#include <drogon/drogon.h>
#include <drogon/HttpTypes.h>
#include <algorithm>
#include <cctype>
#include <fstream>
#include <map>
#include <set>
#include <sstream>
#include <string>

namespace nexus::utils {
namespace {

std::string readStaticOpenApiSpec() {
    const std::string candidates[] = {
        "openapi.yaml",
        "/app/openapi.yaml",
        "data/openapi.yaml",
        "../openapi.yaml",
    };

    for (const auto &path : candidates) {
        std::ifstream file(path);
        if (!file.is_open()) {
            continue;
        }
        std::ostringstream buffer;
        buffer << file.rdbuf();
        return buffer.str();
    }
    return "";
}

std::string yamlQuote(const std::string &value) {
    if (value.find_first_of(":#{}[]&*!|>'\"%@`\n") == std::string::npos) {
        return value;
    }
    std::string escaped;
    escaped.reserve(value.size() + 2);
    escaped.push_back('"');
    for (char ch : value) {
        if (ch == '"') {
            escaped += "\\\"";
        } else if (ch == '\\') {
            escaped += "\\\\";
        } else {
            escaped.push_back(ch);
        }
    }
    escaped.push_back('"');
    return escaped;
}

std::string methodKey(drogon::HttpMethod method) {
    switch (method) {
        case drogon::HttpMethod::Get:
            return "get";
        case drogon::HttpMethod::Post:
            return "post";
        case drogon::HttpMethod::Put:
            return "put";
        case drogon::HttpMethod::Delete:
            return "delete";
        case drogon::HttpMethod::Patch:
            return "patch";
        default:
            return drogon::to_string(method);
    }
}

std::string inferTag(const std::string &path) {
    if (path == "/" || path == "/api/health") {
        return "System";
    }
    if (path.rfind("/api/auth", 0) == 0) {
        return "Auth";
    }
    if (path.rfind("/api/admin", 0) == 0) {
        return "Admin";
    }
    if (path.rfind("/api/orders", 0) == 0) {
        return "Orders";
    }
    if (path.rfind("/api/users", 0) == 0) {
        return "Users";
    }
    if (path.rfind("/api/search", 0) == 0) {
        return "Search";
    }
    if (path.rfind("/api/builder", 0) == 0) {
        return "Builder";
    }
    if (path.rfind("/api/products", 0) == 0) {
        return "Products";
    }
    if (path.rfind("/api/catalog", 0) == 0 || path.rfind("/api/home", 0) == 0 ||
        path.rfind("/api/categories", 0) == 0) {
        return "Catalog";
    }
    return "API";
}

std::string humanSummary(const std::string &path, drogon::HttpMethod method) {
    const std::string key = drogon::to_string(method) + " " + path;
    static const std::map<std::string, std::string> kSummaries = {
        {"GET /", "Service index"},
        {"GET /api/health", "Health check"},
        {"GET /api/catalog", "Full catalog snapshot"},
        {"GET /api/home", "Home screen payload"},
        {"GET /api/categories", "Product category tiles"},
        {"GET /api/products", "All products"},
        {"GET /api/products/featured", "Featured products grid"},
        {"GET /api/products/botm", "Build of the month"},
        {"GET /api/products/{id}", "Single product by ID"},
        {"GET /api/search", "Search products and builder parts"},
        {"GET /api/builder/parts", "PC builder parts catalog"},
        {"GET /api/orders", "List orders"},
        {"POST /api/orders", "Place a new order"},
        {"GET /api/orders/{id}", "Order detail by ID"},
        {"POST /api/auth/login", "Sign in"},
        {"POST /api/auth/signup", "Create account"},
        {"GET /api/auth/me", "Current user profile"},
        {"GET /api/users/me/favorites", "Get saved product IDs"},
        {"PUT /api/users/me/favorites", "Replace favorites list"},
        {"POST /api/admin/products", "Create product"},
        {"PUT /api/admin/products/{id}", "Update product"},
        {"DELETE /api/admin/products/{id}", "Delete product"},
        {"GET /api/admin/dashboard", "Admin dashboard stats"},
        {"GET /api/admin/orders", "List all orders (admin)"},
        {"PATCH /api/admin/orders/{id}/status", "Update order status"},
        {"GET /api/docs", "Swagger UI"},
        {"GET /api/openapi.yaml", "OpenAPI specification"},
    };

    const auto found = kSummaries.find(key);
    if (found != kSummaries.end()) {
        return found->second;
    }
    return drogon::to_string(method) + " " + path;
}

bool includeInDocs(const std::string &path, drogon::HttpMethod method) {
    if (method == drogon::HttpMethod::Invalid ||
        method == drogon::HttpMethod::Head ||
        method == drogon::HttpMethod::Options) {
        return false;
    }
    if (path.empty() || path == "/api/docs" || path == "/api/openapi.yaml") {
        return false;
    }
    if (path == "/api/{path}") {
        return false;
    }
    return true;
}

bool pathDocumented(const std::string &yaml, const std::string &path) {
    return yaml.find("\n  " + path + ":") != std::string::npos;
}

struct RouteEntry {
    drogon::HttpMethod method;
};

std::map<std::string, std::vector<RouteEntry>> collectRoutes() {
    std::map<std::string, std::vector<RouteEntry>> routes;
    for (const auto &info : drogon::app().getHandlersInfo()) {
        const auto &path = std::get<0>(info);
        const auto method = std::get<1>(info);
        if (!includeInDocs(path, method)) {
            continue;
        }

        RouteEntry entry{method};
        auto &methods = routes[path];
        const auto duplicate = std::find_if(
            methods.begin(),
            methods.end(),
            [&](const RouteEntry &existing) {
                return existing.method == entry.method;
            });
        if (duplicate == methods.end()) {
            methods.push_back(entry);
        }
    }
    return routes;
}

std::string generateMinimalPathBlock(const std::string &path,
                                     const std::vector<RouteEntry> &entries) {
    std::ostringstream out;
    out << "  " << yamlQuote(path) << ":\n";
    for (const auto &entry : entries) {
        const auto tag = inferTag(path);
        out << "    " << methodKey(entry.method) << ":\n";
        out << "      tags: [" << tag << "]\n";
        out << "      summary: " << yamlQuote(humanSummary(path, entry.method))
            << "\n";
        out << "      responses:\n";
        out << "        '200':\n";
        out << "          description: Successful response\n";
        if (entry.method == drogon::HttpMethod::Post) {
            out << "        '201':\n";
            out << "          description: Resource created\n";
        }
    }
    return out.str();
}

std::string generateDiscoveredPathsSection(const std::string &baseYaml) {
    const auto routes = collectRoutes();
    std::ostringstream out;
    bool added = false;

    for (const auto &[path, entries] : routes) {
        if (pathDocumented(baseYaml, path)) {
            continue;
        }
        out << generateMinimalPathBlock(path, entries);
        added = true;
    }

    if (!added) {
        return "";
    }
    return "\n# Auto-discovered routes (not yet in openapi.yaml)\n" + out.str();
}

std::string mergeStaticWithDiscovered(const std::string &baseYaml) {
    const auto extra = generateDiscoveredPathsSection(baseYaml);
    if (extra.empty()) {
        return baseYaml;
    }

    const auto marker = baseYaml.find("\ncomponents:");
    if (marker == std::string::npos) {
        return baseYaml + extra;
    }
    return baseYaml.substr(0, marker) + extra + baseYaml.substr(marker);
}

}  // namespace

std::vector<std::string> listRegisteredApiPaths() {
    std::set<std::string> unique;
    for (const auto &info : drogon::app().getHandlersInfo()) {
        const auto &path = std::get<0>(info);
        const auto method = std::get<1>(info);
        if (!includeInDocs(path, method)) {
            continue;
        }
        unique.insert(path);
    }
    return std::vector<std::string>(unique.begin(), unique.end());
}

std::string generateOpenApiYaml() {
    const auto staticSpec = readStaticOpenApiSpec();
    if (!staticSpec.empty()) {
        return mergeStaticWithDiscovered(staticSpec);
    }

    const auto routes = collectRoutes();
    std::ostringstream out;
    out << "openapi: 3.0.3\n";
    out << "info:\n";
    out << "  title: Nexus CSF API\n";
    out << "  version: 1.0.0\n";
    out << "paths:\n";
    for (const auto &[path, entries] : routes) {
        out << generateMinimalPathBlock(path, entries);
    }
    return out.str();
}

}  // namespace nexus::utils
