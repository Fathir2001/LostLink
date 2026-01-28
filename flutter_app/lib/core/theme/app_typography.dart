import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App typography styles using Google Fonts
class AppTypography {
  AppTypography._();

  // Using Google Fonts - no need to download font files!
  static TextStyle get _baseStyle => GoogleFonts.inter();
  
  static String get fontFamily => GoogleFonts.inter().fontFamily ?? 'Inter';

  // Display Styles
  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle get displayMedium => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
    height: 1.25,
  );

  static TextStyle get displaySmall => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
    height: 1.3,
  );

  // Headline Styles
  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.35,
  );

  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );

  static TextStyle get headlineSmall => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );

  // Title Styles
  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.45,
  );

  static TextStyle get titleSmall => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.45,
  );

  // Body Styles
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    height: 1.5,
  );

  // Label Styles
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
  );

  // Button Text
  static TextStyle get button => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.4,
  );

  // Caption
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    height: 1.4,
  );

  // Overline
  static TextStyle get overline => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    height: 1.4,
  );
}

/// Text theme for light mode
TextTheme lightTextTheme = TextTheme(
  displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.textPrimaryLight),
  displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.textPrimaryLight),
  displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.textPrimaryLight),
  headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.textPrimaryLight),
  headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.textPrimaryLight),
  headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimaryLight),
  titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.textPrimaryLight),
  titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.textPrimaryLight),
  titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.textSecondaryLight),
  bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimaryLight),
  bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
  bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryLight),
  labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.textPrimaryLight),
  labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.textSecondaryLight),
  labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.textTertiaryLight),
);

/// Text theme for dark mode
TextTheme darkTextTheme = TextTheme(
  displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.textPrimaryDark),
  displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.textPrimaryDark),
  displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.textPrimaryDark),
  headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.textPrimaryDark),
  headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.textPrimaryDark),
  headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimaryDark),
  titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.textPrimaryDark),
  titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.textPrimaryDark),
  titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.textSecondaryDark),
  bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimaryDark),
  bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
  bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryDark),
  labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.textPrimaryDark),
  labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.textSecondaryDark),
  labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.textTertiaryDark),
);
