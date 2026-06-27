#pragma once
#include <drogon/drogon.h>
#include <json/json.h>
#include "nexus/middleware/cors.h"

namespace nexus::utils {

inline drogon::HttpResponsePtr jsonResponse(
    const Json::Value &body,
    drogon::HttpStatusCode code = drogon::k200OK) {
    auto resp = drogon::HttpResponse::newHttpJsonResponse(body);
    resp->setStatusCode(code);
    middleware::addCors(resp);
    return resp;
}

inline drogon::HttpResponsePtr errorResponse(
    const std::string &message,
    drogon::HttpStatusCode code = drogon::k400BadRequest) {
    Json::Value body;
    body["error"] = message;
    return jsonResponse(body, code);
}

}  // namespace nexus::utils
