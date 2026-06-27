#include "nexus/services/auth_service.h"
#include <drogon/drogon.h>
#include <openssl/sha.h>
#include <algorithm>
#include <cctype>
#include <chrono>
#include <fstream>
#include <iomanip>
#include <mutex>
#include <random>
#include <sstream>

namespace nexus::services {
namespace {

constexpr const char *kDefaultTier = "Member · Nova rewards tier";
constexpr const char *kTokenPepper = "nexus-csf-auth-v1";

std::mutex gAuthMutex;
AuthService gAuth;

std::string toLowerCopy(std::string value) {
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) {
        return static_cast<char>(std::tolower(c));
    });
    return value;
}

std::string trimCopy(const std::string &value) {
    const auto start = value.find_first_not_of(" \t\n\r");
    if (start == std::string::npos) {
        return "";
    }
    const auto end = value.find_last_not_of(" \t\n\r");
    return value.substr(start, end - start + 1);
}

std::string sha256Hex(const std::string &input) {
    unsigned char hash[SHA256_DIGEST_LENGTH];
    SHA256(reinterpret_cast<const unsigned char *>(input.data()),
           input.size(),
           hash);
    std::ostringstream oss;
    oss << std::hex << std::setfill('0');
    for (unsigned char byte : hash) {
        oss << std::setw(2) << static_cast<int>(byte);
    }
    return oss.str();
}

std::string hashPassword(const std::string &password) {
    return sha256Hex(password + ":" + kTokenPepper);
}

std::string makeInitials(const std::string &name) {
    std::istringstream stream(name);
    std::string word;
    std::string initials;
    while (stream >> word && initials.size() < 2) {
        initials.push_back(
            static_cast<char>(std::toupper(static_cast<unsigned char>(word[0]))));
    }
    if (initials.empty()) {
        return "NX";
    }
    return initials;
}

std::string randomUserId() {
    static std::mt19937 rng{static_cast<unsigned>(
        std::chrono::steady_clock::now().time_since_epoch().count())};
    static std::uniform_int_distribution<int> dist(0, 15);
    std::ostringstream oss;
    oss << "u-";
    for (int i = 0; i < 8; ++i) {
        oss << std::hex << dist(rng);
    }
    return oss.str();
}

std::vector<std::string> usersSearchPaths() {
    return {
        "data/users.json",
        "../data/users.json",
        "../../data/users.json",
        "./users.json",
        "/app/data/users.json",
    };
}

Json::Value readUsersRoot() {
    for (const auto &path : usersSearchPaths()) {
        std::ifstream in(path);
        if (!in.is_open()) {
            continue;
        }
        Json::Value root;
        Json::CharReaderBuilder builder;
        std::string errs;
        if (Json::parseFromStream(builder, in, &root, &errs)) {
            if (!root.isMember("users") || !root["users"].isArray()) {
                root["users"] = Json::arrayValue;
            }
            return root;
        }
    }
    Json::Value root;
    root["users"] = Json::arrayValue;
    return root;
}

bool writeUsersRoot(const Json::Value &root) {
    for (const auto &path : usersSearchPaths()) {
        std::ofstream out(path, std::ios::trunc);
        if (!out.is_open()) {
            continue;
        }
        out << root.toStyledString();
        return true;
    }
    return false;
}

Json::Value *findUserByEmail(Json::Value &root, const std::string &emailLower) {
    auto &users = root["users"];
    for (auto &user : users) {
        if (toLowerCopy(user.get("email", "").asString()) == emailLower) {
            return &user;
        }
    }
    return nullptr;
}

const Json::Value *findUserById(const Json::Value &root, const std::string &id) {
    for (const auto &user : root["users"]) {
        if (user.get("id", "").asString() == id) {
            return &user;
        }
    }
    return nullptr;
}

Json::Value *findUserByIdMutable(Json::Value &root, const std::string &id) {
    for (auto &user : root["users"]) {
        if (user.get("id", "").asString() == id) {
            return &user;
        }
    }
    return nullptr;
}

AuthUserProfile userFromJson(const Json::Value &user) {
    AuthUserProfile profile;
    profile.id = user.get("id", "").asString();
    profile.email = user.get("email", "").asString();
    profile.displayName = user.get("name", "").asString();
    profile.initials = user.get("initials", makeInitials(profile.displayName)).asString();
    profile.tier = user.get("tier", kDefaultTier).asString();
    profile.role = user.get("role", "user").asString();
    return profile;
}

std::string issueToken(const std::string &userId, const std::string &passwordHash) {
    const auto signature =
        sha256Hex(userId + ":" + passwordHash + ":" + kTokenPepper).substr(0, 24);
    return "nx." + userId + "." + signature;
}

bool parseToken(const std::string &token, std::string &userId, std::string &signature) {
    if (token.rfind("nx.", 0) != 0) {
        return false;
    }
    const auto separator = token.find('.', 3);
    if (separator == std::string::npos || separator + 1 >= token.size()) {
        return false;
    }
    userId = token.substr(3, separator - 3);
    signature = token.substr(separator + 1);
    return !userId.empty() && !signature.empty();
}

}  // namespace

AuthService &authService() {
    return gAuth;
}

Json::Value AuthService::profileToJson(const AuthUserProfile &profile) {
    Json::Value body;
    body["id"] = profile.id;
    body["email"] = profile.email;
    body["displayName"] = profile.displayName;
    body["initials"] = profile.initials;
    body["tier"] = profile.tier;
    body["role"] = profile.role;
    return body;
}

AuthResult AuthService::login(const std::string &email, const std::string &password) {
    std::lock_guard<std::mutex> lock(gAuthMutex);
    AuthResult result;
    const auto emailNorm = toLowerCopy(trimCopy(email));
    if (emailNorm.empty() || password.empty()) {
        result.message = "email and password are required";
        return result;
    }

    auto root = readUsersRoot();
    auto *user = findUserByEmail(root, emailNorm);
    if (user == nullptr) {
        result.message = "invalid email or password";
        return result;
    }

    if (user->get("passwordHash", "").asString() != hashPassword(password)) {
        result.message = "invalid email or password";
        return result;
    }

    result.ok = true;
    result.message = "signed in";
    result.user = userFromJson(*user);
    result.token = issueToken(result.user.id, user->get("passwordHash", "").asString());
    return result;
}

AuthResult AuthService::signup(const std::string &name,
                               const std::string &email,
                               const std::string &password) {
    std::lock_guard<std::mutex> lock(gAuthMutex);
    AuthResult result;
    const auto displayName = trimCopy(name);
    const auto emailNorm = toLowerCopy(trimCopy(email));

    if (displayName.empty() || emailNorm.empty() || password.size() < 6) {
        result.message = "name, email, and password (min 6 chars) are required";
        return result;
    }
    if (emailNorm.find('@') == std::string::npos) {
        result.message = "invalid email address";
        return result;
    }

    auto root = readUsersRoot();
    if (findUserByEmail(root, emailNorm) != nullptr) {
        result.message = "account already exists for this email";
        return result;
    }

    Json::Value user;
    user["id"] = randomUserId();
    user["email"] = emailNorm;
    user["name"] = displayName;
    user["initials"] = makeInitials(displayName);
    user["tier"] = kDefaultTier;
    user["role"] = "user";
    user["passwordHash"] = hashPassword(password);
    user["createdAt"] = std::to_string(
        std::chrono::duration_cast<std::chrono::seconds>(
            std::chrono::system_clock::now().time_since_epoch())
            .count());
    user["favorites"] = Json::arrayValue;
    root["users"].append(user);

    if (!writeUsersRoot(root)) {
        result.message = "could not save account";
        return result;
    }

    result.ok = true;
    result.message = "account created";
    result.user = userFromJson(user);
    result.token = issueToken(result.user.id, user["passwordHash"].asString());
    LOG_INFO << "New user registered: " << emailNorm;
    return result;
}

std::optional<AuthUserProfile> AuthService::profileFromToken(const std::string &token) {
    std::lock_guard<std::mutex> lock(gAuthMutex);
    std::string userId;
    std::string signature;
    if (!parseToken(token, userId, signature)) {
        return std::nullopt;
    }

    const auto root = readUsersRoot();
    const auto *user = findUserById(root, userId);
    if (user == nullptr) {
        return std::nullopt;
    }

    const auto expected =
        issueToken(userId, user->get("passwordHash", "").asString());
    if (expected != token) {
        return std::nullopt;
    }

    return userFromJson(*user);
}

std::vector<std::string> AuthService::favoritesFromToken(const std::string &token) {
    std::lock_guard<std::mutex> lock(gAuthMutex);
    std::string userId;
    std::string signature;
    if (!parseToken(token, userId, signature)) {
        return {};
    }

    const auto root = readUsersRoot();
    const auto *user = findUserById(root, userId);
    if (user == nullptr) {
        return {};
    }

    const auto expected =
        issueToken(userId, user->get("passwordHash", "").asString());
    if (expected != token) {
        return {};
    }

    std::vector<std::string> ids;
    if (user->isMember("favorites") && (*user)["favorites"].isArray()) {
        for (const auto &entry : (*user)["favorites"]) {
            ids.push_back(entry.asString());
        }
    }
    return ids;
}

bool AuthService::updateFavorites(const std::string &token,
                                  const std::vector<std::string> &productIds) {
    std::lock_guard<std::mutex> lock(gAuthMutex);
    std::string userId;
    std::string signature;
    if (!parseToken(token, userId, signature)) {
        return false;
    }

    auto root = readUsersRoot();
    auto *user = findUserByIdMutable(root, userId);
    if (user == nullptr) {
        return false;
    }

    const auto expected =
        issueToken(userId, user->get("passwordHash", "").asString());
    if (expected != token) {
        return false;
    }

    Json::Value favorites(Json::arrayValue);
    for (const auto &id : productIds) {
        if (!id.empty()) {
            favorites.append(id);
        }
    }
    (*user)["favorites"] = favorites;
    return writeUsersRoot(root);
}

int AuthService::countUsers() {
    std::lock_guard<std::mutex> lock(gAuthMutex);
    const auto root = readUsersRoot();
    return static_cast<int>(root["users"].size());
}

}  // namespace nexus::services
