#pragma once
#include <json/json.h>
#include <optional>
#include <string>

namespace nexus::services {
struct AuthUserProfile {
    std::string id;
    std::string email;
    std::string displayName;
    std::string initials;
    std::string tier;
    std::string role{"user"};
};

struct AuthResult {
    bool ok{false};
    std::string message;
    std::string token;
    AuthUserProfile user;
};

class AuthService {
public:
    AuthResult login(const std::string &email, const std::string &password);
    AuthResult signup(const std::string &name,
                      const std::string &email,
                      const std::string &password);
    std::optional<AuthUserProfile> profileFromToken(const std::string &token);

    std::vector<std::string> favoritesFromToken(const std::string &token);
    bool updateFavorites(const std::string &token,
                         const std::vector<std::string> &productIds);

    int countUsers();

    static Json::Value profileToJson(const AuthUserProfile &profile);
};

AuthService &authService();

}  // namespace nexus::services
