import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:krushi_setu/app/theme/app_colors.dart';

class AppTheme {
  static ThemeData light() {
    final textTheme = GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme);
    
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: GoogleFonts.poppins().fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      textTheme: textTheme.apply(
        fontFamily: GoogleFonts.poppins().fontFamily,
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 15,
        ),
        prefixIconColor: AppColors.textBlack, // Ensure prefix icons use textBlack by default
        suffixIconColor: AppColors.textMuted,
      ),
    );
  }
}
