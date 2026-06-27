#pragma once
#include <drogon/drogon.h>
namespace nexus::middleware {
inline void addCors(const drogon::HttpResponsePtr &resp) {
    resp->addHeader("Access-Control-Allow-Origin", "*");
    resp->addHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    resp->addHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

}  // namespace nexus::middleware
