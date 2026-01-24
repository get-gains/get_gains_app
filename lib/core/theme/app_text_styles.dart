import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Application Typography
///
/// Centralized text style definitions following the design system.
/// Uses Poppins as primary font, JetBrains Mono for numbers.
///
/// See docs/DESIGN_STYLE.md for complete typography documentation.
class AppTextStyles {
  AppTextStyles._();

  // ============================================================
  // FONT FAMILIES
  // ============================================================

  /// Primary font for UI elements
  static const String fontFamilySans = 'Poppins';

  /// Serif font for editorial/feature content
  static const String fontFamilySerif = 'Roboto Serif';

  /// Monospace for numbers, code, and tabular data
  static const String fontFamilyMono = 'JetBrains Mono';

  /// Default font family (alias for backward compatibility)
  static const String fontFamily = fontFamilySans;

  // ============================================================
  // DISPLAY STYLES (Hero numbers, splash screens)
  // ============================================================

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.02 * 48, // -0.02em
    height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.01 * 36, // -0.01em
    height: 1.15,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.01 * 32,
    height: 1.2,
  );

  // ============================================================
  // HEADLINE STYLES (Page/section headers)
  // ============================================================

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.01 * 28,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.01 * 24,
    height: 1.3,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.35,
  );

  // ============================================================
  // TITLE STYLES (Card titles, list items)
  // ============================================================

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.01 * 16, // 0.01em
    height: 1.45,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.01 * 14,
    height: 1.4,
  );

  // ============================================================
  // BODY STYLES (Paragraphs, descriptions)
  // ============================================================

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.01 * 16,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.01 * 14,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.02 * 12,
    height: 1.4,
  );

  // ============================================================
  // LABEL STYLES (Buttons, chips, badges)
  // ============================================================

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.02 * 14,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.02 * 12,
    height: 1.35,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.03 * 10,
    height: 1.3,
  );

  // ============================================================
  // SPECIAL STYLES
  // ============================================================

  /// Button text style
  static const TextStyle button = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.02 * 14,
    height: 1.4,
  );

  /// Large button text style
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.01 * 16,
    height: 1.4,
  );

  /// Small button text style
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.02 * 12,
    height: 1.3,
  );

  /// Overline text (all caps, small)
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1 * 10, // 0.1em
    height: 1.4,
  );

  /// Caption text
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.02 * 11,
    height: 1.35,
  );

  // ============================================================
  // NUMERIC STYLES (Monospace for tabular data)
  // ============================================================

  /// Large monetary display (e.g., $14,390.75)
  static const TextStyle numericDisplayLarge = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.01 * 36,
    height: 1.15,
  );

  /// Medium monetary display
  static const TextStyle numericDisplayMedium = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.01 * 28,
    height: 1.2,
  );

  /// Small numeric display
  static const TextStyle numericDisplaySmall = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
  );

  /// Tabular numbers for lists
  static const TextStyle numericBody = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Apply color to any text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Apply font family to any text style
  static TextStyle withFont(TextStyle style, String fontFamily) {
    return style.copyWith(fontFamily: fontFamily);
  }

  /// Apply weight to any text style
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  // ============================================================
  // PRE-STYLED VARIANTS (Convenience methods)
  // ============================================================

  /// Primary headline on light background
  static TextStyle get primaryHeadline =>
      headlineMedium.copyWith(color: AppColors.foregroundLight);

  /// Secondary body text on light background
  static TextStyle get secondaryBody =>
      bodyMedium.copyWith(color: AppColors.mutedForegroundLight);

  /// Muted text style
  static TextStyle get muted =>
      bodySmall.copyWith(color: AppColors.mutedForegroundDark);

  /// Success text style
  static TextStyle get successText =>
      labelMedium.copyWith(color: AppColors.success);

  /// Error text style
  static TextStyle get errorText =>
      labelMedium.copyWith(color: AppColors.error);
}
