#include "nexus/services/order_service.h"
#include <chrono>
#include <fstream>
#include <iomanip>
#include <mutex>
#include <random>
#include <set>
#include <sstream>

namespace nexus::services {
namespace {
std::mutex gOrderMutex;
OrderService gOrders;

std::vector<std::string> ordersSearchPaths() {
    return {
        "data/orders.json",
        "../data/orders.json",
        "../../data/orders.json",
        "./orders.json",
        "/app/data/orders.json",
    };
}

Json::Value readOrdersRoot() {
    for (const auto &path : ordersSearchPaths()) {
        std::ifstream in(path);
        if (!in.is_open()) {
            continue;
        }
        Json::Value root;
        Json::CharReaderBuilder builder;
        std::string errs;
        if (Json::parseFromStream(builder, in, &root, &errs)) {
            if (!root.isMember("orders") || !root["orders"].isArray()) {
                root["orders"] = Json::arrayValue;
            }
            return root;
        }
    }
    Json::Value root;
    root["orders"] = Json::arrayValue;
    return root;
}

bool writeOrdersRoot(const Json::Value &root) {
    for (const auto &path : ordersSearchPaths()) {
        std::ofstream out(path, std::ios::trunc);
        if (!out.is_open()) {
            continue;
        }
        out << root.toStyledString();
        return true;
    }
    return false;
}

std::string todayIsoDate() {
    const auto now = std::chrono::system_clock::now();
    const std::time_t t = std::chrono::system_clock::to_time_t(now);
    std::tm tm{};
#if defined(_WIN32)
    localtime_s(&tm, &t);
#else
    localtime_r(&t, &tm);
#endif
    std::ostringstream oss;
    oss << std::put_time(&tm, "%Y-%m-%d");
    return oss.str();
}

std::string randomOrderId() {
    static std::mt19937 rng{static_cast<unsigned>(
        std::chrono::steady_clock::now().time_since_epoch().count())};
    static std::uniform_int_distribution<int> dist(1000, 9999);
    std::ostringstream oss;
    oss << "NX-" << dist(rng);
    return oss.str();
}

bool orderIdExists(const Json::Value &root, const std::string &id) {
    for (const auto &order : root["orders"]) {
        if (order.get("summary", Json::Value()).get("id", "").asString() == id) {
            return true;
        }
    }
    return false;
}

}  // namespace

OrderService &orderService() {
    return gOrders;
}

Json::Value OrderService::listForUser(const std::string &userId) const {
    std::lock_guard<std::mutex> lock(gOrderMutex);
    const auto root = readOrdersRoot();
    Json::Value list(Json::arrayValue);
    for (const auto &order : root["orders"]) {
        if (order.get("userId", "").asString() == userId) {
            list.append(order["summary"]);
        }
    }
    return list;
}

const Json::Value *OrderService::findByIdForUser(const std::string &orderId,
                                                 const std::string &userId) const {
    std::lock_guard<std::mutex> lock(gOrderMutex);
    const auto root = readOrdersRoot();
    for (const auto &order : root["orders"]) {
        if (order.get("userId", "").asString() != userId) {
            continue;
        }
        if (order.get("summary", Json::Value()).get("id", "").asString() == orderId) {
            return &order;
        }
    }
    return nullptr;
}

CreateOrderResult OrderService::createOrder(
    const std::string &userId,
    const std::vector<CreateOrderItem> &items) const {
    std::lock_guard<std::mutex> lock(gOrderMutex);
    CreateOrderResult result;
    if (userId.empty()) {
        result.message = "user required";
        return result;
    }
    if (items.empty()) {
        result.message = "cart is empty";
        return result;
    }

    auto root = readOrdersRoot();
    Json::Value order;
    order["userId"] = userId;

    std::string orderId;
    do {
        orderId = randomOrderId();
    } while (orderIdExists(root, orderId));

    Json::Value lines(Json::arrayValue);
    double total = 0.0;
    int itemCount = 0;
    for (const auto &item : items) {
        if (item.qty < 1) {
            result.message = "invalid quantity";
            return result;
        }
        Json::Value line;
        line["title"] = item.title.empty() ? item.productId : item.title;
        line["qty"] = item.qty;
        line["unitPrice"] = item.unitPrice;
        if (!item.productId.empty()) {
            line["productId"] = item.productId;
        }
        lines.append(line);
        total += item.unitPrice * item.qty;
        itemCount += item.qty;
    }

    Json::Value summary;
    summary["id"] = orderId;
    summary["date"] = todayIsoDate();
    summary["total"] = total;
    summary["status"] = "processing";
    summary["itemCount"] = itemCount;

    order["summary"] = summary;
    order["lines"] = lines;
    order["carrier"] = "NeoShip Apex";
    order["etaNote"] = "Processing · estimated 3–5 business days";
    order["trackingHints"] = Json::arrayValue;
    order["trackingHints"].append("Order received");
    order["trackingHints"].append("Payment confirmed");
    order["trackingHints"].append("Awaiting warehouse allocation");

    root["orders"].append(order);
    if (!writeOrdersRoot(root)) {
        result.message = "could not save order";
        return result;
    }

    result.ok = true;
    result.message = "order placed";
    result.order = order;
    return result;
}

Json::Value OrderService::listAll() const {
    std::lock_guard<std::mutex> lock(gOrderMutex);
    const auto root = readOrdersRoot();
    Json::Value list(Json::arrayValue);
    for (const auto &order : root["orders"]) {
        Json::Value entry;
        entry["summary"] = order["summary"];
        entry["userId"] = order.get("userId", "").asString();
        if (order.isMember("lines")) {
            entry["lines"] = order["lines"];
        }
        if (order.isMember("carrier")) {
            entry["carrier"] = order["carrier"];
        }
        if (order.isMember("etaNote")) {
            entry["etaNote"] = order["etaNote"];
        }
        list.append(entry);
    }
    return list;
}

const Json::Value *OrderService::findById(const std::string &orderId) const {
    std::lock_guard<std::mutex> lock(gOrderMutex);
    const auto root = readOrdersRoot();
    for (const auto &order : root["orders"]) {
        if (order.get("summary", Json::Value()).get("id", "").asString() == orderId) {
            return &order;
        }
    }
    return nullptr;
}

bool OrderService::updateStatus(const std::string &orderId,
                                const std::string &status) const {
    static const std::set<std::string> kAllowed = {
        "processing", "shipped", "delivered", "cancelled"};
    if (kAllowed.find(status) == kAllowed.end()) {
        return false;
    }

    std::lock_guard<std::mutex> lock(gOrderMutex);
    auto root = readOrdersRoot();
    for (auto &order : root["orders"]) {
        if (order.get("summary", Json::Value()).get("id", "").asString() != orderId) {
            continue;
        }
        order["summary"]["status"] = status;
        if (status == "shipped") {
            order["etaNote"] = "In transit · carrier pickup confirmed";
        } else if (status == "delivered") {
            order["etaNote"] = "Delivered · signed at destination";
        } else if (status == "cancelled") {
            order["etaNote"] = "Order cancelled by admin";
        } else {
            order["etaNote"] = "Processing · estimated 3–5 business days";
        }
        return writeOrdersRoot(root);
    }
    return false;
}

int OrderService::orderCount() const {
    std::lock_guard<std::mutex> lock(gOrderMutex);
    const auto root = readOrdersRoot();
    return static_cast<int>(root["orders"].size());
}

double OrderService::totalRevenue() const {
    std::lock_guard<std::mutex> lock(gOrderMutex);
    const auto root = readOrdersRoot();
    double total = 0.0;
    for (const auto &order : root["orders"]) {
        const auto status =
            order.get("summary", Json::Value()).get("status", "").asString();
        if (status == "cancelled") {
            continue;
        }
        total += order.get("summary", Json::Value()).get("total", 0.0).asDouble();
    }
    return total;
}

}  // namespace nexus::services
