#include "nexus/repositories/catalog_repository.h"
#include <drogon/drogon.h>
#include <drogon/orm/DbClient.h>
#include <fstream>
#include <json/json.h>
#include <mutex>
#include <optional>
#include <sstream>
#include "nexus/db/database.h"

namespace nexus::repositories {
namespace {

std::mutex gRepoMutex;
CatalogRepository gRepo;

Json::Value parseJsonText(const std::string &text) {
    Json::Value value;
    Json::CharReaderBuilder builder;
    std::string errs;
    std::istringstream stream(text);
    if (!Json::parseFromStream(builder, stream, &value, &errs)) {
        throw std::runtime_error("Invalid JSON from database: " + errs);
    }
    return value;
}

std::vector<std::string> catalogSearchPaths() {
    return {
        "data/catalog.json",
        "../data/catalog.json",
        "../../data/catalog.json",
        "./catalog.json",
        "/app/data/catalog.json",
    };
}

Json::Value readCatalogJsonFile() {
    for (const auto &path : catalogSearchPaths()) {
        std::ifstream in(path);
        if (!in.is_open()) {
            continue;
        }
        Json::Value catalog;
        Json::CharReaderBuilder builder;
        std::string errs;
        if (Json::parseFromStream(builder, in, &catalog, &errs)) {
            LOG_INFO << "Loaded seed catalog from " << path;
            return catalog;
        }
    }
    throw std::runtime_error("Could not load catalog.json for seed/fallback");
}

drogon::orm::DbClientPtr dbClient() {
    return drogon::app().getDbClient();
}

std::string jsonOrNullMember(const Json::Value &obj, const char *key) {
    if (!obj.isMember(key) || obj[key].isNull()) {
        return "";
    }
    return obj[key].asString();
}

}  // namespace

CatalogRepository &catalogRepository() {
    return gRepo;
}

Json::Value CatalogRepository::productRowToJson(
    const std::string &id,
    const std::string &name,
    const std::string &category,
    double price,
    const std::string &imageUrl,
    const std::string &specsJson,
    const std::string &benchmarksJson,
    bool isNew,
    bool isDeal,
    const std::string &configJson) {
    Json::Value product;
    product["id"] = id;
    product["name"] = name;
    product["category"] = category;
    product["price"] = price;
    product["image"] = imageUrl;
    product["specs"] = parseJsonText(specsJson.empty() ? "{}" : specsJson);
    if (!benchmarksJson.empty() && benchmarksJson != "null") {
        product["benchmarks"] = parseJsonText(benchmarksJson);
    }
    product["isNew"] = isNew;
    product["isDeal"] = isDeal;
    if (!configJson.empty() && configJson != "null") {
        product["configOptions"] = parseJsonText(configJson);
    }
    return product;
}

Json::Value CatalogRepository::loadFromJsonFile() {
    source_ = DataSource::JsonFile;
    return readCatalogJsonFile();
}

Json::Value CatalogRepository::loadFromPostgres() {
    source_ = DataSource::Postgres;
    auto client = dbClient();
    Json::Value catalog;

    Json::Value featured(Json::arrayValue);
    Json::Value botm;
    bool hasBotm = false;

    auto products = client->execSqlSync(
        "SELECT id, name, category, price, image_url, specs::text, benchmarks::text, "
        "is_new, is_deal, config_options::text, product_role "
        "FROM products ORDER BY sort_order, created_at");

    for (const auto &row : products) {
        const auto role = row["product_role"].as<std::string>();
        const auto product = productRowToJson(
            row["id"].as<std::string>(),
            row["name"].as<std::string>(),
            row["category"].as<std::string>(),
            row["price"].as<double>(),
            row["image_url"].as<std::string>(),
            row["specs"].as<std::string>(),
            row["benchmarks"].isNull() ? "" : row["benchmarks"].as<std::string>(),
            row["is_new"].as<bool>(),
            row["is_deal"].as<bool>(),
            row["config_options"].isNull() ? "" : row["config_options"].as<std::string>());

        if (role == "botm") {
            botm = product;
            hasBotm = true;
        } else {
            featured.append(product);
        }
    }
    catalog["featuredProducts"] = featured;
    if (hasBotm) {
        catalog["buildOfTheMonth"] = botm;
    }

    auto sections = client->execSqlSync(
        "SELECT section_key, payload::text FROM catalog_sections ORDER BY section_key");
    for (const auto &row : sections) {
        catalog[row["section_key"].as<std::string>()] =
            parseJsonText(row["payload"].as<std::string>());
    }

    Json::Value builder(Json::objectValue);
    auto parts = client->execSqlSync(
        "SELECT id, part_type, name, brand, price, image_url, attributes::text "
        "FROM builder_parts ORDER BY part_type, name");
    for (const auto &row : parts) {
        const auto type = row["part_type"].as<std::string>();
        Json::Value part = parseJsonText(row["attributes"].as<std::string>());
        part["id"] = row["id"].as<std::string>();
        part["partType"] = type;
        part["name"] = row["name"].as<std::string>();
        part["brand"] = row["brand"].as<std::string>();
        part["price"] = row["price"].as<double>();
        part["image"] = row["image_url"].as<std::string>();

        std::string bucket;
        if (type == "cpu") {
            bucket = "cpus";
        } else if (type == "motherboard") {
            bucket = "motherboards";
        } else if (type == "ram") {
            bucket = "ram";
        } else if (type == "gpu") {
            bucket = "gpus";
        } else if (type == "storage") {
            bucket = "storage";
        } else if (type == "psu") {
            bucket = "psus";
        } else if (type == "case") {
            bucket = "cases";
        } else {
            bucket = type + "s";
        }
        if (!builder.isMember(bucket)) {
            builder[bucket] = Json::arrayValue;
        }
        builder[bucket].append(part);
    }
    if (!builder.empty()) {
        catalog["builder"] = builder;
    }

    Json::Value orders(Json::objectValue);
    auto orderRows = client->execSqlSync(
        "SELECT id, order_date::text, total, status, item_count, carrier, eta_note, "
        "tracking_hints::text FROM orders ORDER BY order_date DESC");
    for (const auto &row : orderRows) {
        const auto orderId = row["id"].as<std::string>();
        Json::Value detail;
        Json::Value summary;
        summary["id"] = orderId;
        summary["date"] = row["order_date"].as<std::string>().substr(0, 10);
        summary["total"] = row["total"].as<double>();
        summary["status"] = row["status"].as<std::string>();
        summary["itemCount"] = row["item_count"].as<int>();
        detail["summary"] = summary;
        if (!row["carrier"].isNull()) {
            detail["carrier"] = row["carrier"].as<std::string>();
        }
        if (!row["eta_note"].isNull()) {
            detail["etaNote"] = row["eta_note"].as<std::string>();
        }
        detail["trackingHints"] =
            parseJsonText(row["tracking_hints"].as<std::string>());

        Json::Value lines(Json::arrayValue);
        auto lineRows = client->execSqlSync(
            "SELECT title, qty, unit_price FROM order_lines WHERE order_id=$1 ORDER BY id",
            orderId);
        for (const auto &line : lineRows) {
            Json::Value item;
            item["title"] = line["title"].as<std::string>();
            item["qty"] = line["qty"].as<int>();
            item["unitPrice"] = line["unit_price"].as<double>();
            lines.append(item);
        }
        detail["lines"] = lines;
        orders[orderId] = detail;
    }
    if (!orders.empty()) {
        catalog["orders"] = orders;
    }

    return catalog;
}

bool CatalogRepository::seedFromJsonFile() {
    if (!nexus::db::isEnabled()) {
        return false;
    }

    auto client = dbClient();
    const Json::Value seed = readCatalogJsonFile();
    LOG_INFO << "Syncing PostgreSQL catalog from catalog.json seed";

    for (const auto &product : seed["featuredProducts"]) {
        client->execSqlSync(
            "INSERT INTO products (id, name, category, price, image_url, specs, benchmarks, "
            "is_new, is_deal, config_options, product_role, sort_order) "
            "VALUES ($1,$2,$3,$4,$5,$6::jsonb,$7::jsonb,$8,$9,$10::jsonb,$11,$12) "
            "ON CONFLICT (id) DO NOTHING",
            product["id"].asString(),
            product["name"].asString(),
            product["category"].asString(),
            product["price"].asDouble(),
            product["image"].asString(),
            product["specs"].toStyledString(),
            product.isMember("benchmarks") ? product["benchmarks"].toStyledString()
                                           : std::string("null"),
            product.get("isNew", false).asBool(),
            product.get("isDeal", false).asBool(),
            product.isMember("configOptions") ? product["configOptions"].toStyledString()
                                              : std::string("null"),
            std::string("featured"),
            0);
    }

    if (seed.isMember("buildOfTheMonth")) {
        const auto &product = seed["buildOfTheMonth"];
        client->execSqlSync(
            "INSERT INTO products (id, name, category, price, image_url, specs, benchmarks, "
            "is_new, is_deal, config_options, product_role, sort_order) "
            "VALUES ($1,$2,$3,$4,$5,$6::jsonb,$7::jsonb,$8,$9,$10::jsonb,$11,$12) "
            "ON CONFLICT (id) DO UPDATE SET product_role=EXCLUDED.product_role",
            product["id"].asString(),
            product["name"].asString(),
            product["category"].asString(),
            product["price"].asDouble(),
            product["image"].asString(),
            product["specs"].toStyledString(),
            product.isMember("benchmarks") ? product["benchmarks"].toStyledString()
                                           : std::string("null"),
            product.get("isNew", false).asBool(),
            product.get("isDeal", false).asBool(),
            product.isMember("configOptions") ? product["configOptions"].toStyledString()
                                              : std::string("null"),
            std::string("botm"),
            0);
    }

    for (const auto *key :
         {"heroSlides", "categories", "marqueeBrands", "content"}) {
        if (!seed.isMember(key)) {
            continue;
        }
        client->execSqlSync(
            "INSERT INTO catalog_sections (section_key, payload) VALUES ($1, $2::jsonb) "
            "ON CONFLICT (section_key) DO UPDATE SET payload=EXCLUDED.payload, "
            "updated_at=NOW()",
            std::string(key),
            seed[key].toStyledString());
    }

    if (seed.isMember("builder")) {
        const auto &builder = seed["builder"];
        for (const auto &bucket : builder.getMemberNames()) {
            for (const auto &part : builder[bucket]) {
                client->execSqlSync(
                    "INSERT INTO builder_parts (id, part_type, name, brand, price, image_url, "
                    "attributes) VALUES ($1,$2,$3,$4,$5,$6,$7::jsonb) "
                    "ON CONFLICT (id) DO UPDATE SET "
                    "part_type=EXCLUDED.part_type, name=EXCLUDED.name, brand=EXCLUDED.brand, "
                    "price=EXCLUDED.price, image_url=EXCLUDED.image_url, "
                    "attributes=EXCLUDED.attributes",
                    part["id"].asString(),
                    part["partType"].asString(),
                    part["name"].asString(),
                    part["brand"].asString(),
                    part["price"].asDouble(),
                    part["image"].asString(),
                    part.toStyledString());
            }
        }
    }

    if (seed.isMember("orders")) {
        const auto &orders = seed["orders"];
        for (const auto &orderId : orders.getMemberNames()) {
            const auto &detail = orders[orderId];
            const auto &summary = detail["summary"];
            const auto carrier = jsonOrNullMember(detail, "carrier");
            const auto eta = jsonOrNullMember(detail, "etaNote");

            if (carrier.empty() && eta.empty()) {
                client->execSqlSync(
                    "INSERT INTO orders (id, order_date, total, status, item_count, "
                    "tracking_hints) "
                    "VALUES ($1,$2::date,$3,$4,$5,$6::jsonb) ON CONFLICT (id) DO NOTHING",
                    summary["id"].asString(),
                    summary["date"].asString(),
                    summary["total"].asDouble(),
                    summary["status"].asString(),
                    summary["itemCount"].asInt(),
                    detail["trackingHints"].toStyledString());
            } else {
                client->execSqlSync(
                    "INSERT INTO orders (id, order_date, total, status, item_count, carrier, "
                    "eta_note, tracking_hints) "
                    "VALUES ($1,$2::date,$3,$4,$5,$6,$7,$8::jsonb) ON CONFLICT (id) DO NOTHING",
                    summary["id"].asString(),
                    summary["date"].asString(),
                    summary["total"].asDouble(),
                    summary["status"].asString(),
                    summary["itemCount"].asInt(),
                    carrier,
                    eta,
                    detail["trackingHints"].toStyledString());
            }

            for (const auto &line : detail["lines"]) {
                client->execSqlSync(
                    "INSERT INTO order_lines (order_id, title, qty, unit_price) "
                    "SELECT $1,$2,$3,$4 WHERE NOT EXISTS ("
                    "SELECT 1 FROM order_lines WHERE order_id=$1 AND title=$2 AND qty=$3)",
                    summary["id"].asString(),
                    line["title"].asString(),
                    line["qty"].asInt(),
                    line["unitPrice"].asDouble());
            }
        }
    }

    LOG_INFO << "PostgreSQL seed sync complete";
    return true;
}

bool CatalogRepository::seedIfEmpty() {
    std::lock_guard<std::mutex> lock(gRepoMutex);
    if (!nexus::db::isEnabled()) {
        return false;
    }
    return seedFromJsonFile();
}

void CatalogRepository::invalidateCache() {
    std::lock_guard<std::mutex> lock(gRepoMutex);
    cacheValid_ = false;
}

Json::Value CatalogRepository::loadCatalog() {
    std::lock_guard<std::mutex> lock(gRepoMutex);
    if (cacheValid_) {
        return cache_;
    }

    if (nexus::db::isEnabled()) {
        seedFromJsonFile();
        cache_ = loadFromPostgres();
    } else {
        cache_ = loadFromJsonFile();
    }
    cacheValid_ = true;
    return cache_;
}

Json::Value CatalogRepository::insertProduct(const Json::Value &body) {
    if (nexus::db::isEnabled()) {
        if (!body.isMember("id") || !body.isMember("name") || !body.isMember("category") ||
            !body.isMember("price") || !body.isMember("image")) {
            throw std::runtime_error("id, name, category, price, image are required");
        }

        const auto role =
            body.get("productRole", "featured").asString();
        const auto specs =
            body.isMember("specs") ? body["specs"].toStyledString() : std::string("{}");
        const auto benchmarks = body.isMember("benchmarks")
                                    ? body["benchmarks"].toStyledString()
                                    : std::string("null");
        const auto config = body.isMember("configOptions")
                                ? body["configOptions"].toStyledString()
                                : std::string("null");

        auto client = dbClient();
        client->execSqlSync(
            "INSERT INTO products (id, name, category, price, image_url, specs, benchmarks, "
            "is_new, is_deal, config_options, product_role, sort_order) "
            "VALUES ($1,$2,$3,$4,$5,$6::jsonb,$7::jsonb,$8,$9,$10::jsonb,$11,$12) "
            "ON CONFLICT (id) DO UPDATE SET "
            "name=EXCLUDED.name, category=EXCLUDED.category, price=EXCLUDED.price, "
            "image_url=EXCLUDED.image_url, specs=EXCLUDED.specs, benchmarks=EXCLUDED.benchmarks, "
            "is_new=EXCLUDED.is_new, is_deal=EXCLUDED.is_deal, "
            "config_options=EXCLUDED.config_options, product_role=EXCLUDED.product_role",
            body["id"].asString(),
            body["name"].asString(),
            body["category"].asString(),
            body["price"].asDouble(),
            body["image"].asString(),
            specs,
            benchmarks,
            body.get("isNew", false).asBool(),
            body.get("isDeal", false).asBool(),
            config,
            role,
            body.get("sortOrder", 0).asInt());

        invalidateCache();
        return productRowToJson(
            body["id"].asString(),
            body["name"].asString(),
            body["category"].asString(),
            body["price"].asDouble(),
            body["image"].asString(),
            specs,
            benchmarks == "null" ? "" : benchmarks,
            body.get("isNew", false).asBool(),
            body.get("isDeal", false).asBool(),
            config == "null" ? "" : config);
    }

    std::lock_guard<std::mutex> lock(gRepoMutex);
    const auto product = upsertProductInJson(body, false);
    cacheValid_ = false;
    return product;
}

Json::Value CatalogRepository::normalizeProductBody(const Json::Value &body,
                                                    const std::string &fallbackId) {
    if (!body.isMember("name") || !body.isMember("category") || !body.isMember("price") ||
        !body.isMember("image")) {
        throw std::runtime_error("name, category, price, image are required");
    }

    Json::Value product;
    const auto id = body.isMember("id") ? body["id"].asString() : fallbackId;
    if (id.empty()) {
        throw std::runtime_error("product id is required");
    }

    product["id"] = id;
    product["name"] = body["name"].asString();
    product["category"] = body["category"].asString();
    product["price"] = body["price"].asDouble();
    product["image"] = body["image"].asString();
    product["specs"] = body.isMember("specs") ? body["specs"] : Json::Value(Json::objectValue);
    if (body.isMember("benchmarks")) {
        product["benchmarks"] = body["benchmarks"];
    }
    product["isNew"] = body.get("isNew", false).asBool();
    product["isDeal"] = body.get("isDeal", false).asBool();
    if (body.isMember("configOptions")) {
        product["configOptions"] = body["configOptions"];
    }
    return product;
}

bool CatalogRepository::writeCatalogJsonFile(const Json::Value &catalog) {
    for (const auto &path : catalogSearchPaths()) {
        std::ofstream out(path, std::ios::trunc);
        if (!out.is_open()) {
            continue;
        }
        out << catalog.toStyledString();
        LOG_INFO << "Saved catalog to " << path;
        return true;
    }
    return false;
}

Json::Value CatalogRepository::upsertProductInJson(const Json::Value &body, bool mustExist) {
    auto catalog = readCatalogJsonFile();
    const auto product = normalizeProductBody(body);
    const auto productId = product["id"].asString();

    if (catalog.isMember("buildOfTheMonth") &&
        catalog["buildOfTheMonth"].get("id", "").asString() == productId) {
        catalog["buildOfTheMonth"] = product;
        if (!writeCatalogJsonFile(catalog)) {
            throw std::runtime_error("could not save catalog");
        }
        return product;
    }

    if (!catalog.isMember("featuredProducts") || !catalog["featuredProducts"].isArray()) {
        catalog["featuredProducts"] = Json::arrayValue;
    }

    auto &featured = catalog["featuredProducts"];
    for (auto &existing : featured) {
        if (existing.get("id", "").asString() == productId) {
            if (!mustExist) {
                for (const auto &key : product.getMemberNames()) {
                    existing[key] = product[key];
                }
            } else {
                for (const auto &key : product.getMemberNames()) {
                    existing[key] = product[key];
                }
            }
            if (!writeCatalogJsonFile(catalog)) {
                throw std::runtime_error("could not save catalog");
            }
            return existing;
        }
    }

    if (mustExist) {
        throw std::runtime_error("product not found");
    }

    featured.append(product);
    if (!writeCatalogJsonFile(catalog)) {
        throw std::runtime_error("could not save catalog");
    }
    return product;
}

bool CatalogRepository::deleteProductFromJson(const std::string &id) {
    auto catalog = readCatalogJsonFile();

    if (catalog.isMember("buildOfTheMonth") &&
        catalog["buildOfTheMonth"].get("id", "").asString() == id) {
        throw std::runtime_error("cannot delete build of the month product");
    }

    if (!catalog.isMember("featuredProducts") || !catalog["featuredProducts"].isArray()) {
        return false;
    }

    auto &featured = catalog["featuredProducts"];
    Json::Value next(Json::arrayValue);
    bool removed = false;
    for (const auto &product : featured) {
        if (product.get("id", "").asString() == id) {
            removed = true;
            continue;
        }
        next.append(product);
    }

    if (!removed) {
        return false;
    }

    catalog["featuredProducts"] = next;
    if (!writeCatalogJsonFile(catalog)) {
        throw std::runtime_error("could not save catalog");
    }
    return true;
}

Json::Value CatalogRepository::updateProduct(const std::string &id, const Json::Value &body) {
    if (nexus::db::isEnabled()) {
        Json::Value payload = body;
        payload["id"] = id;
        return insertProduct(payload);
    }

    std::lock_guard<std::mutex> lock(gRepoMutex);
    Json::Value payload = body;
    payload["id"] = id;
    const auto product = upsertProductInJson(payload, true);
    cacheValid_ = false;
    return product;
}

bool CatalogRepository::deleteProduct(const std::string &id) {
    if (nexus::db::isEnabled()) {
        auto client = dbClient();
        auto result = client->execSqlSync("DELETE FROM products WHERE id=$1", id);
        if (result.affectedRows() == 0) {
            return false;
        }
        invalidateCache();
        return true;
    }

    std::lock_guard<std::mutex> lock(gRepoMutex);
    const bool removed = deleteProductFromJson(id);
    if (removed) {
        cacheValid_ = false;
    }
    return removed;
}

}  // namespace nexus::repositories
