import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF0B0E14);
  static const Color surface = Color(0xFF1A1F2B);
  static const Color card = Color(0xFF1A1F2B);
  static const Color neonGreen = Color(0xFF22C55E);
  static const Color neonGreenDim = Color(0xFF16A34A);
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDim = Color(0xFFCCA800);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF475569);
  static const Color error = Color(0xFFEF4444);
  static const Color blueAccent = Color(0xFF3B82F6);
}

class AppTheme {
  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    );
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonGreen,
        secondary: AppColors.blueAccent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.04,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        labelLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
        iconTheme: const IconThemeData(color: AppColors.neonGreen),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.neonGreen,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGreen,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.textSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.textSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIconColor: AppColors.textSecondary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.textSecondary,
        thickness: 0.5,
      ),
    );
  }
}
