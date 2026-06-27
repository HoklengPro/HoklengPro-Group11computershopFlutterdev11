import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/nexus_palette.dart';

/// Cart / checkout line — image, title, qty, price.
class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.product,
    this.readOnly = false,
    this.onIncrease,
    this.onDecrease,
    this.onDelete,
  });

  final CartItem item;
  final Product? product;
  final bool readOnly;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;
  final VoidCallback? onDelete;

  static String cents(double value) => value.toStringAsFixed(2);

  String get _title {
    if (product != null) return product!.name;
    if (item.productId == 'custom-build') return 'CUSTOM BUILD';
    return 'Product ${item.productId}';
  }

  @override
  Widget build(BuildContext context) {
    final border = NexusPalette.borderSubtle(context);
    final muted = NexusPalette.textMuted(context);
    final lineTotal = item.price * item.qty;

    final opts = item.configOptions;
    final configLabel = opts == null
        ? ''
        : '${opts.ram ?? ''}${opts.ram != null && opts.storage != null ? ' · ' : ''}${opts.storage ?? ''}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 72,
              child: product != null
                  ? CachedNetworkImage(
                      imageUrl: product!.image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => ColoredBox(
                        color: border,
                        child: const Icon(Icons.image_outlined, size: 28),
                      ),
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: border,
                        child: const Icon(Icons.memory, size: 28),
                      ),
                    )
                  : ColoredBox(
                      color: border,
                      child: Icon(Icons.shopping_bag_outlined, color: muted),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (configLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    configLabel,
                    style: GoogleFonts.jetBrainsMono(fontSize: 10, color: muted),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Qty ${item.qty}  ·  \$${cents(item.price)} each',
                  style: GoogleFonts.jetBrainsMono(fontSize: 11, color: muted),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$ ${cents(lineTotal)}',
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.bold,
                    color: NexusPalette.cyan,
                  ),
                ),
              ],
            ),
          ),
          if (!readOnly && onIncrease != null && onDecrease != null) ...[
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: onDecrease,
                      icon: const Icon(Icons.remove_circle_outline, size: 22),
                    ),
                    Text(
                      '${item.qty}',
                      style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: onIncrease,
                      icon: const Icon(Icons.add_circle_outline, size: 22),
                    ),
                  ],
                ),
                if (onDelete != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline, color: muted, size: 22),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
