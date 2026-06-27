import '../services/catalog_json.dart';
import 'models.dart';

class AdminDashboardStats {
  const AdminDashboardStats({
    required this.productCount,
    required this.orderCount,
    required this.userCount,
    required this.totalRevenue,
    required this.dataSource,
  });

  final int productCount;
  final int orderCount;
  final int userCount;
  final double totalRevenue;
  final String dataSource;

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) =>
      AdminDashboardStats(
        productCount: (json['productCount'] as num?)?.toInt() ?? 0,
        orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
        userCount: (json['userCount'] as num?)?.toInt() ?? 0,
        totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
        dataSource: json['dataSource'] as String? ?? 'json',
      );
}

class AdminOrderRecord {
  const AdminOrderRecord({
    required this.summary,
    required this.userId,
  });

  final OrderSummary summary;
  final String userId;

  factory AdminOrderRecord.fromJson(Map<String, dynamic> json) =>
      AdminOrderRecord(
        summary: orderSummaryFromJson(
          json['summary'] as Map<String, dynamic>,
        ),
        userId: json['userId'] as String? ?? '',
      );
}
