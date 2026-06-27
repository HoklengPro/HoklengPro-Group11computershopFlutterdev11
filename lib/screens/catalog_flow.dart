import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../models/view_state.dart';
import '../state/nexus_controller.dart';
import '../services/nexus_api_service.dart';
import '../theme/nexus_palette.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/favorite_button.dart';
import '../widgets/product_card.dart';
import '../widgets/ui_kit.dart';

Iterable<MapEntry<String, String>> productSpecPairs(ProductSpecs s) sync* {
  if (s.cpu != null) yield MapEntry('CPU', s.cpu!);
  if (s.gpu != null) yield MapEntry('GPU', s.gpu!);
  if (s.ram != null) yield MapEntry('RAM', s.ram!);
  if (s.storage != null) yield MapEntry('STORAGE', s.storage!);
  if (s.display != null) yield MapEntry('DISPLAY', s.display!);
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _placing = false;
  bool _loadingCart = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<NexusController>().ensureCartLoaded();
      if (mounted) setState(() => _loadingCart = false);
    });
  }

  Future<void> _pay(NexusController store) async {
    if (!store.isSignedIn) {
      showNexusToast(context, 'SIGN IN REQUIRED');
      store.navigate(ViewState.login);
      return;
    }
    if (store.cart.isEmpty) {
      showNexusToast(context, 'CART IS EMPTY');
      return;
    }
    if (store.secureCheckout) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm order'),
          content: Text(
            'Place order for \$${store.cartSubtotal.toStringAsFixed(2)} '
            'on this device?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('CONFIRM'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _placing = true);
    try {
      final order = await store.placeOrderFromCart();
      if (!mounted) return;
      showNexusToast(context, 'ORDER ${order.summary.id} PLACED');
      store.navigate(ViewState.orders, params: {'origin': 'checkout'});
    } on NexusApiException catch (e) {
      if (!mounted) return;
      showNexusToast(context, e.message.toUpperCase());
    } catch (_) {
      if (!mounted) return;
      showNexusToast(context, 'CHECKOUT FAILED — CHECK BACKEND');
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NexusController>();
    final muted = NexusPalette.textMuted(context);
    final subtotal = store.cartSubtotal;
    final tax = subtotal * 0.08;
    final total = subtotal + tax;
    final itemCount = store.cart.fold<int>(0, (n, e) => n + e.qty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StickyBar(
          icon: Icons.chevron_left,
          title: 'CHECKOUT (${store.cart.length})',
          onLeading: () => store.navigate(ViewState.cart),
        ),
        if (_loadingCart)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (store.cart.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 48, color: muted),
                    const SizedBox(height: 16),
                    Text(
                      'YOUR CART IS EMPTY',
                      style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add items before checkout.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted),
                    ),
                    const SizedBox(height: 20),
                    GradientRgbButton(
                      onPressed: () => store.navigate(ViewState.home),
                      child: const Text('BROWSE SHOP'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              children: [
                if (!store.isSignedIn) ...[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: NexusPalette.cyan.withValues(alpha: 0.08),
                      border: Border.all(
                        color: NexusPalette.cyan.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Sign in to complete your order.',
                            style: TextStyle(color: muted),
                          ),
                          const SizedBox(height: 12),
                          GradientRgbButton(
                            onPressed: () => store.navigate(ViewState.login),
                            child: const Text('SIGN IN'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  'ORDER SUMMARY · $itemCount ITEM${itemCount == 1 ? '' : 'S'}',
                  style: GoogleFonts.jetBrainsMono(
                    color: muted,
                    letterSpacing: 1.5,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                ...store.cart.map(
                  (e) => CartItemTile(
                    item: e,
                    product: store.productById(e.productId),
                    readOnly: true,
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: NexusPalette.borderSubtle(context)),
                const SizedBox(height: 12),
                _checkoutTotalRow(context, 'Subtotal', subtotal, muted),
                const SizedBox(height: 8),
                _checkoutTotalRow(context, 'Estimated tax', tax, muted),
                const SizedBox(height: 12),
                _checkoutTotalRow(
                  context,
                  'Total',
                  total,
                  muted,
                  emphasized: true,
                ),
                const SizedBox(height: 24),
                GradientRgbButton(
                  onPressed: _placing ? () {} : () => _pay(store),
                  child: _placing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('PAY SECURELY · \$ ${total.toStringAsFixed(2)}'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

Widget _checkoutTotalRow(
  BuildContext context,
  String label,
  double amount,
  Color muted, {
  bool emphasized = false,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label.toUpperCase(),
        style: GoogleFonts.jetBrainsMono(
          fontSize: emphasized ? 12 : 11,
          letterSpacing: emphasized ? 1.2 : 1,
          color: muted,
          fontWeight: emphasized ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      Text(
        '\$ ${amount.toStringAsFixed(2)}',
        style: GoogleFonts.jetBrainsMono(
          fontWeight: FontWeight.bold,
          fontSize: emphasized ? 18 : 14,
          color: emphasized ? NexusPalette.cyan : muted,
        ),
      ),
    ],
  );
}

class CategoryBrowseScreen extends StatelessWidget {
  const CategoryBrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NexusController>();
    final label =
        '${controller.viewParams?['category'] ?? 'Shop'}'.toUpperCase();

    Iterable<Product> source = controller.featuredProducts;
    final raw = '${controller.viewParams?['category'] ?? ''}'.toLowerCase();
    if (raw.isNotEmpty && raw != 'all deals') {
      source = controller.featuredProducts.where(
        (p) =>
            p.category.toLowerCase() == raw ||
            p.name.toLowerCase().contains(raw),
      );
    }

    final list = source.toList();

    return Column(
      children: [
        _StickyBar(
          icon: Icons.chevron_left,
          title: label,
          onLeading: () => controller.navigate(ViewState.home),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 48,
                            color: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: .6)),
                        const SizedBox(height: 20),
                        Text(
                          'NO LISTINGS IN THIS AISLE',
                          textAlign: TextAlign.center,
                          style:
                              GoogleFonts.jetBrainsMono(letterSpacing: 1.6),
                        ),
                        const SizedBox(height: 24),
                        GradientRgbButton(
                          onPressed: () =>
                              controller.navigate(ViewState.home),
                          child: const Text('BACK TO HOME'),
                        ),
                      ],
                    ),
                  )
                : GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: .52,
                    children: list
                        .map(
                          (product) => ProductCardTile(
                            product: product,
                            isFavorite:
                                controller.favorites.contains(product.id),
                            onToggleFavorite: () =>
                                controller.toggleFavorite(product.id),
                            onTap: () => controller.navigate(
                              ViewState.product,
                              params: {'id': product.id},
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ),
      ],
    );
  }
}

class ProductDetailRoute extends StatefulWidget {
  const ProductDetailRoute({super.key});

  @override
  State<ProductDetailRoute> createState() => _ProductDetailRouteState();
}

class _ProductDetailRouteState extends State<ProductDetailRoute> {
  String? ram;
  String? disk;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NexusController>();
    final fallbackId = store.featuredProducts.isNotEmpty
        ? store.featuredProducts.first.id
        : '';
    final pid = '${store.viewParams?['id'] ?? fallbackId}';
    final product = store.featuredById(pid);
    if (product == null) {
      return const Center(child: Text('Product not available'));
    }

    final ramOptions = product.configOptions?.ram ?? const ['32GB', '64GB'];
    final storageOptions =
        product.configOptions?.storage ?? const ['1TB', '2TB'];
    final selectedRam = ram ?? (ramOptions.isNotEmpty ? ramOptions.first : '32GB');
    final selectedDisk =
        disk ?? (storageOptions.isNotEmpty ? storageOptions.first : '1TB');
    final favors = store.favorites.contains(product.id);

    final base = product.price;
    final mod = (selectedRam == '64GB' ? 200.0 : 0) +
        (selectedDisk == '2TB' ? 150.0 : 0);
    final finalPrice = base + mod;

    final muted =
        Theme.of(context).dividerColor.withValues(alpha: .75);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => store.navigate(ViewState.home),
                icon: const Icon(Icons.chevron_left),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => showNexusToast(context, 'LINK COPIED'),
                icon: const Icon(Icons.share_rounded),
              ),
              NexusFavoriteButton(
                isFavorite: favors,
                onPressed: () => store.toggleFavorite(product.id),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding:
                const EdgeInsets.only(bottom: 150),
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(imageUrl: product.image, fit: BoxFit.cover),
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                              radius: 4,
                              backgroundColor: NexusPalette.cyan),
                          const SizedBox(width: 10),
                          CircleAvatar(
                              radius: 4,
                              backgroundColor:
                                  muted.withValues(alpha: .55)),
                          const SizedBox(width: 10),
                          CircleAvatar(
                              radius: 4,
                              backgroundColor:
                                  muted.withValues(alpha: .55)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.category.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.name,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '\$ ${finalPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        color: NexusPalette.cyan,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'IN STOCK • FREE STORE PICKUP',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        letterSpacing: 1.4,
                        color: muted,
                      ),
                    ),
                    if (product.benchmarks != null) ...[
                      const SizedBox(height: 22),
                      NexusBenchmarkStrip(
                        gaming: product.benchmarks!.gaming,
                        productivity: product.benchmarks!.productivity,
                      ),
                    ],
                    const SizedBox(height: 26),
                    _SegmentControl(
                      label: 'MEMORY (RAM)',
                      options: ramOptions,
                      value: selectedRam,
                      activeColor: NexusPalette.cyan,
                      onChanged: (v) => setState(() => ram = v),
                    ),
                    const SizedBox(height: 18),
                    _SegmentControl(
                      label: 'STORAGE',
                      options: storageOptions,
                      value: selectedDisk,
                      activeColor: NexusPalette.magenta,
                      onChanged: (v) => setState(() => disk = v),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'SYSTEM SPECS',
                      style:
                          GoogleFonts.jetBrainsMono(letterSpacing: 2),
                    ),
                    const Divider(height: 24),
                    ...productSpecPairs(product.specs).map(
                          (pair) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    pair.key,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      color: muted,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    pair.value,
                                    textAlign: TextAlign.right,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 118),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      showNexusToast(context, 'RESERVE REQUEST SENT'),
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.calendar_month, size: 18),
                        SizedBox(width: 8),
                        Text('RESERVE'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: GradientRgbButton(
                  onPressed: () {
                    store.addToCart(
                      NewCartPayload(
                        productId: product.id,
                        qty: 1,
                        price: finalPrice,
                        configOptions:
                            CartConfigOptions(
                              ram: selectedRam,
                              storage: selectedDisk,
                            ),
                      ),
                    );
                    showNexusToast(context, 'ADDED TO CART');
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.shopping_cart_outlined),
                      SizedBox(width: 8),
                      Text('ADD TO CART'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SegmentControl extends StatelessWidget {
  const _SegmentControl({
    required this.label,
    required this.options,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  final String label;
  final List<String> options;
  final String value;
  final Color activeColor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).dividerColor.withValues(alpha: .7);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 11)),
        const SizedBox(height: 12),
        Row(
          children: options.map((opt) {
            final active = opt == value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: opt == options.first ? 0 : 6,
                  right: opt == options.last ? 0 : 6,
                ),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: active ? activeColor : muted,
                    side: BorderSide(
                      color: active ? activeColor : muted.withValues(alpha: .6),
                    ),
                    backgroundColor:
                        active ? activeColor.withValues(alpha: 0.1) : null,
                  ),
                  onPressed: () => onChanged(opt),
                  child: Text(opt, style: GoogleFonts.jetBrainsMono()),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StickyBar extends StatelessWidget {
  const _StickyBar({
    required this.icon,
    required this.title,
    required this.onLeading,
  });

  final IconData icon;
  final String title;
  final VoidCallback onLeading;

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: NexusPalette.borderSubtle(context),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onLeading,
            icon: Icon(icon, size: 28, color: iconColor),
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
