import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/nexus_palette.dart';

/// Clean profile avatar — gradient ring + solid fill + readable initials.
class NexusProfileAvatar extends StatelessWidget {
  const NexusProfileAvatar({
    super.key,
    required this.initials,
    this.radius = 32,
    this.showRing = true,
  });

  final String initials;
  final double radius;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? const Color(0xFF1A1F2E) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final core = CircleAvatar(
      radius: radius,
      backgroundColor: fill,
      child: Text(
        initials.isEmpty ? '?' : initials.toUpperCase(),
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.44,
          color: textColor,
          letterSpacing: 0.4,
        ),
      ),
    );

    if (!showRing) return core;

    return Container(
      padding: EdgeInsets.all(radius > 20 ? 2.5 : 1.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NexusPalette.cyan,
            NexusPalette.magenta,
            NexusPalette.violet,
          ],
        ),
      ),
      child: core,
    );
  }
}
