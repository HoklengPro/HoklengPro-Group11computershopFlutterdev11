#pragma once
#include <json/json.h>
#include <optional>
#include <string>

namespace nexus::repositories {

class CatalogRepository {
public:
    enum class DataSource { Postgres, JsonFile };

    DataSource source() const { return source_; }

    Json::Value loadCatalog();
    bool seedIfEmpty();
    Json::Value insertProduct(const Json::Value &body);
    Json::Value updateProduct(const std::string &id, const Json::Value &body);
    bool deleteProduct(const std::string &id);
    void invalidateCache();

private:
    DataSource source_{DataSource::JsonFile};
    Json::Value cache_;
    bool cacheValid_{false};

    Json::Value loadFromPostgres();
    Json::Value loadFromJsonFile();
    bool seedFromJsonFile();
    Json::Value productRowToJson(const std::string &id,
                                 const std::string &name,
                                 const std::string &category,
                                 double price,
                                 const std::string &imageUrl,
                                 const std::string &specsJson,
                                 const std::string &benchmarksJson,
                                 bool isNew,
                                 bool isDeal,
                                 const std::string &configJson);

    Json::Value normalizeProductBody(const Json::Value &body,
                                     const std::string &fallbackId = "");
    bool writeCatalogJsonFile(const Json::Value &catalog);
    Json::Value upsertProductInJson(const Json::Value &body, bool mustExist);
    bool deleteProductFromJson(const std::string &id);
};

CatalogRepository &catalogRepository();

}  // namespace nexus::repositories
