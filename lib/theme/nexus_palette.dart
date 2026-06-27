import 'package:flutter/material.dart';
/// Brand + surface colors matching the Magic Pattern / React Nexus UI.
abstract final class NexusPalette {
  static const Color cyan = Color(0xFF00E5FF);
  static const Color magenta = Color(0xFFFF2BD6);
  static const Color violet = Color(0xFF7C3AFF);
  static const Color frameOuter = Color(0xFF050508);
  static const Color phoneBorder = Color(0xFF1A1A24);

  /// Dark surfaces (defaults)
  static const Color darkBase = Color(0xFF0A0A0F);
  static const Color darkSurface = Color(0xFF12121A);
  static const Color darkSurfaceLight = Color(0xFF1A1A24);

  /// Light surfaces
  static const Color lightBase = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceLight = Color(0xFFF1F5F9);

  static Gradient rgbGradientLinear = const LinearGradient(
    colors: [cyan, magenta, violet],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static Gradient textGradientHorizontal = LinearGradient(
    colors: [cyan.withValues(alpha: 0.95), magenta, violet],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Matches React `--text-muted` from `index.css`.
  static Color textMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFCBD5E1)
          : const Color(0xFF64748B);

  /// Secondary icons (nav, chevrons, toolbar) — higher contrast than body muted.
  static Color iconMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFE2E8F0)
          : const Color(0xFF475569);

  static Color textMain(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// Subtle borders that stay visible in both themes.
  static Color borderSubtle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2A2A38)
          : const Color(0xFFE2E8F0);
}
