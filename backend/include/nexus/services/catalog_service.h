#pragma once
#include <json/json.h>
#include <string>

namespace nexus::services {
class CatalogService {
public:
    const Json::Value &catalog() const;
    Json::Value productsArray() const;
    Json::Value homePayload() const;
    Json::Value orderSummaries() const;

    const Json::Value *findProductById(const std::string &id) const;
    const Json::Value *findOrderById(const std::string &id) const;

    Json::Value builderParts(const std::string &typeFilter = "") const;
    Json::Value search(const std::string &query, int limit = 20) const;

    Json::Value createProduct(const Json::Value &body) const;
    Json::Value updateProduct(const std::string &id, const Json::Value &body) const;
    bool deleteProduct(const std::string &id) const;
    int productCount() const;
    std::string dataSourceLabel() const;
    void refresh() const;

private:
    mutable Json::Value catalog_;
    mutable bool loaded_{false};

    void ensureLoaded() const;
};

}  // namespace nexus::services
