#pragma once
#include <json/json.h>
#include <optional>
#include <string>
#include <vector>

namespace nexus::services {

struct CreateOrderItem {
    std::string productId;
    std::string title;
    int qty{1};
    double unitPrice{0.0};
};

struct CreateOrderResult {
    bool ok{false};
    std::string message;
    Json::Value order;
};

class OrderService {
public:
    Json::Value listForUser(const std::string &userId) const;
    const Json::Value *findByIdForUser(const std::string &orderId,
                                       const std::string &userId) const;

    CreateOrderResult createOrder(const std::string &userId,
                                  const std::vector<CreateOrderItem> &items) const;

    Json::Value listAll() const;
    const Json::Value *findById(const std::string &orderId) const;
    bool updateStatus(const std::string &orderId, const std::string &status) const;
    int orderCount() const;
    double totalRevenue() const;
};

OrderService &orderService();

}  // namespace nexus::services
