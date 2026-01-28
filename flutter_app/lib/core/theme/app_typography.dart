import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App typography styles
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';

  // Display Styles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
    height: 1.25,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
    height: 1.3,
  );

  // Headline Styles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.35,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );

  // Title Styles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.45,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.45,
  );

  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    height: 1.5,
  );

  // Label Styles
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
  );

  // Button Text
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.4,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    height: 1.4,
  );

  // Overline
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
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
