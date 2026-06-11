import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Core backgrounds ──────────────────────────────────────────────────────
  static const Color backgroundColor  = Color(0xFF030309); // Near-black deep space
  static const Color surfaceColor      = Color(0xFF0A0A14); // Elevated surface
  static const Color cardColor         = Color(0xFF0D0D1C); // Dark card base

  // ── Primary neon accent palette ───────────────────────────────────────────
  static const Color primaryBlue       = Color(0xFF00C6FF); // Electric cyan-blue
  static const Color accentBlue        = Color(0xFF0052FF); // Deep royal blue
  static const Color accentPurple      = Color(0xFF7B2FFF); // Volt purple
  static const Color neonGreen         = Color(0xFF00FFB2); // Neon mint green
  static const Color amberAlert        = Color(0xFFFF9D00); // Amber warning
  static const Color criticalRed       = Color(0xFFFF3B5C); // Critical red-pink

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary       = Color(0xFFFFFFFF);
  static const Color textSecondary     = Color(0xFF8F9BB3);
  static const Color textMuted         = Color(0xFF4A5568);

  // ── Glass & borders ───────────────────────────────────────────────────────
  static const Color glassBorderColor  = Color(0xFF1E2A3A);
  static const Color glassGlowColor    = Color(0x2A00C6FF); // 17% alpha cyan glow

  // ── Gradient presets ─────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cynaToGreen = LinearGradient(
    colors: [primaryBlue, neonGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleToBlue = LinearGradient(
    colors: [accentPurple, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [amberAlert, Color(0xFFFF5F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [neonGreen, Color(0xFF00A878)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redGradient = LinearGradient(
    colors: [criticalRed, Color(0xFFFF6B00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Glow shadow helpers ───────────────────────────────────────────────────
  static List<BoxShadow> glowBlue({double intensity = 0.35, double blur = 24}) => [
    BoxShadow(color: primaryBlue.withValues(alpha: intensity), blurRadius: blur, spreadRadius: 0),
  ];

  static List<BoxShadow> glowPurple({double intensity = 0.35, double blur = 24}) => [
    BoxShadow(color: accentPurple.withValues(alpha: intensity), blurRadius: blur, spreadRadius: 0),
  ];

  static List<BoxShadow> glowGreen({double intensity = 0.35, double blur = 24}) => [
    BoxShadow(color: neonGreen.withValues(alpha: intensity), blurRadius: blur, spreadRadius: 0),
  ];

  static List<BoxShadow> glowAmber({double intensity = 0.4, double blur = 24}) => [
    BoxShadow(color: amberAlert.withValues(alpha: intensity), blurRadius: blur, spreadRadius: 0),
  ];

  static List<BoxShadow> glowRed({double intensity = 0.4, double blur = 24}) => [
    BoxShadow(color: criticalRed.withValues(alpha: intensity), blurRadius: blur, spreadRadius: 0),
  ];

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: accentPurple,
        surface: cardColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        error: criticalRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          color: textPrimary,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.outfit(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: GoogleFonts.outfit(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(color: textPrimary),
        bodyMedium: GoogleFonts.inter(color: textSecondary),
        bodySmall: GoogleFonts.inter(color: textMuted, fontSize: 11),
        labelLarge: GoogleFonts.outfit(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: const BorderSide(color: glassBorderColor, width: 0.8),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        elevation: 32,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
          side: const BorderSide(color: glassBorderColor, width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0E0E1E),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: glassBorderColor, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: glassBorderColor, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: criticalRed, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: criticalRed, width: 1.5),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryBlue,
        inactiveTrackColor: glassBorderColor,
        thumbColor: primaryBlue,
        overlayColor: primaryBlue.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
      dividerTheme: const DividerThemeData(
        color: glassBorderColor,
        thickness: 0.8,
      ),
    );
  }
}
