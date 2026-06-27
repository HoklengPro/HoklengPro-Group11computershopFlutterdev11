import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/view_state.dart';
import '../state/nexus_controller.dart';
import '../theme/nexus_palette.dart';
import '../widgets/brand_marquee_strip.dart';
import '../widgets/product_card.dart';
import '../widgets/ui_kit.dart';

class NexusHomeScreen extends StatefulWidget {
  const NexusHomeScreen({super.key});

  @override
  State<NexusHomeScreen> createState() => _NexusHomeScreenState();
}

class _NexusHomeScreenState extends State<NexusHomeScreen> {
  int heroIndex = 0;
  Timer? _timer;
  late final ScrollController _listController;

  @override
  void initState() {
    super.initState();
    _listController = ScrollController();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      _stepHero(1);
    });
  }

  void _stepHero(int delta) {
    if (!mounted) return;
    final len = context.read<NexusController>().heroSlides.length;
    if (len == 0) return;
    final next = (heroIndex + delta + len) % len;
    setState(() => heroIndex = next);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NexusController>();
    final muted = NexusPalette.textMuted(context);
    final border = NexusPalette.borderSubtle(context);
    final iconMuted = NexusPalette.iconMuted(context);
    final surface = Theme.of(context).colorScheme.surface;
    final overlay = Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: .45)
        : Colors.black.withValues(alpha: .35);

    IconData categoryIcon(String id) {
      switch (id) {
        case 'laptops':
          return Icons.laptop_mac;
        case 'desktops':
          return Icons.dns;
        case 'components':
          return Icons.memory;
        case 'peripherals':
          return Icons.mouse;
        case 'monitors':
          return Icons.desktop_mac;
        case 'networking':
          return Icons.wifi;
        default:
          return Icons.category_outlined;
      }
    }

    return ListView(
      controller: _listController,
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        SizedBox(
          height: 256,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: Builder(
                  key: ValueKey<int>(heroIndex),
                  builder: (context) {
                    final slide = store.heroSlides[heroIndex];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: slide.image,
                          fit: BoxFit.cover,
                          color: Colors.white.withValues(alpha: .6),
                          colorBlendMode: BlendMode.modulate,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context)
                                    .scaffoldBackgroundColor
                                    .withValues(alpha: 0.94),
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(28),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slide.subtitle.toUpperCase(),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    letterSpacing: 3,
                                    color: slide.isCyanAccent
                                        ? NexusPalette.cyan
                                        : NexusPalette.magenta,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  slide.title,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    backgroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => store.navigate(
                                    ViewState.category,
                                    params: {'category': 'Desktops'},
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'EXPLORE',
                                        style: GoogleFonts.jetBrainsMono(
                                            fontSize: 11),
                                      ),
                                      const Icon(Icons.chevron_right, size: 18),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 24, bottom: 16),
                  child: Row(
                    children: List.generate(store.heroSlides.length, (i) {
                      final active = i == heroIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: active ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: active
                              ? NexusPalette.cyan
                              : surface.withValues(alpha: .65),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    blurRadius: 12,
                                    color:
                                        NexusPalette.cyan.withValues(alpha: .3),
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _ScanlinePainter(overlay)),
                ),
              ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            border: Border(
              top: BorderSide(color: border),
              bottom: BorderSide(color: border),
            ),
          ),
          child: SizedBox(
            height: 84,
            child: InfiniteBrandMarquee(
              brands: store.marqueeBrands,
              surface: surface,
              border: border,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 6),
          child: Row(
            children: [
              const GlowDot(color: NexusPalette.magenta),
              const SizedBox(width: 12),
              Text(
                'CATEGORIES',
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: muted,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: GridView.builder(
            primary: false,
            itemCount: store.categoryTiles.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, idx) {
              final cat = store.categoryTiles[idx];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => store.navigate(
                    ViewState.category,
                    params: {'category': cat.label},
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.9),
                      border:
                          Border.all(color: border.withValues(alpha: .7)),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          categoryIcon(cat.id),
                          color: iconMuted,
                          size: 26,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat.label.toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: BorderGradientPanel(
            radius: 20,
            child: Stack(
              children: [
                Positioned(
                  right: -52,
                  top: -62,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: NexusPalette.violet.withValues(alpha: .18),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 60,
                          color: NexusPalette.violet.withValues(alpha: .3),
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BUILD OF THE MONTH',
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: NexusPalette.violet,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Neon Phantom',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ryzen 7 7800X3D + RTX 4080 Super in a stunning dual-chamber showcase.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              height: 1.36,
                              color: muted,
                            ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: muted.withValues(alpha: .55)),
                          backgroundColor:
                              Colors.white.withValues(alpha: .08),
                        ),
                        onPressed: () =>
                            store.navigate(ViewState.product, params: {'id': 'botm'}),
                        child: Text(
                          'VIEW SPECS',
                          style: GoogleFonts.jetBrainsMono(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 34),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Row(
                children: [
                  const GlowDot(color: NexusPalette.cyan),
                  const SizedBox(width: 12),
                  Text(
                    'FEATURED DEALS',
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: muted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: () => store.navigate(
                  ViewState.category,
                  params: {'category': 'All Deals'},
                ),
                child: Text(
                  'VIEW ALL',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: NexusPalette.cyan,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 112),
          child: LayoutGrid(
            store: store,
            border: border,
          ),
        ),
      ],
    );
  }
}

class LayoutGrid extends StatelessWidget {
  const LayoutGrid({
    super.key,
    required this.store,
    required this.border,
  });

  final NexusController store;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      primary: false,
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Match React ProductCard proportions (square image + compact text).
      childAspectRatio: .72,
      children: store.featuredProducts.map((p) {
        return ProductCardTile(
          surface: Theme.of(context).colorScheme.surface,
          border: border,
          product: p,
          isFavorite: store.favorites.contains(p.id),
          onToggleFavorite: () => store.toggleFavorite(p.id),
          onTap: () =>
              store.navigate(ViewState.product, params: {'id': p.id}),
          showBenchmarks: false,
        );
      }).toList(),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  _ScanlinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: .06);
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) =>
      oldDelegate.color != color;
}
