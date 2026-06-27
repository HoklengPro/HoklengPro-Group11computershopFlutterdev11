import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../models/models.dart';
import '../models/view_state.dart';
import '../services/catalog_json.dart';
import '../state/nexus_controller.dart';
import '../theme/nexus_palette.dart';
import '../widgets/nexus_profile_avatar.dart';
import '../widgets/nexus_store_map.dart';
import '../widgets/ui_kit.dart';

class _NexusStickyHeader extends StatelessWidget {
  const _NexusStickyHeader({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final d = NexusPalette.borderSubtle(context);
    final iconColor = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: d)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.chevron_left, size: 28, color: iconColor),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

Widget _capsLabel(BuildContext ctx, Color muted, String t) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        t,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
          color: muted,
        ),
      ),
    );

Color _statusTint(OrderStatus s) => switch (s) {
      OrderStatus.delivered => Colors.lightGreenAccent,
      OrderStatus.shipped => NexusPalette.cyan,
      OrderStatus.processing => Colors.amberAccent,
      OrderStatus.cancelled => Colors.redAccent,
    };

Product? _productForId(NexusController ctrl, String? id) {
  if (id != null && id.isNotEmpty) {
    return ctrl.productById(id) ?? ctrl.featuredById(id);
  }
  return ctrl.featuredProducts.isNotEmpty ? ctrl.featuredProducts.first : null;
}

class _SearchResultItem {
  const _SearchResultItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.image,
    required this.price,
    required this.isPart,
  });

  final String id;
  final String name;
  final String subtitle;
  final String image;
  final double price;
  final bool isPart;
}

class NexusSearchScreen extends StatefulWidget {
  const NexusSearchScreen({super.key});

  @override
  State<NexusSearchScreen> createState() => _NexusSearchScreenState();
}

class _NexusSearchScreenState extends State<NexusSearchScreen> {
  final _txt = TextEditingController();
  String _q = '';
  bool _loading = false;
  List<_SearchResultItem> _results = [];
  Timer? _debounce;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _txt.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    setState(() => _q = _txt.text);
    _debounce?.cancel();
    final ql = _q.trim();
    if (ql.length <= 2) {
      setState(() {
        _loading = false;
        _results = [];
        _searchError = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _searchError = null;
    });
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      final ctrl = context.read<NexusController>();
      try {
        final hits = await ctrl.searchCatalog(ql);
        if (!mounted) return;
        setState(() {
          _results = hits.map((hit) {
            if (hit.isProduct) {
              final product = productFromJson(hit.item);
              return _SearchResultItem(
                id: product.id,
                name: product.name,
                subtitle:
                    '${product.category.toUpperCase()} • \$${product.price.toStringAsFixed(2)}',
                image: product.image,
                price: product.price,
                isPart: false,
              );
            }
            final part = builderPartFromJson(hit.item);
            return _SearchResultItem(
              id: part.id,
              name: part.name,
              subtitle:
                  '${part.partType.toUpperCase()} • \$${part.price.toStringAsFixed(2)}',
              image: part.image,
              price: part.price,
              isPart: true,
            );
          }).toList();
          _loading = false;
        });
        await ctrl.rememberSearch(ql);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _searchError = e.toString();
          _results = [];
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _txt.removeListener(_onQueryChanged);
    _txt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NexusController>();
    final muted = NexusPalette.textMuted(context);
    final surface = Theme.of(context).colorScheme.surface;
    final ql = _q.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: surface.withValues(alpha: 0.82),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: .45),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  autofocus: true,
                  controller: _txt,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Search products, parts...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: muted,
                    ),
                    suffixIcon: ql.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(Icons.close_rounded,
                                size: 18, color: muted),
                            onPressed: () {
                              _txt.clear();
                              setState(() {
                                _q = '';
                                _results = [];
                                _loading = false;
                              });
                            },
                          ),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: .55),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor.withValues(alpha: .55),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: NexusPalette.cyan),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => ctrl.navigate(ViewState.home),
                child: Text(
                  'CANCEL',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: muted,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            children: [
              if (ql.length > 2) ...[
                if (_loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: NexusPalette.cyan,
                        ),
                      ),
                    ),
                  )
                else if (_results.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      _searchError == null
                          ? 'NO RESULTS FOUND'
                          : 'SEARCH FAILED — CHECK BACKEND',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        color: muted,
                      ),
                    ),
                  )
                else
                  ..._results.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: surface.withValues(alpha: .95),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            if (item.isPart) {
                              ctrl.navigate(ViewState.builder);
                            } else {
                              ctrl.navigate(
                                ViewState.product,
                                params: {'id': item.id},
                              );
                            }
                          },
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: .45),
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: .5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: CachedNetworkImage(
                                    imageUrl: item.image,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.subtitle,
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 10,
                                          color: muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_rounded,
                                    size: 18, color: muted),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ] else ...[
                Text(
                  'RECENT SEARCHES',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ctrl.recentSearches.map((s) {
                    return ActionChip(
                      label: Text(
                        s,
                        style: GoogleFonts.jetBrainsMono(fontSize: 11),
                      ),
                      backgroundColor: surface.withValues(alpha: .95),
                      side: BorderSide(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: .45),
                      ),
                      onPressed: () {
                        _txt.text = s;
                        _txt.selection = TextSelection.collapsed(
                          offset: s.length,
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                Text(
                  'TRENDING CATEGORIES',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.4,
                  children: ctrl.categoryTiles.map((cat) {
                    return Material(
                      color: surface.withValues(alpha: .95),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => ctrl.navigate(
                          ViewState.category,
                          params: {'category': cat.label},
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: .45),
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              cat.label,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class NotificationsFeedScreen extends StatelessWidget {
  const NotificationsFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NexusController>();
    final muted = NexusPalette.textMuted(context);

    return Column(
      children: [
        _NexusStickyHeader(
          title: 'NOTIFICATIONS',
          onBack: () => ctrl.navigate(ViewState.home),
        ),
        Expanded(
          child: ctrl.notifications.isEmpty
              ? Center(child: Text('ALL CAUGHT UP', style: GoogleFonts.jetBrainsMono(color: muted)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 112),
                  separatorBuilder: (_, __) => const Divider(height: 22),
                  itemCount: ctrl.notifications.length,
                  itemBuilder: (_, i) {
                    final n = ctrl.notifications[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => ctrl.markNotificationRead(n.id),
                      child: Ink(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: muted.withValues(alpha: .42)),
                          color: n.read
                              ? Colors.transparent
                              : NexusPalette.cyan.withValues(alpha: .06),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (!n.read) GlowDot(color: NexusPalette.magenta),
                                if (!n.read) const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall!
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  n.date.length >= 10
                                      ? n.date.substring(0, 10)
                                      : n.date,
                                  style:
                                      GoogleFonts.jetBrainsMono(fontSize: 9),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              n.message,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: muted),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class AccountOverviewScreen extends StatelessWidget {
  const AccountOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NexusController>();
    final muted = NexusPalette.textMuted(context);
    final profile = ctrl.accountProfile;
    final signedIn = ctrl.isSignedIn;

    Widget row(String title, IconData ic, VoidCallback onTap,
        [Color tint = NexusPalette.cyan]) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NexusPalette.borderSubtle(context)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Row(
              children: [
                Icon(ic, color: tint, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: NexusPalette.iconMuted(context), size: 22),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 112),
      children: [
        BorderGradientPanel(
          radius: 20,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                NexusProfileAvatar(
                  radius: 36,
                  initials: profile.initials,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        signedIn
                            ? profile.tier
                            : profile.tier,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: muted),
                      ),
                      if (signedIn && ctrl.currentUser?.email.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          ctrl.currentUser!.email,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: muted.withValues(alpha: .85)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),
        _capsLabel(context, muted, 'ACCOUNT MENU'),
        row(
          'ORDERS',
          Icons.receipt_long_rounded,
          () => ctrl.navigate(ViewState.orders),
        ),
        row(
          'LOYALTY & REWARDS',
          Icons.emoji_events_rounded,
          () => ctrl.navigate(ViewState.loyalty),
          Colors.amberAccent.shade400,
        ),
        row(
          'ADDRESSES',
          Icons.place_rounded,
          () => ctrl.navigate(ViewState.addresses),
        ),
        row(
          'PAYMENT METHODS',
          Icons.wallet_rounded,
          () => ctrl.navigate(ViewState.paymentMethods),
          NexusPalette.magenta,
        ),
        row(
          'WRITE A REVIEW',
          Icons.rate_review_rounded,
          () => ctrl.navigate(
            ViewState.writeReview,
            params: {
              'id': ctrl.featuredProducts.isNotEmpty
                  ? ctrl.featuredProducts.first.id
                  : '',
            },
          ),
        ),
        row(
          'HELP CENTER',
          Icons.help_outline_rounded,
          () => ctrl.navigate(ViewState.help),
        ),
        row(
          'SETTINGS',
          Icons.tune_rounded,
          () => ctrl.navigate(ViewState.settings),
          NexusPalette.violet,
        ),
        if (ctrl.isAdmin) ...[
          const SizedBox(height: 8),
          row(
            'ADMIN PANEL',
            Icons.admin_panel_settings_rounded,
            () => ctrl.navigate(ViewState.adminDashboard),
            Colors.amberAccent.shade400,
          ),
        ],
        const SizedBox(height: 18),
        if (!signedIn) ...[
          GradientRgbButton(
            onPressed: () => ctrl.navigate(ViewState.login),
            child: const Text('SIGN IN'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => ctrl.navigate(ViewState.signup),
            child: Text(
              'CREATE ACCOUNT',
              style: GoogleFonts.jetBrainsMono(fontSize: 11),
            ),
          ),
        ] else
          OutlinedButton(
            onPressed: () async {
              await ctrl.logout();
              if (context.mounted) {
                showNexusToast(context, 'SIGNED OUT');
              }
            },
            child: Text(
              'SIGN OUT',
              style: GoogleFonts.jetBrainsMono(fontSize: 11),
            ),
          ),
      ],
    );
  }
}

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<NexusController>();
      if (ctrl.isSignedIn) {
        unawaited(ctrl.refreshOrders());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NexusController>();
    final rows = ctrl.listOrdersByDate();
    final muted = NexusPalette.textMuted(context);

    return Column(
      children: [
        _NexusStickyHeader(
          title: 'YOUR ORDERS',
          onBack: () {
            final fromCheckout =
                ctrl.viewParams?['origin'] == 'checkout';
            ctrl.navigate(fromCheckout ? ViewState.home : ViewState.account);
          },
        ),
        if (ctrl.isLoadingOrders)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (rows.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  ctrl.isSignedIn
                      ? 'No orders yet. Add items to cart and checkout.'
                      : 'Sign in to see your orders, or browse demo orders after loading catalog.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 112),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final r = rows[i];
                final tint = _statusTint(r.status);
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () =>
                      ctrl.navigate(ViewState.orderDetail, params: {'orderId': r.id}),
                  child: Ink(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: muted.withValues(alpha: .5)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.id,
                                style:
                                    GoogleFonts.jetBrainsMono(
                                        fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${r.date} · ${r.itemCount} ITEMS',
                                style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    letterSpacing: 1.5,
                                    color: muted),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$ ${r.total.toStringAsFixed(2)}',
                              style: GoogleFonts.jetBrainsMono(
                                fontWeight: FontWeight.bold,
                                color: NexusPalette.cyan,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: tint.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(999),
                                border:
                                    Border.all(color: tint.withValues(alpha: .45)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                child: Text(
                                  r.status.name.toUpperCase(),
                                  style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.5,
                                      color: tint),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.chevron_right,
                            color: NexusPalette.iconMuted(context), size: 22),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class OrderReceiptScreen extends StatefulWidget {
  const OrderReceiptScreen({super.key});

  @override
  State<OrderReceiptScreen> createState() => _OrderReceiptScreenState();
}

class _OrderReceiptScreenState extends State<OrderReceiptScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<NexusController>();
      final id = '${ctrl.viewParams?['orderId'] ?? ''}';
      if (id.isNotEmpty) {
        unawaited(ctrl.refreshOrderDetail(id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NexusController>();
    final id = '${ctrl.viewParams?['orderId'] ?? ''}';
    if (ctrl.isLoadingOrder && ctrl.orderDetailById(id) == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final detail = ctrl.orderDetailById(id) ??
        (ctrl.orderCatalog.values.isNotEmpty
            ? ctrl.orderCatalog.values.first
            : null);
    if (detail == null) {
      return const Center(child: Text('Order not found'));
    }
    final muted = NexusPalette.textMuted(context);
    final s = detail.summary;
    final hints = detail.trackingHints;

    return Column(
      children: [
        _NexusStickyHeader(
          title: 'ORDER RECEIPT',
          onBack: () => ctrl.navigate(ViewState.orders),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 112),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.id,
                    style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _statusTint(s.status).withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text(
                        s.status.name.toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: _statusTint(s.status)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${s.date} · ${detail.carrier ?? ''}',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 11, letterSpacing: 1.2, color: muted),
              ),
              if (detail.etaNote != null) ...[
                const SizedBox(height: 6),
                Text(detail.etaNote!, style: TextStyle(color: muted)),
              ],
              const SizedBox(height: 24),
              Text('ITEMS',
                  style:
                      GoogleFonts.jetBrainsMono(letterSpacing: 2, fontSize: 11)),
              const Divider(height: 24),
              ...detail.lines.map(
                (l) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: Text(l.title)),
                      Text('${l.qty}×',
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 11, color: muted)),
                      const SizedBox(width: 12),
                      Text(
                        '\$ ${(l.unitPrice * l.qty).toStringAsFixed(2)}',
                        style: GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.bold, color: NexusPalette.cyan),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PAID TOTAL',
                      style: GoogleFonts.jetBrainsMono(fontSize: 12)),
                  Text(
                    '\$ ${s.total.toStringAsFixed(2)}',
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: NexusPalette.cyan,
                    ),
                  ),
                ],
              ),
              if (hints.isNotEmpty) ...[
                const SizedBox(height: 26),
                Text('TRACKING PULSE',
                    style:
                        GoogleFonts.jetBrainsMono(letterSpacing: 2, fontSize: 11)),
                const SizedBox(height: 12),
                for (var i = 0; i < hints.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlowDot(
                          radius: i == hints.length - 1 ? 5 : 3,
                          color: NexusPalette.magenta.withValues(
                              alpha: i == hints.length - 1 ? 1 : .5),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${i + 1}. ${hints[i]}',
                            style: TextStyle(color: muted, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NexusController>().refreshBackendStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NexusController>();
    final muted = NexusPalette.textMuted(context);
    final online = ctrl.backendOnline;

    return Column(
      children: [
        _NexusStickyHeader(
          title: 'SETTINGS',
          onBack: () => ctrl.navigate(ViewState.account),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 112),
            children: [
              _settingsSectionLabel(context, 'APPEARANCE'),
              _SettingsTile(
                icon: Icons.dark_mode_rounded,
                iconColor: NexusPalette.violet,
                title: 'DARK INTERFACE',
                trailing: Switch(
                  value: ctrl.isDarkTheme,
                  onChanged: (_) => ctrl.toggleTheme(),
                ),
              ),
              const SizedBox(height: 8),
              _settingsSectionLabel(context, 'NOTIFICATIONS'),
              _SettingsTile(
                icon: Icons.local_fire_department_rounded,
                iconColor: NexusPalette.magenta,
                title: 'FLASH DEAL ALERTS',
                trailing: Switch(
                  value: ctrl.flashDealAlerts,
                  onChanged: ctrl.toggleFlashDealAlerts,
                ),
              ),
              const SizedBox(height: 8),
              _settingsSectionLabel(context, 'CHECKOUT'),
              _SettingsTile(
                icon: Icons.verified_user_rounded,
                iconColor: NexusPalette.cyan,
                title: 'SECURE DEVICE CHECKOUT',
                subtitle: 'Require confirmation before placing orders',
                trailing: Switch(
                  value: ctrl.secureCheckout,
                  onChanged: ctrl.toggleSecureCheckout,
                ),
              ),
              const SizedBox(height: 8),
              _settingsSectionLabel(context, 'PREFERENCES'),
              _SettingsTile(
                icon: Icons.mail_outline_rounded,
                iconColor: muted,
                title: 'EMAIL DIGEST SETTINGS',
                trailing: Icon(Icons.chevron_right, color: muted),
                onTap: () => showNexusToast(context, 'PREFERENCES UPDATED'),
              ),
              const SizedBox(height: 8),
              _settingsSectionLabel(context, 'BACKEND'),
              _SettingsTile(
                icon: Icons.dns_rounded,
                iconColor: NexusPalette.cyan,
                title: 'API BASE URL',
                subtitle: ApiConfig.baseUrl,
              ),
              _SettingsTile(
                icon: online == true
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_off_rounded,
                iconColor: online == true ? Colors.greenAccent : Colors.orangeAccent,
                title: 'BACKEND STATUS',
                subtitle: online == null
                    ? 'Checking connection…'
                    : online
                        ? 'Online — catalog and auth available'
                        : 'Offline — start backend on port 8848',
                trailing: IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => ctrl.refreshBackendStatus(),
                ),
              ),
              _SettingsTile(
                icon: Icons.menu_book_rounded,
                iconColor: NexusPalette.violet,
                title: 'API DOCUMENTATION',
                subtitle: '${ApiConfig.baseUrl}/api/docs',
                trailing: Icon(Icons.open_in_new_rounded, color: muted, size: 20),
                onTap: () => showNexusToast(
                  context,
                  'Open ${ApiConfig.baseUrl}/api/docs in a browser',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingsSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          letterSpacing: 2,
          color: NexusPalette.textMuted(context),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: (iconColor ?? NexusPalette.cyan).withValues(alpha: .12),
        ),
        child: Icon(icon, color: iconColor ?? NexusPalette.cyan, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.jetBrainsMono(fontSize: 13),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<NexusController>();
    final muted = NexusPalette.textMuted(context);
    final list = ctrl.content.addresses;

    return Column(
      children: [
        _NexusStickyHeader(
          title: 'ADDRESSES',
          onBack: () => ctrl.navigate(ViewState.account),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 112),
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final item = list[i];
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: muted.withValues(alpha: .5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.tag,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: NexusPalette.cyan,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(item.line1,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(item.line2,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: muted)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => showNexusToast(context, 'ADDRESS EDITOR OPENED'),
                        child: Text('EDIT',
                            style: GoogleFonts.jetBrainsMono(fontSize: 10)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class PaymentWalletScreen extends StatelessWidget {
  const PaymentWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<NexusController>();
    final muted = NexusPalette.textMuted(context);

    IconData iconFor(String name) => switch (name) {
          'wallet' => Icons.account_balance_wallet_outlined,
          _ => Icons.credit_card_rounded,
        };

    Widget cardRow(String primary, String sub, IconData ic) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: muted.withValues(alpha: .5)),
          ),
          child: ListTile(
            leading: Icon(ic),
            title: Text(primary,
                style:
                    GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
            subtitle: Text(sub),
            trailing: Icon(Icons.more_horiz, color: muted),
          ),
        );

    return Column(
      children: [
        _NexusStickyHeader(
          title: 'PAYMENTS',
          onBack: () => ctrl.navigate(ViewState.account),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 112),
            children: [
              ...ctrl.content.paymentMethods.map(
                (method) => cardRow(
                  method.primary,
                  method.subtitle,
                  iconFor(method.icon),
                ),
              ),
              OutlinedButton(
                onPressed: () => showNexusToast(context, 'PAYMENT SETUP STARTED'),
                child: Text(
                  '+ PAYMENT METHOD',
                  style: GoogleFonts.jetBrainsMono(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WriteReviewSheet extends StatefulWidget {
  const WriteReviewSheet({super.key});

  @override
  State<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<WriteReviewSheet> {
  int stars = 4;
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NexusController>();
    final product = _productForId(ctrl, ctrl.viewParams?['id'] as String?);
    final muted = NexusPalette.textMuted(context);
    if (product == null) {
      return const Center(child: Text('Product not found'));
    }

    return Column(
      children: [
        _NexusStickyHeader(
          title: 'WRITE REVIEW',
          onBack: () => ctrl.navigate(ViewState.account),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
            children: [
              Text(
                product.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              _capsLabel(context, muted, 'RATING'),
              Row(
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setState(() => stars = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        i < stars
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color:
                            i < stars ? NexusPalette.magenta : Colors.white24,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _notes,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Thermals · noise · performance?',
                ),
              ),
              const SizedBox(height: 24),
              GradientRgbButton(
                onPressed: () {
                  showNexusToast(context, 'REVIEW SUBMITTED — THANKS');
                  ctrl.navigate(ViewState.account);
                },
                child: const Text('SUBMIT REVIEW'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BranchLocatorScreen extends StatefulWidget {
  const BranchLocatorScreen({super.key});

  @override
  State<BranchLocatorScreen> createState() => _BranchLocatorScreenState();
}

class _BranchLocatorScreenState extends State<BranchLocatorScreen> {
  String? _selectedStore;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<NexusController>();
    final muted = NexusPalette.textMuted(context);
    final spots = ctrl.content.storeLocations;

    return Column(
      children: [
        _NexusStickyHeader(
          title: 'STORE MAP',
          onBack: () => ctrl.navigate(ViewState.more),
        ),
        Expanded(
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: muted.withValues(alpha: .55)),
                    ),
                    child: SizedBox.expand(
                    child: NexusStoreMap(
                      locations: spots,
                      selectedName: _selectedStore,
                      onMarkerTap: (spot) {
                        setState(() => _selectedStore = spot.name);
                      },
                    ),
                  ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 112),
                  itemCount: spots.length,
                  itemBuilder: (_, i) {
                    final spot = spots[i];
                    final selected = _selectedStore == spot.name;
                    return ListTile(
                      selected: selected,
                      leading: GlowDot(
                        color: selected
                            ? NexusPalette.cyan.withValues(alpha: .9)
                            : NexusPalette.violet.withValues(alpha: .9),
                      ),
                      title: Text(spot.name, style: GoogleFonts.jetBrainsMono()),
                      subtitle: Text(spot.subtitle, style: TextStyle(color: muted)),
                      onTap: spot.hasCoordinates
                          ? () => setState(() => _selectedStore = spot.name)
                          : null,
                      trailing: TextButton(
                        onPressed: () async {
                          if (!spot.hasCoordinates) {
                            showNexusToast(context, 'NO MAP COORDINATES');
                            return;
                          }
                          final ok = await openStoreDirections(spot);
                          if (!context.mounted) return;
                          showNexusToast(
                            context,
                            ok ? 'OPENING DIRECTIONS' : 'COULD NOT OPEN MAPS',
                          );
                        },
                        child: Text('GO', style: GoogleFonts.jetBrainsMono()),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class NearbyAvailabilityScreen extends StatelessWidget {
  const NearbyAvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<NexusController>();
    final muted = NexusPalette.textMuted(context);

    return Column(
      children: [
        _NexusStickyHeader(
          title: 'NEARBY STOCK',
          onBack: () => ctrl.navigate(ViewState.more),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 112),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    ['ALL', 'GPU', 'LAPTOP', 'PSU'].map((t) {
                  return Chip(
                    label:
                        Text(t, style: GoogleFonts.jetBrainsMono(fontSize: 10)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ...ctrl.content.nearbyStock.map((stock) {
                final p = ctrl.productById(stock.productId) ??
                    ctrl.featuredById(stock.productId);
                if (p == null) return const SizedBox.shrink();
                return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: muted.withValues(alpha: .5)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: p.image,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name),
                                const SizedBox(height: 8),
                                Text(
                                  '${stock.shelfCount} IN SHELF HOLD',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    letterSpacing: 2,
                                    color: NexusPalette.cyan,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => ctrl.navigate(
                              ViewState.product,
                              params: {'id': p.id},
                            ),
                            child: Text('VIEW',
                                style: GoogleFonts.jetBrainsMono()),
                          ),
                        ],
                      ),
                    );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class PromotionsHubScreen extends StatelessWidget {
  const PromotionsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<NexusController>();
    final muted = NexusPalette.textMuted(context);
    final promos = ctrl.content.promotions;

    return Column(
      children: [
        _NexusStickyHeader(
          title: 'PROMOS',
          onBack: () => ctrl.navigate(ViewState.more),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 112),
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemCount: promos.length,
            itemBuilder: (_, i) {
              final promo = promos[i];
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => ctrl.navigate(ViewState.category),
                child: BorderGradientPanel(
                  radius: 17,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promo.title,
                          style: GoogleFonts.jetBrainsMono(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          promo.body,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: muted),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'REDEEM',
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              letterSpacing: 3,
                              color: NexusPalette.cyan),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class RepairBookingScreen extends StatefulWidget {
  const RepairBookingScreen({super.key});

  @override
  State<RepairBookingScreen> createState() => _RepairBookingScreenState();
}

class _RepairBookingScreenState extends State<RepairBookingScreen> {
  late String device;
  DateTime slot = DateTime(2026, 6, 1, 14);

  @override
  void initState() {
    super.initState();
    final types = context.read<NexusController>().content.repairDeviceTypes;
    device = types.isNotEmpty ? types.first : 'Gaming Laptop';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<NexusController>();
    final muted = NexusPalette.textMuted(context);

    return Column(
      children: [
        _NexusStickyHeader(
          title: 'BOOK REPAIR',
          onBack: () => ctrl.navigate(ViewState.more),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
            children: [
              _capsLabel(context, muted, 'DEVICE'),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(),
                value: device,
                items: ctrl.content.repairDeviceTypes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => device = v ?? device),
              ),
              const SizedBox(height: 18),
              _capsLabel(context, muted, 'TECH NOTES'),
              TextField(
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Symptoms · warranty window · BIOS tweaks…',
                ),
              ),
              const SizedBox(height: 18),
              _capsLabel(context, muted, 'DROP-OFF'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${slot.month}/${slot.day} · ${slot.hour}:00 LOCAL',
                  style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Tap arrow to iterate day (demo)',
                    style: TextStyle(color: muted)),
                trailing: IconButton(
                  icon: Icon(Icons.calendar_month_outlined, color: muted),
                  onPressed: () => setState(
                    () =>
                        slot = slot.add(const Duration(days: 1)),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              GradientRgbButton(
                onPressed: () {
                  showNexusToast(context, 'SERVICE REQUEST CONFIRMED');
                  ctrl.navigate(ViewState.repairTracker);
                },
                child: const Text('LOCK SLOT'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TechChatScreen extends StatefulWidget {
  const TechChatScreen({super.key});

  @override
  State<TechChatScreen> createState() => _TechChatScreenState();
}

class _Msg {
  _Msg({required this.fromUser, required this.text});
  final bool fromUser;
  final String text;
}

class _TechChatScreenState extends State<TechChatScreen> {
  final ctrlText = TextEditingController();
  final msgs = <_Msg>[
    _Msg(fromUser: false,
        text:
            'Hi Hex · need PSU math for dual-GPU workstation?'),
    _Msg(fromUser: true,
        text: '7800X3D · 4090 Strix OC · light OC only.'),
    _Msg(fromUser: false,
        text: 'Shoot for RM1000x class. Sending bundle link.'),
  ];

  @override
  void dispose() {
    ctrlText.dispose();
    super.dispose();
  }

  void _send(BuildContext ctx) {
    final v = ctrlText.text.trim();
    if (v.isEmpty) return;
    setState(() => msgs.add(_Msg(fromUser: true, text: v)));
    ctrlText.clear();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<NexusController>();
    final theme = Theme.of(context);

    return Column(
      children: [
        _NexusStickyHeader(
          title: 'TECH SUPPORT',
          onBack: () => store.navigate(ViewState.more),
        ),
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
            itemCount: msgs.length,
            itemBuilder: (_, i) {
              final m = msgs[msgs.length - 1 - i];
              final align =
                  m.fromUser ? Alignment.centerRight : Alignment.centerLeft;
              final bubble = BorderRadius.circular(14).copyWith(
                bottomRight:
                    m.fromUser ? const Radius.circular(3) : const Radius.circular(14),
                bottomLeft:
                    !m.fromUser ? const Radius.circular(3) : const Radius.circular(14),
              );
              final maxW = MediaQuery.sizeOf(context).width * .78;

              return Align(
                alignment: align,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  constraints: BoxConstraints(maxWidth: maxW),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: bubble,
                    color: m.fromUser
                        ? NexusPalette.cyan.withValues(alpha: .18)
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: .45),
                  ),
                  child: Text(
                    m.text,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                  ),
                ),
              );
            },
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: .92),
            border: Border(
              top: BorderSide(color: NexusPalette.borderSubtle(context)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrlText,
                    minLines: 1,
                    maxLines: 4,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Message Nexus…',
                      hintStyle: theme.inputDecorationTheme.hintStyle,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(context),
                  ),
                ),
                IconButton(
                  tooltip: 'Send',
                  onPressed: () => _send(context),
                  icon: Icon(Icons.send_rounded, color: NexusPalette.cyan),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CommunityReviewsScreen extends StatelessWidget {
  const CommunityReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<NexusController>();
    final reviews = ctrl.content.communityReviews;

    Widget card(String handle, double stars, String sku, String body) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Theme.of(context)
                      .dividerColor
                      .withValues(alpha: .45)),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(handle,
                          style:
                              GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
                    ),
                    Text(
                      '★'.padRight(stars.round(), '★').padRight(5, '☆'),
                      style:
                          TextStyle(fontSize: 12, color: NexusPalette.magenta),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(body),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      ctrl.navigate(ViewState.product, params: {'id': sku}),
                  child: Text(
                    'SKU',
                    style: GoogleFonts.jetBrainsMono(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        );

    return Column(
      children: [
        _NexusStickyHeader(
          title: 'REVIEWS',
          onBack: () => ctrl.navigate(ViewState.more),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 112),
            children: reviews
                .map(
                  (review) => card(
                    review.author,
                    review.stars.toDouble(),
                    review.productId,
                    review.body,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class ShowcaseMediaScreen extends StatelessWidget {
  const ShowcaseMediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<NexusController>();
    final extra = ctrl.content.showcaseExtra;

    return Column(
      children: [
        _NexusStickyHeader(
          title: 'SHOWCASE',
          onBack: () => ctrl.navigate(ViewState.more),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 112),
            itemCount: ctrl.featuredProducts.length + (extra == null ? 0 : 1),
            itemBuilder: (_, i) {
              if (i == ctrl.featuredProducts.length && extra != null) {
                return ListTile(
                  leading: GlowDot(color: NexusPalette.cyan),
                  title:
                      Text(extra.title, style: GoogleFonts.jetBrainsMono()),
                  subtitle: Text(extra.subtitle),
                  trailing: const Icon(Icons.play_circle_fill_rounded),
                );
              }
              if (i == ctrl.featuredProducts.length) {
                return const SizedBox.shrink();
              }
              final p = ctrl.featuredProducts[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: InkWell(
                  onTap: () =>
                      ctrl.navigate(ViewState.product, params: {'id': p.id}),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(imageUrl: p.image, fit: BoxFit.cover),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: .72),
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.center,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          bottom: 14,
                          right: 16,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${p.category.toUpperCase()} REEL',
                                  style: GoogleFonts.jetBrainsMono(fontSize: 11),
                                ),
                              ),
                              const Icon(Icons.play_arrow_rounded, size: 36),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class RepairTimelineScreen extends StatelessWidget {
  const RepairTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<NexusController>();
    final muted = NexusPalette.textMuted(context);
    final tracker = ctrl.content.repairTracker;
    final steps = tracker.steps;

    return Column(
      children: [
        _NexusStickyHeader(
          title: 'REPAIR TRACK',
          onBack: () => ctrl.navigate(ViewState.more),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 112),
            children: [
              BorderGradientPanel(
                radius: 18,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tracker.ticketId} · ${tracker.title}',
                        style: GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tracker.lead,
                        style: TextStyle(color: muted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              for (var i = 0; i < steps.length; i++)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                steps[i].complete ? NexusPalette.cyan : Colors.transparent,
                            border: Border.all(color: muted, width: 1.8),
                          ),
                        ),
                        if (i != steps.length - 1)
                          Container(width: 1, height: 46, color: muted.withValues(alpha: .35)),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            bottom: i == steps.length - 1 ? 0 : 16),
                        child: Text(
                          steps[i].label,
                          style: TextStyle(
                            fontWeight:
                                steps[i].complete ? FontWeight.bold : FontWeight.normal,
                            color: steps[i].complete ? Colors.white : muted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              OutlinedButton(
                onPressed: () => ctrl.navigate(ViewState.chat),
                child:
                    Text('OPEN CHAT', style: GoogleFonts.jetBrainsMono()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LoyaltyHubScreen extends StatelessWidget {
  const LoyaltyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<NexusController>();
    final muted = NexusPalette.textMuted(context);
    final loyalty = ctrl.content.loyalty;

    return Column(
      children: [
        _NexusStickyHeader(
          title: 'REWARDS',
          onBack: () => ctrl.navigate(ViewState.account),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 112),
            children: [
              BorderGradientPanel(
                radius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${loyalty.points} PTS',
                        style: GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.bold, fontSize: 30),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loyalty.tierLabel,
                        style: TextStyle(color: muted),
                      ),
                      const SizedBox(height: 18),
                      LinearProgressIndicator(
                        value: loyalty.progress,
                        minHeight: 8,
                        backgroundColor:
                            Colors.white.withValues(alpha: .12),
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: GlowDot(color: Colors.amberAccent.shade400),
                title:
                    Text('Redeem perk drops', style: GoogleFonts.jetBrainsMono()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    showNexusToast(context, 'REWARDS OPENED'),
              ),
              ListTile(
                leading: GlowDot(color: NexusPalette.magenta),
                title: Text('Refer a builder buddy',
                    style: GoogleFonts.jetBrainsMono(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => ctrl.navigate(ViewState.more),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HelpDeskScreen extends StatelessWidget {
  const HelpDeskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<NexusController>();
    final faqs = ctrl.content.helpFaqs;

    return Column(
      children: [
        _NexusStickyHeader(
          title: 'HELP',
          onBack: () => ctrl.navigate(ViewState.account),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 112),
            itemCount: faqs.length,
            itemBuilder: (_, i) {
              final faq = faqs[i];
              return ExpansionTile(
                title: Text(faq.question,
                    style: GoogleFonts.jetBrainsMono(fontSize: 12)),
                childrenPadding:
                    const EdgeInsets.fromLTRB(26, 0, 26, 12),
                children: [
                  Text(faq.answer),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
