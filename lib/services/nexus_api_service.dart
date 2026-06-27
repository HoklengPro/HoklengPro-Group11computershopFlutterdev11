import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/admin_models.dart';
import '../models/models.dart';
import '../models/user_session.dart';
import 'catalog_json.dart';

class NexusApiException implements Exception {
  NexusApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'NexusApiException($statusCode): $message';
}

class NexusApiService {
  NexusApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _authToken;

  void setAuthToken(String? token) => _authToken = token;

  Map<String, String> _headers({bool jsonBody = false}) {
    final headers = <String, String>{};
    if (jsonBody) {
      headers['Content-Type'] = 'application/json';
    }
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  String _errorMessage(http.Response response) {
    if (response.body.isEmpty) {
      return 'Request failed';
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } catch (_) {}
    return response.body;
  }

  Future<Map<String, dynamic>> _decodeJson(http.Response response) async {
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw NexusApiException(
        _errorMessage(response),
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw NexusApiException('Invalid JSON response');
    }
    return decoded;
  }

  UserSession _sessionFromAuthResponse(Map<String, dynamic> body) {
    final token = body['token'] as String? ?? '';
    final user = body['user'];
    if (token.isEmpty || user is! Map<String, dynamic>) {
      throw NexusApiException('Invalid auth response');
    }
    _authToken = token;
    return UserSession.fromJson(user, token: token);
  }

  Future<NexusCatalogSnapshot> fetchCatalog() async {
    final response = await _client
        .get(ApiConfig.uri('/api/catalog'))
        .timeout(const Duration(seconds: 12));
    return NexusCatalogSnapshot.fromJson(await _decodeJson(response));
  }

  Future<List<NexusSearchHit>> search(String query, {int limit = 20}) async {
    final response = await _client
        .get(
          ApiConfig.uri('/api/search').replace(
            queryParameters: {'q': query, 'limit': '$limit'},
          ),
        )
        .timeout(const Duration(seconds: 10));
    return searchHitsFromJson(await _decodeJson(response));
  }

  Future<DetailedOrderMock> fetchOrder(String id) async {
    final response = await _client
        .get(ApiConfig.uri('/api/orders/$id'))
        .timeout(const Duration(seconds: 10));
    return detailedOrderFromJson(await _decodeJson(response));
  }

  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client
        .post(
          ApiConfig.uri('/api/auth/login'),
          headers: _headers(jsonBody: true),
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 8));
    return _sessionFromAuthResponse(await _decodeJson(response));
  }

  Future<UserSession> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client
        .post(
          ApiConfig.uri('/api/auth/signup'),
          headers: _headers(jsonBody: true),
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 8));
    return _sessionFromAuthResponse(await _decodeJson(response));
  }

  Future<UserSession> fetchCurrentUser() async {
    final response = await _client
        .get(
          ApiConfig.uri('/api/auth/me'),
          headers: _headers(),
        )
        .timeout(const Duration(seconds: 8));
    final body = await _decodeJson(response);
    final user = body['user'];
    if (_authToken == null || _authToken!.isEmpty || user is! Map<String, dynamic>) {
      throw NexusApiException('Invalid session response');
    }
    return UserSession.fromJson(user, token: _authToken!);
  }

  Future<bool> healthCheck() async {
    final response = await _client
        .get(ApiConfig.uri('/api/health'))
        .timeout(const Duration(seconds: 5));
    return response.statusCode == 200;
  }

  Future<List<OrderSummary>> fetchOrders() async {
    final response = await _client
        .get(
          ApiConfig.uri('/api/orders'),
          headers: _headers(),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw NexusApiException(
        _errorMessage(response),
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw NexusApiException('Invalid orders response');
    }
    return decoded
        .map((e) => orderSummaryFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DetailedOrderMock> placeOrder(List<Map<String, dynamic>> items) async {
    final response = await _client
        .post(
          ApiConfig.uri('/api/orders'),
          headers: _headers(jsonBody: true),
          body: jsonEncode({'items': items}),
        )
        .timeout(const Duration(seconds: 12));
    final body = await _decodeJson(response);
    final order = body['order'];
    if (order is! Map<String, dynamic>) {
      throw NexusApiException('Invalid order response');
    }
    return detailedOrderFromJson(order);
  }

  Future<List<String>> fetchFavorites() async {
    final response = await _client
        .get(
          ApiConfig.uri('/api/users/me/favorites'),
          headers: _headers(),
        )
        .timeout(const Duration(seconds: 8));
    final body = await _decodeJson(response);
    final ids = body['productIds'] as List<dynamic>? ?? [];
    return ids.map((e) => e as String).toList();
  }

  Future<List<String>> syncFavorites(List<String> productIds) async {
    final response = await _client
        .put(
          ApiConfig.uri('/api/users/me/favorites'),
          headers: _headers(jsonBody: true),
          body: jsonEncode({'productIds': productIds}),
        )
        .timeout(const Duration(seconds: 8));
    final body = await _decodeJson(response);
    final ids = body['productIds'] as List<dynamic>? ?? [];
    return ids.map((e) => e as String).toList();
  }

  Future<AdminDashboardStats> fetchAdminDashboard() async {
    final response = await _client
        .get(
          ApiConfig.uri('/api/admin/dashboard'),
          headers: _headers(),
        )
        .timeout(const Duration(seconds: 10));
    return AdminDashboardStats.fromJson(await _decodeJson(response));
  }

  Future<List<Product>> fetchAdminProducts() async {
    final response = await _client
        .get(
          ApiConfig.uri('/api/admin/products'),
          headers: _headers(),
        )
        .timeout(const Duration(seconds: 12));
    final body = await _decodeJson(response);
    final products = body['products'] as List<dynamic>? ?? [];
    return products
        .map((e) => productFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Product> createAdminProduct(Map<String, dynamic> payload) async {
    final response = await _client
        .post(
          ApiConfig.uri('/api/admin/products'),
          headers: _headers(jsonBody: true),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 12));
    final body = await _decodeJson(response);
    final product = body['product'];
    if (product is! Map<String, dynamic>) {
      throw NexusApiException('Invalid product response');
    }
    return productFromJson(product);
  }

  Future<Product> updateAdminProduct(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client
        .put(
          ApiConfig.uri('/api/admin/products/$id'),
          headers: _headers(jsonBody: true),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 12));
    final body = await _decodeJson(response);
    final product = body['product'];
    if (product is! Map<String, dynamic>) {
      throw NexusApiException('Invalid product response');
    }
    return productFromJson(product);
  }

  Future<void> deleteAdminProduct(String id) async {
    final response = await _client
        .delete(
          ApiConfig.uri('/api/admin/products/$id'),
          headers: _headers(),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw NexusApiException(
        _errorMessage(response),
        statusCode: response.statusCode,
      );
    }
  }

  Future<List<AdminOrderRecord>> fetchAdminOrders() async {
    final response = await _client
        .get(
          ApiConfig.uri('/api/admin/orders'),
          headers: _headers(),
        )
        .timeout(const Duration(seconds: 12));
    final body = await _decodeJson(response);
    final orders = body['orders'] as List<dynamic>? ?? [];
    return orders
        .map((e) => AdminOrderRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateAdminOrderStatus(String id, String status) async {
    final response = await _client
        .patch(
          ApiConfig.uri('/api/admin/orders/$id/status'),
          headers: _headers(jsonBody: true),
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw NexusApiException(
        _errorMessage(response),
        statusCode: response.statusCode,
      );
    }
  }

  void dispose() => _client.close();
}
