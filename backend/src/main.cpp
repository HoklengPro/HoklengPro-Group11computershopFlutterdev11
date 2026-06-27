#include <cstdlib>
#include <drogon/drogon.h>

#include "nexus/db/database.h"
#include "nexus/routes/route_registry.h"

int main() {
    const char *portEnv = std::getenv("NEXUS_API_PORT");
    const uint16_t port = portEnv != nullptr ? static_cast<uint16_t>(std::atoi(portEnv)) : 8848;

    nexus::db::configureFromEnvironment();
    nexus::routes::registerRoutes();

    drogon::app().addListener("0.0.0.0", port);
    LOG_INFO << "Nexus Drogon API listening on http://0.0.0.0:" << port;
    drogon::app().run();
    return 0;
}
