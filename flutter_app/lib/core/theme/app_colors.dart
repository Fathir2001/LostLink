import 'package:flutter/material.dart';

/// App color palette - Based on LostLink Logo (Blue & Orange)
/// Premium glassmorphism & iOS-inspired design system
class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY COLORS (Deep Blue from logo)
  // ============================================
  static const Color primary = Color(0xFF1A3A5C);
  static const Color primaryLight = Color(0xFF2D5A87);
  static const Color primaryDark = Color(0xFF0D2438);
  static const Color primarySoft = Color(0xFF3D7AB8);

  // ============================================
  // SECONDARY/ACCENT COLORS (Orange from logo)
  // ============================================
  static const Color secondary = Color(0xFFF5821F);
  static const Color secondaryLight = Color(0xFFFF9D47);
  static const Color secondaryDark = Color(0xFFE06B00);
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentLight = Color(0xFFFF8A5C);

  // ============================================
  // STATUS COLORS (iOS-style)
  // ============================================
  static const Color success = Color(0xFF34C759);
  static const Color successLight = Color(0xFFD4F5DD);
  static const Color warning = Color(0xFFFFCC00);
  static const Color warningLight = Color(0xFFFFF9E6);
  static const Color error = Color(0xFFFF3B30);
  static const Color errorLight = Color(0xFFFFE5E4);
  static const Color info = Color(0xFF007AFF);
  static const Color infoLight = Color(0xFFE5F2FF);

  // ============================================
  // NEUTRAL COLORS - Light Mode (iOS-inspired)
  // ============================================
  static const Color backgroundLight = Color(0xFFF2F4F8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE5E5EA);
  static const Color textPrimaryLight = Color(0xFF1C1C1E);
  static const Color textSecondaryLight = Color(0xFF636366);
  static const Color textTertiaryLight = Color(0xFF8E8E93);
  static const Color iconLight = Color(0xFF3C3C43);

  // ============================================
  // NEUTRAL COLORS - Dark Mode (iOS-inspired)
  // ============================================
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color cardDark = Color(0xFF2C2C2E);
  static const Color dividerDark = Color(0xFF38383A);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFAEAEB2);
  static const Color textTertiaryDark = Color(0xFF636366);
  static const Color iconDark = Color(0xFFAEAEB2);

  // ============================================
  // GLASS EFFECT COLORS (Glassmorphism)
  // ============================================
  static const Color glassLight = Color(0xE6FFFFFF);
  static const Color glassMedium = Color(0xB3FFFFFF);
  static const Color glassDark = Color(0x66FFFFFF);
  static const Color glassUltraLight = Color(0xF2FFFFFF);
  static const Color glassBorderLight = Color(0x40FFFFFF);
  static const Color glassBorderDark = Color(0x20FFFFFF);
  static const Color glassShadow = Color(0x1A000000);

  // ============================================
  // CATEGORY COLORS (iOS-style)
  // ============================================
  static const Color categoryElectronics = Color(0xFF007AFF);
  static const Color categoryDocuments = Color(0xFF5856D6);
  static const Color categoryPets = Color(0xFFFF9500);
  static const Color categoryClothing = Color(0xFFFF2D55);
  static const Color categoryJewelry = Color(0xFFAF52DE);
  static const Color categoryBags = Color(0xFF00C7BE);
  static const Color categoryKeys = Color(0xFF5AC8FA);
  static const Color categoryWallet = Color(0xFF34C759);
  static const Color categoryOther = Color(0xFF8E8E93);

  // ============================================
  // POST TYPE COLORS
  // ============================================
  static const Color lost = Color(0xFFFF3B30);
  static const Color lostLight = Color(0xFFFFE5E4);
  static const Color lostGradientStart = Color(0xFFFF6B6B);
  static const Color lostGradientEnd = Color(0xFFFF3B30);
  
  static const Color found = Color(0xFF34C759);
  static const Color foundLight = Color(0xFFD4F5DD);
  static const Color foundGradientStart = Color(0xFF5DD67C);
  static const Color foundGradientEnd = Color(0xFF34C759);

  // ============================================
  // GRADIENTS
  // ============================================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primarySoft, primary],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, secondary],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, accent],
  );

  static const LinearGradient lostGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lostGradientStart, lostGradientEnd],
  );

  static const LinearGradient foundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [foundGradientStart, foundGradientEnd],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5DD67C), success],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1C1C1E),
      Color(0xFF121214),
      Color(0xFF000000),
    ],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A3A5C),
      Color(0xFF0D2438),
      Color(0xFF071620),
    ],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A3A5C),
      Color(0xFF2D5A87),
      Color(0xFFF5821F),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardGlassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x60FFFFFF),
      Color(0x20FFFFFF),
    ],
  );

  static const LinearGradient darkGlassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x40FFFFFF),
      Color(0x10FFFFFF),
    ],
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE5E5EA),
      Color(0xFFF5F5F7),
      Color(0xFFE5E5EA),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ============================================
  // SHIMMER COLORS
  // ============================================
  static const Color shimmerBaseLight = Color(0xFFE5E5EA);
  static const Color shimmerHighlightLight = Color(0xFFF5F5F7);
  static const Color shimmerBaseDark = Color(0xFF2C2C2E);
  static const Color shimmerHighlightDark = Color(0xFF3A3A3C);
}
