import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'nexus_palette.dart';
class NexusTheme {
  static ThemeData dark() {
    final baseText = ThemeData.dark().textTheme.copyWith(
      bodyLarge: GoogleFonts.inter(),
      bodyMedium: GoogleFonts.inter(),
      titleLarge:
          GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, letterSpacing: 1.4),
      titleMedium:
          GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w600, letterSpacing: 1.2),
      labelLarge: GoogleFonts.jetBrainsMono(letterSpacing: 1),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NexusPalette.darkBase,
      colorScheme: const ColorScheme.dark(
        surface: NexusPalette.darkSurface,
        secondary: NexusPalette.darkSurfaceLight,
        primary: NexusPalette.cyan,
        tertiary: NexusPalette.magenta,
        onSurface: Color(0xFFE2E8F0),
        onPrimary: Colors.black,
        outline: NexusPalette.darkSurfaceLight,
      ),
      textTheme: baseText.apply(
        bodyColor: const Color(0xFFE2E8F0),
        displayColor: const Color(0xFFE2E8F0),
      ),
      appBarTheme: const AppBarTheme(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      dividerColor: NexusPalette.darkSurfaceLight,
      iconTheme: const IconThemeData(
        size: 24,
        color: Color(0xFFE2E8F0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NexusPalette.darkSurface,
        hintStyle: TextStyle(
          color: const Color(0xFF94A3B8),
          fontFamily: GoogleFonts.inter().fontFamily,
          fontSize: 15,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NexusPalette.darkSurfaceLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NexusPalette.cyan),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  static ThemeData light() {
    final baseText = ThemeData.light().textTheme.copyWith(
      bodyLarge: GoogleFonts.inter(),
      bodyMedium: GoogleFonts.inter(),
      titleLarge:
          GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, letterSpacing: 1.4),
      titleMedium:
          GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w600, letterSpacing: 1.2),
      labelLarge: GoogleFonts.jetBrainsMono(letterSpacing: 1),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: NexusPalette.lightBase,
      colorScheme: const ColorScheme.light(
        surface: NexusPalette.lightSurface,
        secondary: NexusPalette.lightSurfaceLight,
        primary: NexusPalette.cyan,
        tertiary: NexusPalette.magenta,
        onSurface: Color(0xFF0F172A),
      ),
      textTheme: baseText.apply(
        bodyColor: const Color(0xFF0F172A),
        displayColor: const Color(0xFF0F172A),
      ),
      dividerColor: const Color(0xFFE2E8F0),
      iconTheme: const IconThemeData(
        size: 24,
        color: Color(0xFF475569),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NexusPalette.lightSurface,
        hintStyle: TextStyle(
          color: const Color(0xFF64748B),
          fontFamily: GoogleFonts.inter().fontFamily,
          fontSize: 15,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NexusPalette.lightSurfaceLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NexusPalette.cyan),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
