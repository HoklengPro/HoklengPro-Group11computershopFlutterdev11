#pragma once
#include <drogon/drogon.h>
#include <optional>
#include <string>
#include "nexus/services/auth_service.h"
#include "nexus/utils/json_response.h"

namespace nexus::middleware {

inline std::string bearerToken(const drogon::HttpRequestPtr &req) {
    const auto auth = req->getHeader("Authorization");
    const std::string prefix = "Bearer ";
    if (auth.rfind(prefix, 0) == 0) {
        return auth.substr(prefix.size());
    }
    return "";
}

inline std::optional<services::AuthUserProfile> authProfile(
    const drogon::HttpRequestPtr &req) {
    const auto token = bearerToken(req);
    if (token.empty()) {
        return std::nullopt;
    }
    return services::authService().profileFromToken(token);
}

inline bool isAdmin(const services::AuthUserProfile &profile) {
    return profile.role == "admin";
}

inline void rejectUnauthorized(
    const std::function<void(const drogon::HttpResponsePtr &)> &callback) {
    callback(utils::errorResponse("authorization required", drogon::k401Unauthorized));
}

inline void rejectForbidden(
    const std::function<void(const drogon::HttpResponsePtr &)> &callback) {
    callback(utils::errorResponse("admin access required", drogon::k403Forbidden));
}

}  // namespace nexus::middleware
