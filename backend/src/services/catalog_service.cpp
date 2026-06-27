#include "nexus/services/catalog_service.h"
#include <algorithm>
#include <cctype>
#include <map>
#include "nexus/repositories/catalog_repository.h"

namespace nexus::services {
namespace {

std::string toLowerCopy(std::string value) {
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) {
        return static_cast<char>(std::tolower(c));
    });
    return value;
}

bool jsonContainsQuery(const Json::Value &value, const std::string &queryLower) {
    if (value.isString()) {
        return toLowerCopy(value.asString()).find(queryLower) != std::string::npos;
    }
    if (value.isNumeric()) {
        return toLowerCopy(value.asString()).find(queryLower) != std::string::npos;
    }
    if (value.isArray()) {
        for (const auto &item : value) {
            if (jsonContainsQuery(item, queryLower)) {
                return true;
            }
        }
        return false;
    }
    if (value.isObject()) {
        for (const auto &key : value.getMemberNames()) {
            if (toLowerCopy(key).find(queryLower) != std::string::npos) {
                return true;
            }
            if (jsonContainsQuery(value[key], queryLower)) {
                return true;
            }
        }
    }
    return false;
}

const std::map<std::string, std::string> &builderTypeMap() {
    static const std::map<std::string, std::string> map = {
        {"cpu", "cpus"},
        {"motherboard", "motherboards"},
        {"ram", "ram"},
        {"gpu", "gpus"},
        {"storage", "storage"},
        {"psu", "psus"},
        {"case", "cases"},
    };
    return map;
}

repositories::CatalogRepository &repo() {
    return repositories::catalogRepository();
}

}  // namespace

void CatalogService::ensureLoaded() const {
    if (loaded_) {
        return;
    }
    catalog_ = repo().loadCatalog();
    loaded_ = true;
}

void CatalogService::refresh() const {
    repo().invalidateCache();
    loaded_ = false;
    ensureLoaded();
}

const Json::Value &CatalogService::catalog() const {
    ensureLoaded();
    return catalog_;
}

Json::Value CatalogService::productsArray() const {
    const auto &cat = catalog();
    Json::Value all(Json::arrayValue);
    for (const auto &product : cat["featuredProducts"]) {
        all.append(product);
    }
    if (cat.isMember("buildOfTheMonth")) {
        all.append(cat["buildOfTheMonth"]);
    }
    return all;
}

Json::Value CatalogService::homePayload() const {
    const auto &cat = catalog();
    Json::Value home;
    home["heroSlides"] = cat["heroSlides"];
    home["categories"] = cat["categories"];
    home["marqueeBrands"] = cat["marqueeBrands"];
    home["featuredProducts"] = cat["featuredProducts"];
    home["buildOfTheMonth"] = cat["buildOfTheMonth"];
    return home;
}

Json::Value CatalogService::orderSummaries() const {
    const auto &orders = catalog()["orders"];
    Json::Value list(Json::arrayValue);
    for (const auto &id : orders.getMemberNames()) {
        list.append(orders[id]["summary"]);
    }
    return list;
}

const Json::Value *CatalogService::findProductById(const std::string &id) const {
    const auto &cat = catalog();
    if (cat.isMember("featuredProducts")) {
        for (const auto &product : cat["featuredProducts"]) {
            if (product["id"].asString() == id) {
                return &product;
            }
        }
    }
    if (cat.isMember("buildOfTheMonth") &&
        cat["buildOfTheMonth"]["id"].asString() == id) {
        return &cat["buildOfTheMonth"];
    }
    return nullptr;
}

const Json::Value *CatalogService::findOrderById(const std::string &id) const {
    const auto &orders = catalog()["orders"];
    if (!orders.isMember(id)) {
        return nullptr;
    }
    return &orders[id];
}

Json::Value CatalogService::builderParts(const std::string &typeFilter) const {
    const auto &builder = catalog()["builder"];
    if (typeFilter.empty()) {
        Json::Value flat(Json::arrayValue);
        for (const auto &key : builder.getMemberNames()) {
            for (const auto &part : builder[key]) {
                flat.append(part);
            }
        }
        return flat;
    }

    const auto &map = builderTypeMap();
    const auto it = map.find(typeFilter);
    if (it == map.end() || !builder.isMember(it->second)) {
        return Json::Value();
    }
    return builder[it->second];
}

Json::Value CatalogService::search(const std::string &query, int limit) const {
    Json::Value results(Json::arrayValue);
    if (query.empty()) {
        return results;
    }

    const auto queryLower = toLowerCopy(query);
    const int maxResults = std::max(1, std::min(limit, 50));

    for (const auto &product : productsArray()) {
        if (jsonContainsQuery(product, queryLower)) {
            Json::Value hit;
            hit["type"] = "product";
            hit["item"] = product;
            results.append(hit);
            if (static_cast<int>(results.size()) >= maxResults) {
                return results;
            }
        }
    }

    for (const auto &part : builderParts()) {
        if (jsonContainsQuery(part, queryLower)) {
            Json::Value hit;
            hit["type"] = "builder_part";
            hit["item"] = part;
            results.append(hit);
            if (static_cast<int>(results.size()) >= maxResults) {
                return results;
            }
        }
    }

    return results;
}

Json::Value CatalogService::createProduct(const Json::Value &body) const {
    auto product = repo().insertProduct(body);
    refresh();
    return product;
}

Json::Value CatalogService::updateProduct(const std::string &id,
                                          const Json::Value &body) const {
    auto product = repo().updateProduct(id, body);
    refresh();
    return product;
}

bool CatalogService::deleteProduct(const std::string &id) const {
    const bool removed = repo().deleteProduct(id);
    if (removed) {
        refresh();
    }
    return removed;
}

int CatalogService::productCount() const {
    return static_cast<int>(productsArray().size());
}

std::string CatalogService::dataSourceLabel() const {
    ensureLoaded();
    return repo().source() == repositories::CatalogRepository::DataSource::Postgres
               ? "postgres"
               : "json";
}

}  // namespace nexus::services
