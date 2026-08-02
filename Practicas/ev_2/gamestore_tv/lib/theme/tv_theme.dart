import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TvColors {
  static const Color background = Color(0xFF0B0E14);
  static const Color surface = Color(0xFF1A1F2B);
  static const Color neonGreen = Color(0xFF22C55E);
  static const Color gold = Color(0xFFFACC15);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color error = Color(0xFFEF4444);
  static const Color blueAccent = Color(0xFF3B82F6);
}

/// Tema TV: escala 10-foot (SA.2.B) - tipografía grande desde 3 metros.
class TvTheme {
  static ThemeData get darkTheme {
    final base = ThemeData.dark().textTheme;
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: TvColors.background,
      colorScheme: const ColorScheme.dark(
        primary: TvColors.neonGreen,
        secondary: TvColors.blueAccent,
        surface: TvColors.surface,
        error: TvColors.error,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(base).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          color: TvColors.textPrimary,
          fontSize: 88,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.02,
        ),
        headlineLarge: GoogleFonts.spaceGrotesk(
          color: TvColors.textPrimary,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.02,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          color: TvColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.inter(
          color: TvColors.textSecondary,
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.inter(
          color: TvColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.inter(
          color: TvColors.textSecondary,
          fontSize: 24,
        ),
        labelLarge: GoogleFonts.inter(
          color: TvColors.neonGreen,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
