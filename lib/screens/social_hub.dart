import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../models/view_state.dart';
import '../state/nexus_controller.dart';
import '../theme/nexus_palette.dart';
import '../widgets/favorite_button.dart';
import '../widgets/ui_kit.dart';

class ExploreMoreScreen extends StatelessWidget {
  const ExploreMoreScreen({super.key});

  static const _items = <(ViewState, String, IconData)>[
    (ViewState.map, 'BRANCH MAP', Icons.map_outlined),
    (ViewState.nearby, 'NEARBY STOCK', Icons.store_outlined),
    (ViewState.promotions, 'PROMOTIONS', Icons.local_offer_outlined),
    (ViewState.booking, 'BOOK REPAIR', Icons.event_outlined),
    (ViewState.repairTracker, 'REPAIR TRACKER', Icons.track_changes_outlined),
    (ViewState.chat, 'TECH SUPPORT', Icons.support_agent_outlined),
    (ViewState.reviews, 'REVIEWS', Icons.rate_review_outlined),
    (ViewState.media, 'SHOWCASES', Icons.play_circle_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final store = context.read<NexusController>();
    final muted = mutedOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconTileBg = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : const Color(0xFF1E293B);

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 112),
      children: [
        Text(
          'EXPLORE',
          style:
              GoogleFonts.jetBrainsMono(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'SERVICES • STORE TOOLS • COMMUNITY',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            letterSpacing: 1.5,
            color: muted,
          ),
        ),
        const SizedBox(height: 22),
        ..._items.map(
          (tile) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => store.navigate(tile.$1),
                child: BorderGradientPanel(
                  radius: 16,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    child: Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: iconTileBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              tile.$3,
                              size: 26,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            tile.$2,
                            style: GoogleFonts.jetBrainsMono(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: NexusPalette.iconMuted(context),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color mutedOf(BuildContext context) => NexusPalette.textMuted(context);
}

class SavedHubScreen extends StatefulWidget {
  const SavedHubScreen({super.key});

  @override
  State<SavedHubScreen> createState() => _SavedHubScreenState();
}

class _SavedHubScreenState extends State<SavedHubScreen> {
  bool productsTab = true;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NexusController>();
    final muted = NexusPalette.textMuted(context);
    final border =
        NexusPalette.borderSubtle(context);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            border: Border(bottom: BorderSide(color: border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SAVED',
                style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: muted.withValues(alpha: .3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TinyTab(
                        text: 'PRODUCTS (${controller.favorites.length})',
                        active: productsTab,
                        onTap: () =>
                            setState(() => productsTab = true),
                      ),
                    ),
                    Expanded(
                      child: _TinyTab(
                        text: 'CUSTOM (${controller.savedBuilds.length})',
                        active: !productsTab,
                        onTap: () =>
                            setState(() => productsTab = false),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: productsTab
              ? ProductFavorites(controller: controller)
              : BuildFavorites(controller: controller),
        ),
      ],
    );
  }
}

class ProductFavorites extends StatelessWidget {
  const ProductFavorites({super.key, required this.controller});

  final NexusController controller;

  @override
  Widget build(BuildContext context) {
    final muted =
        NexusPalette.textMuted(context);
    final list =
        controller.featuredProducts
            .where((p) => controller.favorites.contains(p.id));

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border_rounded, size: 48, color: NexusPalette.magenta),
              const SizedBox(height: 16),
              Text('NO SAVED PRODUCTS',
                  style:
                      GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                'Tap the heart icon while browsing.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: muted.withValues(alpha: .9)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.count(
      primary: false,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      crossAxisCount: 2,
      childAspectRatio: .68,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        ...list.map(
          (product) => ProductCardMini(
            product,
            fav: controller.favorites.contains(product.id),
            onTap: () =>
                controller.navigate(ViewState.product, params: {'id': product.id}),
            toggleFavorite: () => controller.toggleFavorite(product.id),
          ),
        ),
      ],
    );
  }
}

class BuildFavorites extends StatelessWidget {
  const BuildFavorites({super.key, required this.controller});

  final NexusController controller;

  double total(List<double> parts) => parts.fold(0.0, (a, x) => a + x);

  @override
  Widget build(BuildContext context) {
    final muted =
        NexusPalette.textMuted(context);
    if (controller.savedBuilds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('NO CUSTOM BUILDS YET',
                  style:
                      GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
              Text(
                'Finish the wizard to stash setups here.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: muted),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => controller.navigate(ViewState.builder),
                child: Text('OPEN BUILDER', style: GoogleFonts.jetBrainsMono()),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.all(22),
      itemCount: controller.savedBuilds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final build = controller.savedBuilds[i];
        final dollars = total([
          build.cpu?.price ?? 0,
          build.motherboard?.price ?? 0,
          build.ram?.price ?? 0,
          build.gpu?.price ?? 0,
          build.storage?.price ?? 0,
          build.psu?.price ?? 0,
          build.casePart?.price ?? 0,
        ]);

        line(String tag, String? value) {
          if (value == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text(tag,
                    style: GoogleFonts.jetBrainsMono(fontSize: 9, letterSpacing: 2)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: muted),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: muted.withValues(alpha: .5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Custom Rig #${i + 1}',
                      style:
                          Theme.of(context).textTheme.titleSmall!.copyWith(
                              fontWeight: FontWeight.bold)),
                  Text('\$ ${dollars.toStringAsFixed(2)}',
                      style:
                          GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold,color: NexusPalette.cyan)),
                ],
              ),
              const SizedBox(height: 12),
              line('CPU', build.cpu?.name),
              line('GPU', build.gpu?.name),
              Align(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: OutlinedButton(
                    onPressed: () =>
                        controller.navigate(ViewState.builder),
                    child:
                        Text('LOAD IN BUILDER', style: GoogleFonts.jetBrainsMono(fontSize: 10)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  static const _specs = [
    _CompareSpec(label: 'PRICE', key: 'price', isNumber: true, lowerIsBetter: true),
    _CompareSpec(label: 'CPU', key: 'cpu'),
    _CompareSpec(label: 'GPU', key: 'gpu'),
    _CompareSpec(label: 'RAM', key: 'ram'),
    _CompareSpec(label: 'STORAGE', key: 'storage'),
    _CompareSpec(label: 'GAMING FPS', key: 'gaming', isNumber: true),
    _CompareSpec(label: 'PROD SCORE', key: 'productivity', isNumber: true),
  ];

  static dynamic _value(Product product, String key) {
    switch (key) {
      case 'price':
        return product.price;
      case 'gaming':
      case 'productivity':
        return product.benchmarks != null
            ? (key == 'gaming'
                ? product.benchmarks!.gaming
                : product.benchmarks!.productivity)
            : null;
      default:
        return switch (key) {
          'cpu' => product.specs.cpu,
          'gpu' => product.specs.gpu,
          'ram' => product.specs.ram,
          'storage' => product.specs.storage,
          _ => null,
        };
    }
  }

  static String _displayValue(dynamic value, String key) {
    if (value == null) return '-';
    if (key == 'price' && value is num) {
      return '\$${value.toStringAsFixed(0)}';
    }
    return '$value';
  }

  static int _winner(dynamic v1, dynamic v2, {required bool lowerIsBetter}) {
    if (v1 is! num || v2 is! num) return 0;
    if (v1 == v2) return 0;
    if (lowerIsBetter) return v1 < v2 ? 1 : 2;
    return v1 > v2 ? 1 : 2;
  }

  Widget _compareProductCard(
    BuildContext context,
    Product product, {
    required bool left,
  }) {
    final muted = NexusPalette.textMuted(context);

    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: NexusPalette.borderSubtle(context),
              ),
              color: Theme.of(context).colorScheme.surface,
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: CachedNetworkImage(
                        imageUrl: product.image,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.category.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 32,
                  child: Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: NexusPalette.cyan,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: left ? -8 : null,
            right: left ? null : -8,
            child: Material(
              color: Theme.of(context).colorScheme.secondary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () =>
                    showNexusToast(context, 'ITEM REMOVED FROM COMPARISON'),
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: NexusPalette.borderSubtle(context),
                    ),
                  ),
                  child: Icon(Icons.close, size: 14, color: muted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specRow(
    BuildContext context,
    _CompareSpec spec,
    Product p1,
    Product p2, {
    required bool isLast,
  }) {
    final muted = NexusPalette.textMuted(context);
    final v1 = _value(p1, spec.key);
    final v2 = _value(p2, spec.key);
    final winner = spec.isNumber
        ? _winner(v1, v2, lowerIsBetter: spec.lowerIsBetter)
        : 0;

    Widget valueCell(dynamic value, int side) {
      final isWinner = winner == side;
      final tone = side == 1 ? NexusPalette.cyan : NexusPalette.magenta;
      final text = _displayValue(value, spec.key);

      return Expanded(
        child: Container(
          padding: EdgeInsets.only(bottom: isWinner ? 4 : 0),
          decoration: isWinner
              ? BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: tone, width: 1),
                  ),
                )
              : null,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              color: isWinner
                  ? tone
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: .35),
                ),
              ),
      ),
      child: Column(
        children: [
          Text(
            spec.label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              letterSpacing: 2.4,
              color: muted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              valueCell(v1, 1),
              Container(
                width: 1,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: NexusPalette.borderSubtle(context),
              ),
              valueCell(v2, 2),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NexusController>();
    final products = controller.featuredProducts;
    if (products.isEmpty) {
      return const Center(child: Text('No products to compare'));
    }
    final p1 = products.first;
    final p2 = products.length > 1 ? products[1] : products.first;
    final surface = Theme.of(context).colorScheme.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface.withValues(alpha: 0.82),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: .45),
              ),
            ),
          ),
          child: Text(
            'COMPARE',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _compareProductCard(context, p1, left: true),
              const SizedBox(width: 16),
              _compareProductCard(context, p2, left: false),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: .45),
                  ),
                  color: surface.withValues(alpha: .95),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < _specs.length; i++)
                      _specRow(
                        context,
                        _specs[i],
                        p1,
                        p2,
                        isLast: i == _specs.length - 1,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompareSpec {
  const _CompareSpec({
    required this.label,
    required this.key,
    this.isNumber = false,
    this.lowerIsBetter = false,
  });

  final String label;
  final String key;
  final bool isNumber;
  final bool lowerIsBetter;
}

class _TinyTab extends StatelessWidget {
  const _TinyTab(
      {required this.text, required this.active, required this.onTap});

  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: active ? surface : Colors.transparent,
          boxShadow: active
              ? [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black.withValues(alpha: .15),
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.jetBrainsMono(
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class ProductCardMini extends StatelessWidget {
  const ProductCardMini(
    this.product, {
    required this.fav,
    required this.onTap,
    required this.toggleFavorite,
  });

  final Product product;
  final bool fav;
  final VoidCallback onTap;
  final VoidCallback toggleFavorite;

  @override
  Widget build(BuildContext context) {
    final border =
        NexusPalette.borderSubtle(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          color: Theme.of(context).colorScheme.surface.withOpacity(.9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: CachedNetworkImage(
                        fit: BoxFit.cover,
                        imageUrl: product.image,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: NexusFavoriteButton(
                      isFavorite: fav,
                      onPressed: toggleFavorite,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.category.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(fontSize: 10)),
                  const SizedBox(height: 6),
                  Text(product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Text('\$ ${product.price.toStringAsFixed(2)}',
                      style: GoogleFonts.jetBrainsMono(
                          color: NexusPalette.cyan, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
