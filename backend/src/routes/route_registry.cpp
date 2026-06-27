#include "nexus/routes/route_registry.h"
#include "nexus/routes/swagger_routes.h"
#include <drogon/drogon.h>
#include "nexus/db/database.h"
#include "nexus/middleware/auth_guard.h"
#include "nexus/middleware/cors.h"
#include "nexus/repositories/catalog_repository.h"
#include "nexus/services/auth_service.h"
#include "nexus/services/catalog_service.h"
#include "nexus/services/order_service.h"
#include "nexus/utils/json_response.h"
#include "nexus/utils/openapi_generator.h"

namespace nexus::routes {

namespace {

services::CatalogService gCatalog;

void registerRootRoute() {
    using namespace drogon;

    app().registerHandler(
        "/",
        [](const HttpRequestPtr &,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            Json::Value body;
            body["service"] = "nexus-drogon-backend";
            body["status"] = "ok";
            body["message"] = "Use /api/docs for Swagger UI (auto-synced routes)";
            body["docs"] = "/api/docs";
            body["openapi"] = "/api/openapi.yaml";
            body["endpoints"] = Json::arrayValue;
            for (const auto &path : nexus::utils::listRegisteredApiPaths()) {
                body["endpoints"].append(path);
            }
            callback(utils::jsonResponse(body));
        },
        {Get});
}

void registerHealthRoutes() {
    using namespace drogon;

    app().registerHandler(
        "/api/health",
        [](const HttpRequestPtr &,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            Json::Value body;
            body["status"] = "ok";
            body["service"] = "nexus-drogon-backend";
            body["dataSource"] = gCatalog.dataSourceLabel();
            if (nexus::db::isEnabled()) {
                body["database"] = nexus::db::connectionSummary();
            }
            callback(utils::jsonResponse(body));
        },
        {Get});
}

void registerCatalogRoutes() {
    using namespace drogon;

    app().registerHandler(
        "/api/catalog",
        [](const HttpRequestPtr &,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            callback(utils::jsonResponse(gCatalog.catalog()));
        },
        {Get});

    app().registerHandler(
        "/api/home",
        [](const HttpRequestPtr &,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            callback(utils::jsonResponse(gCatalog.homePayload()));
        },
        {Get});

    app().registerHandler(
        "/api/categories",
        [](const HttpRequestPtr &,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            callback(utils::jsonResponse(gCatalog.catalog()["categories"]));
        },
        {Get});
}

void registerProductRoutes() {
    using namespace drogon;

    app().registerHandler(
        "/api/products",
        [](const HttpRequestPtr &,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            callback(utils::jsonResponse(gCatalog.productsArray()));
        },
        {Get});

    app().registerHandler(
        "/api/products/featured",
        [](const HttpRequestPtr &,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            callback(utils::jsonResponse(gCatalog.catalog()["featuredProducts"]));
        },
        {Get});

    app().registerHandler(
        "/api/products/botm",
        [](const HttpRequestPtr &,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            callback(utils::jsonResponse(gCatalog.catalog()["buildOfTheMonth"]));
        },
        {Get});

    app().registerHandler(
        "/api/products/{id}",
        [](const HttpRequestPtr &,
           std::function<void(const HttpResponsePtr &)> &&callback,
           const std::string &id) {
            const auto *product = gCatalog.findProductById(id);
            if (product == nullptr) {
                callback(utils::errorResponse("product not found", k404NotFound));
                return;
            }
            callback(utils::jsonResponse(*product));
        },
        {Get});

    app().registerHandler(
        "/api/search",
        [](const HttpRequestPtr &req,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            const auto query = req->getParameter("q");
            int limit = 20;
            const auto limitParam = req->getParameter("limit");
            if (!limitParam.empty()) {
                try {
                    limit = std::stoi(limitParam);
                } catch (...) {
                    callback(utils::errorResponse("limit must be a number"));
                    return;
                }
            }

            Json::Value body;
            body["query"] = query;
            body["results"] = gCatalog.search(query, limit);
            callback(utils::jsonResponse(body));
        },
        {Get});
}

void registerBuilderRoutes() {
    using namespace drogon;

    app().registerHandler(
        "/api/builder/parts",
        [](const HttpRequestPtr &req,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            const auto type = req->getParameter("type");
            const auto parts = gCatalog.builderParts(type);
            if (!type.empty() && parts.isNull()) {
                callback(utils::errorResponse("unknown builder part type"));
                return;
            }
            callback(utils::jsonResponse(parts));
        },
        {Get});
}

std::string bearerToken(const drogon::HttpRequestPtr &req) {
    const auto auth = req->getHeader("Authorization");
    const std::string prefix = "Bearer ";
    if (auth.rfind(prefix, 0) == 0) {
        return auth.substr(prefix.size());
    }
    return "";
}

void registerOrderRoutes() {
    using namespace drogon;

    app().registerHandler(
        "/api/orders",
        [](const HttpRequestPtr &req,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            if (req->method() == Post) {
                const auto token = bearerToken(req);
                if (token.empty()) {
                    callback(utils::errorResponse("authorization required",
                                                    k401Unauthorized));
                    return;
                }
                const auto profile = services::authService().profileFromToken(token);
                if (!profile.has_value()) {
                    callback(utils::errorResponse("invalid or expired session",
                                                    k401Unauthorized));
                    return;
                }

                auto json = req->getJsonObject();
                if (json == nullptr || !(*json).isMember("items") ||
                    !(*json)["items"].isArray()) {
                    callback(utils::errorResponse("items array required"));
                    return;
                }

                std::vector<services::CreateOrderItem> items;
                for (const auto &entry : (*json)["items"]) {
                    services::CreateOrderItem item;
                    item.productId = entry.get("productId", "").asString();
                    item.title = entry.get("title", "").asString();
                    item.qty = entry.get("qty", 1).asInt();
                    item.unitPrice = entry.get("unitPrice", 0.0).asDouble();
                    items.push_back(item);
                }

                const auto result =
                    services::orderService().createOrder(profile->id, items);
                if (!result.ok) {
                    callback(utils::errorResponse(result.message));
                    return;
                }

                Json::Value body;
                body["order"] = result.order;
                body["message"] = result.message;
                callback(utils::jsonResponse(body, k201Created));
                return;
            }

            const auto token = bearerToken(req);
            if (!token.empty()) {
                const auto profile = services::authService().profileFromToken(token);
                if (profile.has_value()) {
                    callback(utils::jsonResponse(
                        services::orderService().listForUser(profile->id)));
                    return;
                }
            }
            callback(utils::jsonResponse(gCatalog.orderSummaries()));
        },
        {Get, Post});

    app().registerHandler(
        "/api/orders/{id}",
        [](const HttpRequestPtr &req,
           std::function<void(const HttpResponsePtr &)> &&callback,
           const std::string &id) {
            const auto token = bearerToken(req);
            if (!token.empty()) {
                const auto profile = services::authService().profileFromToken(token);
                if (profile.has_value()) {
                    const auto *userOrder =
                        services::orderService().findByIdForUser(id, profile->id);
                    if (userOrder != nullptr) {
                        callback(utils::jsonResponse(*userOrder));
                        return;
                    }
                }
            }

            const auto *order = gCatalog.findOrderById(id);
            if (order == nullptr) {
                callback(utils::errorResponse("order not found", k404NotFound));
                return;
            }
            callback(utils::jsonResponse(*order));
        },
        {Get});
}

Json::Value authSuccessBody(const services::AuthResult &result) {
    Json::Value body;
    body["token"] = result.token;
    body["user"] = services::AuthService::profileToJson(result.user);
    body["message"] = result.message;
    return body;
}

void registerAuthRoutes() {
    using namespace drogon;

    app().registerHandler(
        "/api/auth/login",
        [](const HttpRequestPtr &req,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            auto json = req->getJsonObject();
            if (json == nullptr || !(*json).isMember("email")) {
                callback(utils::errorResponse("email required"));
                return;
            }

            const auto email = (*json)["email"].asString();
            const auto password =
                (*json).get("password", "").asString();
            if (password.empty()) {
                callback(utils::errorResponse("password required"));
                return;
            }

            const auto result = services::authService().login(email, password);
            if (!result.ok) {
                callback(utils::errorResponse(result.message, k401Unauthorized));
                return;
            }
            callback(utils::jsonResponse(authSuccessBody(result)));
        },
        {Post});

    app().registerHandler(
        "/api/auth/signup",
        [](const HttpRequestPtr &req,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            auto json = req->getJsonObject();
            if (json == nullptr || !(*json).isMember("email") ||
                !(*json).isMember("name")) {
                callback(utils::errorResponse("name and email required"));
                return;
            }

            const auto result = services::authService().signup(
                (*json)["name"].asString(),
                (*json)["email"].asString(),
                (*json).get("password", "").asString());
            if (!result.ok) {
                callback(utils::errorResponse(result.message));
                return;
            }
            callback(utils::jsonResponse(authSuccessBody(result), k201Created));
        },
        {Post});

    app().registerHandler(
        "/api/auth/me",
        [](const HttpRequestPtr &req,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            const auto token = bearerToken(req);
            if (token.empty()) {
                callback(utils::errorResponse("authorization required",
                                                k401Unauthorized));
                return;
            }

            const auto profile = services::authService().profileFromToken(token);
            if (!profile.has_value()) {
                callback(utils::errorResponse("invalid or expired session",
                                                k401Unauthorized));
                return;
            }

            Json::Value body;
            body["user"] = services::AuthService::profileToJson(*profile);
            callback(utils::jsonResponse(body));
        },
        {Get});
}

void registerUserRoutes() {
    using namespace drogon;

    app().registerHandler(
        "/api/users/me/favorites",
        [](const HttpRequestPtr &req,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            const auto token = bearerToken(req);
            if (token.empty()) {
                callback(utils::errorResponse("authorization required",
                                                k401Unauthorized));
                return;
            }
            const auto profile = services::authService().profileFromToken(token);
            if (!profile.has_value()) {
                callback(utils::errorResponse("invalid or expired session",
                                                k401Unauthorized));
                return;
            }

            if (req->method() == Get) {
                Json::Value body;
                body["productIds"] = Json::arrayValue;
                for (const auto &id :
                     services::authService().favoritesFromToken(token)) {
                    body["productIds"].append(id);
                }
                callback(utils::jsonResponse(body));
                return;
            }

            if (req->method() == Put) {
                auto json = req->getJsonObject();
                if (json == nullptr || !(*json).isMember("productIds") ||
                    !(*json)["productIds"].isArray()) {
                    callback(utils::errorResponse("productIds array required"));
                    return;
                }
                std::vector<std::string> ids;
                for (const auto &entry : (*json)["productIds"]) {
                    ids.push_back(entry.asString());
                }
                if (!services::authService().updateFavorites(token, ids)) {
                    callback(utils::errorResponse("could not update favorites"));
                    return;
                }
                Json::Value body;
                body["productIds"] = Json::arrayValue;
                for (const auto &id : ids) {
                    body["productIds"].append(id);
                }
                body["message"] = "favorites updated";
                callback(utils::jsonResponse(body));
                return;
            }

            callback(utils::errorResponse("method not allowed", k405MethodNotAllowed));
        },
        {Get, Put});
}

void registerAdminRoutes() {
    using namespace drogon;
    using nexus::middleware::authProfile;
    using nexus::middleware::isAdmin;
    using nexus::middleware::rejectForbidden;
    using nexus::middleware::rejectUnauthorized;

    app().registerHandler(
        "/api/admin/dashboard",
        [](const HttpRequestPtr &req,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            const auto profile = authProfile(req);
            if (!profile.has_value()) {
                rejectUnauthorized(callback);
                return;
            }
            if (!isAdmin(*profile)) {
                rejectForbidden(callback);
                return;
            }

            Json::Value body;
            body["productCount"] = gCatalog.productCount();
            body["orderCount"] = services::orderService().orderCount();
            body["userCount"] = services::authService().countUsers();
            body["totalRevenue"] = services::orderService().totalRevenue();
            body["dataSource"] = gCatalog.dataSourceLabel();
            callback(utils::jsonResponse(body));
        },
        {Get});

    app().registerHandler(
        "/api/admin/products",
        [](const HttpRequestPtr &req,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            const auto profile = authProfile(req);
            if (!profile.has_value()) {
                rejectUnauthorized(callback);
                return;
            }
            if (!isAdmin(*profile)) {
                rejectForbidden(callback);
                return;
            }

            if (req->method() == Get) {
                Json::Value body;
                body["products"] = gCatalog.productsArray();
                callback(utils::jsonResponse(body));
                return;
            }

            if (req->method() == Post) {
                auto json = req->getJsonObject();
                if (json == nullptr) {
                    callback(utils::errorResponse("JSON body required"));
                    return;
                }
                try {
                    Json::Value body;
                    body["product"] = gCatalog.createProduct(*json);
                    body["message"] = "product created";
                    callback(utils::jsonResponse(body, k201Created));
                } catch (const std::exception &ex) {
                    callback(utils::errorResponse(ex.what()));
                }
                return;
            }

            callback(utils::errorResponse("method not allowed", k405MethodNotAllowed));
        },
        {Get, Post});

    app().registerHandler(
        "/api/admin/products/{id}",
        [](const HttpRequestPtr &req,
           std::function<void(const HttpResponsePtr &)> &&callback,
           const std::string &id) {
            const auto profile = authProfile(req);
            if (!profile.has_value()) {
                rejectUnauthorized(callback);
                return;
            }
            if (!isAdmin(*profile)) {
                rejectForbidden(callback);
                return;
            }

            if (req->method() == Put) {
                auto json = req->getJsonObject();
                if (json == nullptr) {
                    callback(utils::errorResponse("JSON body required"));
                    return;
                }
                try {
                    Json::Value body;
                    body["product"] = gCatalog.updateProduct(id, *json);
                    body["message"] = "product updated";
                    callback(utils::jsonResponse(body));
                } catch (const std::exception &ex) {
                    callback(utils::errorResponse(ex.what()));
                }
                return;
            }

            if (req->method() == Delete) {
                try {
                    if (!gCatalog.deleteProduct(id)) {
                        callback(utils::errorResponse("product not found", k404NotFound));
                        return;
                    }
                    Json::Value body;
                    body["message"] = "product deleted";
                    body["id"] = id;
                    callback(utils::jsonResponse(body));
                } catch (const std::exception &ex) {
                    callback(utils::errorResponse(ex.what()));
                }
                return;
            }

            callback(utils::errorResponse("method not allowed", k405MethodNotAllowed));
        },
        {Put, Delete});

    app().registerHandler(
        "/api/admin/orders",
        [](const HttpRequestPtr &req,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            const auto profile = authProfile(req);
            if (!profile.has_value()) {
                rejectUnauthorized(callback);
                return;
            }
            if (!isAdmin(*profile)) {
                rejectForbidden(callback);
                return;
            }

            Json::Value body;
            body["orders"] = services::orderService().listAll();
            callback(utils::jsonResponse(body));
        },
        {Get});

    app().registerHandler(
        "/api/admin/orders/{id}/status",
        [](const HttpRequestPtr &req,
           std::function<void(const HttpResponsePtr &)> &&callback,
           const std::string &id) {
            const auto profile = authProfile(req);
            if (!profile.has_value()) {
                rejectUnauthorized(callback);
                return;
            }
            if (!isAdmin(*profile)) {
                rejectForbidden(callback);
                return;
            }

            auto json = req->getJsonObject();
            if (json == nullptr || !(*json).isMember("status")) {
                callback(utils::errorResponse("status is required"));
                return;
            }

            const auto status = (*json)["status"].asString();
            if (!services::orderService().updateStatus(id, status)) {
                callback(utils::errorResponse("order not found or invalid status",
                                                k404NotFound));
                return;
            }

            Json::Value body;
            body["message"] = "order status updated";
            body["id"] = id;
            body["status"] = status;
            callback(utils::jsonResponse(body));
        },
        {Patch});

    app().registerHandler(
        "/api/admin/seed",
        [](const HttpRequestPtr &req,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            const auto profile = authProfile(req);
            if (!profile.has_value()) {
                rejectUnauthorized(callback);
                return;
            }
            if (!isAdmin(*profile)) {
                rejectForbidden(callback);
                return;
            }
            if (!nexus::db::isEnabled()) {
                callback(utils::errorResponse(
                    "PostgreSQL required — set DATABASE_URL and restart API",
                    k503ServiceUnavailable));
                return;
            }
            try {
                repositories::catalogRepository().seedIfEmpty();
                gCatalog.refresh();
                Json::Value body;
                body["message"] = "catalog synced from seed into postgres";
                body["dataSource"] = gCatalog.dataSourceLabel();
                callback(utils::jsonResponse(body));
            } catch (const std::exception &ex) {
                callback(utils::errorResponse(ex.what()));
            }
        },
        {Post});
}

void registerFallbackRoutes() {
    using namespace drogon;

    app().registerHandler(
        "/api/{path}",
        [](const HttpRequestPtr &req,
           std::function<void(const HttpResponsePtr &)> &&callback,
           const std::string &) {
            if (req->method() == Options) {
                auto resp = HttpResponse::newHttpResponse();
                resp->setStatusCode(k204NoContent);
                middleware::addCors(resp);
                callback(resp);
                return;
            }
            callback(utils::errorResponse("not found", k404NotFound));
        },
        {Options});
}

}  // namespace

void registerRoutes() {
    registerRootRoute();
    registerSwaggerRoutes();
    registerHealthRoutes();
    registerCatalogRoutes();
    registerProductRoutes();
    registerBuilderRoutes();
    registerOrderRoutes();
    registerAuthRoutes();
    registerUserRoutes();
    registerAdminRoutes();
    registerFallbackRoutes();
}

}  // namespace nexus::routes
