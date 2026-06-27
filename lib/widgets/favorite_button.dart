import 'package:flutter/material.dart';
import '../theme/nexus_palette.dart';

/// Heart toggle used on product cards, detail pages, and saved hub.
class NexusFavoriteButton extends StatelessWidget {
  const NexusFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.size = 22,
    this.compact = false,
  });

  final bool isFavorite;
  final VoidCallback onPressed;
  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark
          ? Colors.black.withValues(alpha: 0.55)
          : Colors.white.withValues(alpha: 0.92),
      elevation: isFavorite ? 2 : 0,
      shadowColor: NexusPalette.magenta.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.all(compact ? 6 : 8),
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: size,
            color: isFavorite
                ? NexusPalette.magenta
                : (dark ? Colors.white : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }
}
