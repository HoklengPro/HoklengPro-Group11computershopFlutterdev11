import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin_models.dart';
import '../models/catalog_models.dart';
import '../models/models.dart';
import '../models/view_state.dart';
import '../models/user_session.dart';
import '../services/catalog_json.dart';
import '../services/nexus_api_service.dart';

class NexusController extends ChangeNotifier {
  NexusController(this._prefs, {NexusApiService? api})
      : _api = api ?? NexusApiService() {
    currentView = ViewState.home;
    _loadUserSettings();
  }

  static const String kHasSeenOnboarding = 'hasSeenOnboarding';
  static const String kRecentSearches = 'recentSearches';
  static const String kAuthToken = 'authToken';
  static const String kAuthUser = 'authUser';
  static const String kCartItems = 'cartItems';
  static const String kDarkTheme = 'isDarkTheme';
  static const String kFlashDealAlerts = 'flashDealAlerts';
  static const String kSecureCheckout = 'secureCheckout';
  final SharedPreferences _prefs;
  final NexusApiService _api;

  UserSession? currentUser;

  bool isLoadingCatalog = true;
  String? catalogError;
  NexusCatalogSnapshot? _catalog;

  bool isDarkTheme = true;
  bool flashDealAlerts = true;
  bool secureCheckout = false;
  bool? backendOnline;
  ViewState currentView = ViewState.onboarding;
  Map<String, dynamic>? viewParams;

  final List<CartItem> cart = [];
  List<String> favorites = [];
  final List<BuilderState> savedBuilds = [];
  List<NotificationEntry> notifications = [];

  final Map<String, DetailedOrderMock> _orderDetailOverrides = {};
  List<OrderSummary> userOrders = [];
  bool isLoadingOrders = false;
  String? ordersError;
  bool isPlacingOrder = false;
  bool isLoadingOrder = false;
  String? orderLoadError;

  bool get isCatalogReady => _catalog != null;

  bool get isSignedIn => currentUser != null;

  bool get isAdmin => currentUser?.isAdmin ?? false;

  AdminDashboardStats? adminDashboard;
  List<Product> adminProducts = [];
  List<AdminOrderRecord> adminOrders = [];
  bool isLoadingAdmin = false;
  String? adminError;

  AccountProfileSpec get accountProfile {
    final user = currentUser;
    if (user != null) {
      return AccountProfileSpec(
        displayName: user.displayName.toUpperCase(),
        initials: user.initials,
        tier: user.tier,
      );
    }
    return const AccountProfileSpec(
      displayName: 'GUEST',
      initials: 'G',
      tier: 'Sign in to sync your profile and orders',
    );
  }

  List<Product> get featuredProducts => _catalog?.featuredProducts ?? const [];

  Product? get buildOfTheMonthProduct => _catalog?.buildOfTheMonthProduct;

  List<Product> get allCatalogProducts => _catalog?.allCatalogProducts ?? const [];

  List<HeroSlideSpec> get heroSlides => _catalog?.heroSlides ?? const [];

  List<BrandMarqueeSpec> get marqueeBrands => _catalog?.marqueeBrands ?? const [];

  List<CategorySpec> get categoryTiles => _catalog?.categoryTiles ?? const [];

  List<NexusBuilderPart> get allBuilderParts => _catalog?.allBuilderParts ?? const [];

  BuilderCatalogData? get builderCatalog => _catalog?.builderCatalog;

  NexusContentBundle get content =>
      _catalog?.content ?? NexusContentBundle.empty();

  Map<String, DetailedOrderMock> get orderCatalog =>
      _catalog?.orderCatalog ?? const {};

  List<OrderSummary> listOrdersByDate() {
    if (isSignedIn) {
      final sorted = List<OrderSummary>.from(userOrders);
      sorted.sort((a, b) => b.date.compareTo(a.date));
      return sorted;
    }
    return _catalog?.listOrdersByDate() ?? const [];
  }

  DetailedOrderMock? orderDetailById(String? id) {
    if (id == null || id.isEmpty) return null;
    return _orderDetailOverrides[id] ?? _catalog?.orderDetailById(id);
  }

  List<String> get recentSearches =>
      _prefs.getStringList(kRecentSearches) ?? content.searchHints;

  int get cartCount => cart.fold(0, (a, item) => a + item.qty);

  double get cartSubtotal =>
      cart.fold(0, (double sum, item) => sum + item.price * item.qty);

  int get unreadNotificationsCount =>
      notifications.where((n) => !n.read).length;

  Brightness get brightness =>
      isDarkTheme ? Brightness.dark : Brightness.light;

  Future<void> loadCatalog() async {
    isLoadingCatalog = true;
    catalogError = null;
    notifyListeners();
    try {
      await restoreSession();
      await _loadCartFromPrefs();
      _catalog = await _api.fetchCatalog();
      notifications = List<NotificationEntry>.from(content.notifications);
      isLoadingCatalog = false;
      notifyListeners();
    } catch (e) {
      catalogError = e.toString();
      isLoadingCatalog = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> ensureCartLoaded() async {
    await _loadCartFromPrefs();
    notifyListeners();
  }

  Future<void> _loadCartFromPrefs() async {
    final raw = _prefs.getString(kCartItems);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      cart
        ..clear()
        ..addAll(
          list.map((e) {
            final m = e as Map<String, dynamic>;
            return CartItem(
              id: m['id'] as String,
              productId: m['productId'] as String,
              qty: (m['qty'] as num).toInt(),
              price: (m['price'] as num).toDouble(),
            );
          }),
        );
    } catch (_) {}
  }

  Future<void> _persistCart() async {
    final payload = cart
        .map((e) => {
              'id': e.id,
              'productId': e.productId,
              'qty': e.qty,
              'price': e.price,
            })
        .toList();
    await _prefs.setString(kCartItems, jsonEncode(payload));
  }

  Future<void> restoreSession() async {
    final token = _prefs.getString(kAuthToken);
    final userJson = _prefs.getString(kAuthUser);
    if (token == null || token.isEmpty || userJson == null || userJson.isEmpty) {
      currentUser = null;
      _api.setAuthToken(null);
      return;
    }

    _api.setAuthToken(token);
    try {
      currentUser = await _api.fetchCurrentUser();
      await _persistSession(currentUser!);
      await _loadFavoritesFromBackend();
      await refreshOrders();
    } catch (_) {
      final decoded = jsonDecode(userJson);
      if (decoded is Map<String, dynamic>) {
        currentUser = UserSession.fromJson(decoded, token: token);
      } else {
        await clearSession();
      }
    }
  }

  Future<void> _persistSession(UserSession session) async {
    _api.setAuthToken(session.token);
    await _prefs.setString(kAuthToken, session.token);
    await _prefs.setString(kAuthUser, jsonEncode(session.toJson()));
    currentUser = session;
    notifyListeners();
  }

  Future<void> clearSession() async {
    currentUser = null;
    userOrders = [];
    _api.setAuthToken(null);
    await _prefs.remove(kAuthToken);
    await _prefs.remove(kAuthUser);
    notifyListeners();
  }

  Future<void> _loadFavoritesFromBackend() async {
    if (!isSignedIn) return;
    try {
      favorites = await _api.fetchFavorites();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshOrders() async {
    if (!isSignedIn) {
      userOrders = [];
      notifyListeners();
      return;
    }
    isLoadingOrders = true;
    ordersError = null;
    notifyListeners();
    try {
      userOrders = await _api.fetchOrders();
    } catch (e) {
      ordersError = e.toString();
    } finally {
      isLoadingOrders = false;
      notifyListeners();
    }
  }

  Future<DetailedOrderMock> placeOrderFromCart() async {
    if (!isSignedIn) {
      throw NexusApiException('Sign in required to checkout');
    }
    if (cart.isEmpty) {
      throw NexusApiException('Cart is empty');
    }
    isPlacingOrder = true;
    notifyListeners();
    try {
      final items = cart.map((item) {
        final product = productById(item.productId) ??
            featuredById(item.productId);
        return {
          'productId': item.productId,
          'title': product?.name ?? 'Custom item',
          'qty': item.qty,
          'unitPrice': item.price,
        };
      }).toList();

      final detail = await _api.placeOrder(items);
      _orderDetailOverrides[detail.summary.id] = detail;
      userOrders = [
        detail.summary,
        ...userOrders.where((o) => o.id != detail.summary.id),
      ];
      clearCart();
      await refreshOrders();
      return detail;
    } finally {
      isPlacingOrder = false;
      notifyListeners();
    }
  }

  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    final session = await _api.login(email: email, password: password);
    await _persistSession(session);
    await _loadFavoritesFromBackend();
    await refreshOrders();
    return session;
  }

  Future<UserSession> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final session = await _api.signup(
      name: name,
      email: email,
      password: password,
    );
    await _persistSession(session);
    await _loadFavoritesFromBackend();
    await refreshOrders();
    return session;
  }

  Future<void> logout() async {
    await clearSession();
    navigate(ViewState.home);
  }

  Future<List<NexusSearchHit>> searchCatalog(String query) =>
      _api.search(query);

  Future<void> rememberSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final next = [
      trimmed,
      ...recentSearches.where((s) => s.toLowerCase() != trimmed.toLowerCase()),
    ].take(8).toList();
    await _prefs.setStringList(kRecentSearches, next);
    notifyListeners();
  }

  Future<DetailedOrderMock?> refreshOrderDetail(String id) async {
    isLoadingOrder = true;
    orderLoadError = null;
    notifyListeners();
    try {
      final detail = await _api.fetchOrder(id);
      _orderDetailOverrides[id] = detail;
      return detail;
    } catch (e) {
      orderLoadError = e.toString();
      return orderDetailById(id);
    } finally {
      isLoadingOrder = false;
      notifyListeners();
    }
  }

  int nearbyStockForProduct(String productId) {
    for (final row in content.nearbyStock) {
      if (row.productId == productId) return row.shelfCount;
    }
    return 0;
  }

  void toggleTheme() {
    isDarkTheme = !isDarkTheme;
    unawaited(_prefs.setBool(kDarkTheme, isDarkTheme));
    notifyListeners();
  }

  void toggleFlashDealAlerts(bool value) {
    flashDealAlerts = value;
    unawaited(_prefs.setBool(kFlashDealAlerts, value));
    notifyListeners();
  }

  void toggleSecureCheckout(bool value) {
    secureCheckout = value;
    unawaited(_prefs.setBool(kSecureCheckout, value));
    notifyListeners();
  }

  Future<void> refreshBackendStatus() async {
    try {
      backendOnline = await _api.healthCheck();
    } catch (_) {
      backendOnline = false;
    }
    notifyListeners();
  }

  void _loadUserSettings() {
    isDarkTheme = _prefs.getBool(kDarkTheme) ?? true;
    flashDealAlerts = _prefs.getBool(kFlashDealAlerts) ?? true;
    secureCheckout = _prefs.getBool(kSecureCheckout) ?? false;
  }

  void navigate(ViewState view, {Map<String, dynamic>? params}) {
    currentView = view;
    viewParams = params;
    notifyListeners();
  }

  Future<void> finishOnboarding() async {
    await _prefs.setBool(kHasSeenOnboarding, true);
    navigate(ViewState.home);
  }

  Future<void> skipOnboarding() async {
    await _prefs.setBool(kHasSeenOnboarding, true);
    navigate(ViewState.home);
  }

  Product? featuredById(String? id) {
    if (!isCatalogReady || featuredProducts.isEmpty) return null;
    if (id == null || id.isEmpty) return featuredProducts.first;
    final botm = buildOfTheMonthProduct;
    if (botm != null && id == botm.id) return botm;
    for (final p in featuredProducts) {
      if (p.id == id) return p;
    }
    for (final p in allCatalogProducts) {
      if (p.id == id) return p;
    }
    return featuredProducts.first;
  }

  Product? productById(String id) {
    for (final p in featuredProducts) {
      if (p.id == id) return p;
    }
    final botm = buildOfTheMonthProduct;
    if (botm != null && botm.id == id) return botm;
    return null;
  }

  void addToCart(NewCartPayload payload) {
    cart.add(CartItem(
      id: _randomId(),
      productId: payload.productId,
      qty: payload.qty,
      price: payload.price,
      configOptions: payload.configOptions,
    ));
    unawaited(_persistCart());
    notifyListeners();
  }

  void removeFromCart(String id) {
    cart.removeWhere((e) => e.id == id);
    unawaited(_persistCart());
    notifyListeners();
  }

  void updateCartQty(String id, int qty) {
    if (qty < 1) {
      removeFromCart(id);
      return;
    }
    final idx = cart.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      cart[idx] = CartItem(
        id: cart[idx].id,
        productId: cart[idx].productId,
        qty: qty,
        price: cart[idx].price,
        configOptions: cart[idx].configOptions,
      );
      unawaited(_persistCart());
      notifyListeners();
    }
  }

  void clearCart() {
    cart.clear();
    unawaited(_persistCart());
    notifyListeners();
  }

  void toggleFavorite(String productId) {
    if (favorites.contains(productId)) {
      favorites.remove(productId);
    } else {
      favorites.add(productId);
    }
    notifyListeners();
    if (isSignedIn) {
      unawaited(_api.syncFavorites(List<String>.from(favorites)).catchError((_) {
        return favorites;
      }));
    }
  }

  void saveBuild(BuilderState build) {
    savedBuilds.add(build.copy());
    notifyListeners();
  }

  BuilderState? get latestSavedBuild =>
      savedBuilds.isEmpty ? null : savedBuilds.last;

  void markNotificationRead(String id) {
    final i = notifications.indexWhere((n) => n.id == id);
    if (i >= 0) {
      notifications[i] = NotificationEntry(
        id: notifications[i].id,
        title: notifications[i].title,
        message: notifications[i].message,
        read: true,
        date: notifications[i].date,
      );
      notifyListeners();
    }
  }

  List<NexusBuilderPart> compatibleParts(
    BuilderStep step,
    BuilderState build,
  ) {
    final catalog = builderCatalog;
    if (catalog == null) return const [];

    switch (step) {
      case BuilderStep.cpu:
        return catalog.cpus;
      case BuilderStep.motherboard:
        return catalog.motherboards
            .where((mb) => build.cpu == null || mb.socket == build.cpu!.socket)
            .toList();
      case BuilderStep.ram:
        return catalog.ram
            .where(
              (r) =>
                  build.motherboard == null ||
                  r.ramType == build.motherboard!.ramType,
            )
            .toList();
      case BuilderStep.gpu:
        return catalog.gpus;
      case BuilderStep.storage:
        return catalog.storage;
      case BuilderStep.psu:
        final est = (build.cpu?.tdp ?? 0) + (build.gpu?.tdp ?? 0) + 150;
        return catalog.psus.where((p) => p.wattage >= est).toList();
      case BuilderStep.casePart:
        return catalog.cases
            .where(
              (c) =>
                  build.motherboard == null ||
                  c.formFactors.contains(build.motherboard!.formFactor),
            )
            .toList();
    }
  }

  List<String> compatibilityIssues(BuilderState build) {
    final issues = <String>[];
    final cpu = build.cpu;
    final mb = build.motherboard;
    final ram = build.ram;
    final psu = build.psu;
    final casing = build.casePart;
    final gpu = build.gpu;

    if (cpu != null && mb != null && cpu.socket != mb.socket) {
      issues.add('CPU and Motherboard socket mismatch.');
    }
    if (mb != null && ram != null && mb.ramType != ram.ramType) {
      issues.add('RAM type not supported by Motherboard.');
    }
    final est = (cpu?.tdp ?? 0) + (gpu?.tdp ?? 0) + 150;
    if (psu != null && psu.wattage < est) {
      issues.add('PSU wattage too low. Need at least ${est}W.');
    }
    if (mb != null &&
        casing != null &&
        !casing.formFactors.contains(mb.formFactor)) {
      issues.add('Motherboard form factor does not fit in Case.');
    }
    return issues;
  }

  void _ensureAdmin() {
    if (!isAdmin) {
      throw NexusApiException('Admin access required', statusCode: 403);
    }
  }

  Future<void> loadAdminDashboard() async {
    _ensureAdmin();
    isLoadingAdmin = true;
    adminError = null;
    notifyListeners();
    try {
      adminDashboard = await _api.fetchAdminDashboard();
    } catch (e) {
      adminError = e.toString();
    } finally {
      isLoadingAdmin = false;
      notifyListeners();
    }
  }

  Future<void> loadAdminProducts() async {
    _ensureAdmin();
    isLoadingAdmin = true;
    adminError = null;
    notifyListeners();
    try {
      adminProducts = await _api.fetchAdminProducts();
    } catch (e) {
      adminError = e.toString();
    } finally {
      isLoadingAdmin = false;
      notifyListeners();
    }
  }

  Future<void> loadAdminOrders() async {
    _ensureAdmin();
    isLoadingAdmin = true;
    adminError = null;
    notifyListeners();
    try {
      adminOrders = await _api.fetchAdminOrders();
    } catch (e) {
      adminError = e.toString();
    } finally {
      isLoadingAdmin = false;
      notifyListeners();
    }
  }

  Future<void> createAdminProduct(Map<String, dynamic> payload) async {
    _ensureAdmin();
    await _api.createAdminProduct(payload);
    await loadCatalog();
    await loadAdminProducts();
  }

  Future<void> updateAdminProduct(
    String id,
    Map<String, dynamic> payload,
  ) async {
    _ensureAdmin();
    await _api.updateAdminProduct(id, payload);
    await loadCatalog();
    await loadAdminProducts();
  }

  Future<void> deleteAdminProduct(String id) async {
    _ensureAdmin();
    await _api.deleteAdminProduct(id);
    await loadCatalog();
    await loadAdminProducts();
  }

  Future<void> updateAdminOrderStatus(String id, String status) async {
    _ensureAdmin();
    await _api.updateAdminOrderStatus(id, status);
    await loadAdminOrders();
    await refreshOrders();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  String _randomId() =>
      Random().nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
}

class NewCartPayload {
  NewCartPayload({
    required this.productId,
    required this.qty,
    required this.price,
    this.configOptions,
  });

  final String productId;
  final int qty;
  final double price;
  final CartConfigOptions? configOptions;
}

enum BuilderStep {
  cpu,
  motherboard,
  ram,
  gpu,
  storage,
  psu,
  casePart,
}
