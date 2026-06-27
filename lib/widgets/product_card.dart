import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/nexus_palette.dart';
import 'favorite_button.dart';
import 'ui_kit.dart';

class ProductCardTile extends StatelessWidget {
  const ProductCardTile({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    this.surface,
    this.border,
    this.showBenchmarks = false,
  });

  final Product product;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final Color? surface;
  final Color? border;
  final bool showBenchmarks;

  @override
  Widget build(BuildContext context) {
    final borderColor = border ?? NexusPalette.borderSubtle(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            color: surface ??
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: product.image,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => ColoredBox(
                          color: NexusPalette.borderSubtle(context),
                          child: const Center(
                            child: Icon(Icons.image_outlined, size: 32),
                          ),
                        ),
                        errorWidget: (_, __, ___) => ColoredBox(
                          color: NexusPalette.borderSubtle(context),
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined, size: 32),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: NexusFavoriteButton(
                          isFavorite: isFavorite,
                          onPressed: onToggleFavorite,
                          compact: true,
                        ),
                      ),
                      if (product.isNew == true)
                        _badge(topLeft: true, label: 'NEW', hue: NexusPalette.cyan),
                      if (product.isDeal == true)
                        _badge(
                          topLeft: product.isNew != true,
                          label: 'DEAL',
                          hue: NexusPalette.magenta,
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      product.category.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall!
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '\$${_fmt(product.price)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.bold,
                        color: NexusPalette.cyan,
                      ),
                    ),
                    if (showBenchmarks && product.benchmarks != null) ...[
                      const SizedBox(height: 10),
                      NexusBenchmarkStrip(
                        gaming: product.benchmarks!.gaming,
                        productivity: product.benchmarks!.productivity,
                        compact: true,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge({
    required bool topLeft,
    required String label,
    required Color hue,
  }) {
    final align = topLeft ? Alignment.topLeft : Alignment.topLeft;
    final pad = EdgeInsets.only(left: topLeft ? 10 : 10, top: 10);
    return Align(
      alignment: align,
      child: Padding(
        padding: pad,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: hue.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: hue.withValues(alpha: .45)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                letterSpacing: 2,
                color: hue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(2);
}
