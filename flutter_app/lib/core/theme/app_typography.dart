import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App typography styles - iOS/San Francisco inspired
/// Using Inter as the closest Google Font to SF Pro
class AppTypography {
  AppTypography._();

  // SF Pro Display equivalent - for large titles
  static TextStyle get _displayStyle => GoogleFonts.inter();
  
  // SF Pro Text equivalent - for body text
  static TextStyle get _textStyle => GoogleFonts.inter();

  static String get fontFamily => GoogleFonts.inter().fontFamily ?? 'Inter';

  // ============================================
  // DISPLAY STYLES (Large Titles - iOS style)
  // ============================================
  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static TextStyle get displayMedium => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.22,
  );

  static TextStyle get displaySmall => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.25,
  );

  // ============================================
  // HEADLINE STYLES (Section Headers)
  // ============================================
  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.27,
  );

  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.3,
  );

  static TextStyle get headlineSmall => GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.05,
    height: 1.35,
  );

  // ============================================
  // TITLE STYLES (Navigation & List Headers)
  // ============================================
  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.02,
    height: 1.35,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
  );

  static TextStyle get titleSmall => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
  );

  // ============================================
  // BODY STYLES (Content Text)
  // ============================================
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.02,
    height: 1.47,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.47,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.46,
  );

  // ============================================
  // LABEL STYLES (Buttons, Tags, Small Elements)
  // ============================================
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.33,
  );

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.33,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.27,
  );

  // ============================================
  // BUTTON TEXT (iOS-style)
  // ============================================
  static TextStyle get button => GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.02,
    height: 1.18,
  );

  static TextStyle get buttonSmall => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.2,
  );

  // ============================================
  // CAPTION & FOOTNOTE (iOS-style)
  // ============================================
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.33,
  );

  static TextStyle get footnote => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.38,
  );

  // ============================================
  // OVERLINE (All Caps Small Text)
  // ============================================
  static TextStyle get overline => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    height: 1.27,
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
