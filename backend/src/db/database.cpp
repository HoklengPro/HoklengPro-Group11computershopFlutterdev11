#include "nexus/db/database.h"
#include <cstdlib>
#include <drogon/drogon.h>
#include <sstream>
#include <string>

namespace nexus::db {
namespace {

bool gEnabled = false;
std::string gSummary;

bool parseDatabaseUrl(const std::string &url,
                      std::string &user,
                      std::string &password,
                      std::string &host,
                      unsigned short &port,
                      std::string &database) {
    // postgresql://user:pass@host:port/dbname
    const std::string prefix = "postgresql://";
    if (url.rfind(prefix, 0) != 0) {
        return false;
    }

    const auto withoutScheme = url.substr(prefix.size());
    const auto atPos = withoutScheme.rfind('@');
    if (atPos == std::string::npos) {
        return false;
    }

    const auto creds = withoutScheme.substr(0, atPos);
    const auto hostPart = withoutScheme.substr(atPos + 1);
    const auto colonPos = creds.find(':');
    if (colonPos == std::string::npos) {
        return false;
    }
    user = creds.substr(0, colonPos);
    password = creds.substr(colonPos + 1);

    const auto slashPos = hostPart.find('/');
    if (slashPos == std::string::npos) {
        return false;
    }
    database = hostPart.substr(slashPos + 1);
    const auto hostPort = hostPart.substr(0, slashPos);
    const auto portPos = hostPort.find(':');
    if (portPos == std::string::npos) {
        host = hostPort;
        port = 5432;
    } else {
        host = hostPort.substr(0, portPos);
        port = static_cast<unsigned short>(std::stoi(hostPort.substr(portPos + 1)));
    }
    return true;
}

}  // namespace

bool configureFromEnvironment() {
    const char *urlEnv = std::getenv("DATABASE_URL");
    if (urlEnv == nullptr || urlEnv[0] == '\0') {
        LOG_WARN << "DATABASE_URL not set — API will read catalog.json";
        return false;
    }

    std::string user;
    std::string password;
    std::string host;
    unsigned short port = 5432;
    std::string database;

    if (!parseDatabaseUrl(urlEnv, user, password, host, port, database)) {
        LOG_ERROR << "Invalid DATABASE_URL format";
        return false;
    }

    try {
        drogon::app().createDbClient(
            "postgresql", host, port, database, user, password, 4);
        gEnabled = true;
        gSummary = host + ":" + std::to_string(port) + "/" + database;
        LOG_INFO << "PostgreSQL connected: " << gSummary;
        return true;
    } catch (const std::exception &ex) {
        LOG_ERROR << "PostgreSQL connection failed: " << ex.what()
                  << " — falling back to catalog.json";
        return false;
    }
}

bool isEnabled() {
    return gEnabled;
}

std::string connectionSummary() {
    return gSummary;
}

}  // namespace nexus::db
