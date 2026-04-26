import 'package:flutter/material.dart';

/// Application Color Palette
///
/// Centralized color definitions based on the design system.
/// Dark mode is primary, light mode is secondary.
///
/// See docs/DESIGN_STYLE.md for complete color documentation.
class AppColors {
  AppColors._();

  // ============================================================
  // DARK MODE COLORS (Primary)
  // ============================================================

  // Core Colors - Dark
  static const Color backgroundDark = Color(0xFF1A1A1A);
  static const Color foregroundDark = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF252525);
  static const Color cardForegroundDark = Color(0xFFFFFFFF);
  static const Color popoverDark = Color(0xFF252525);
  static const Color popoverForegroundDark = Color(0xFFFFFFFF);

  // Primary - Orange/Coral
  static const Color primaryDark = Color(0xFFE07D3B);
  static const Color primaryForegroundDark = Color(0xFFFFFFFF);

  // Secondary
  static const Color secondaryDark = Color(0xFF363636);
  static const Color secondaryForegroundDark = Color(0xFFFFFFFF);

  // Muted
  static const Color mutedDark = Color(0xFF363636);
  static const Color mutedForegroundDark = Color(0xFFA1A1AA);

  // Accent - Green
  static const Color accentDark = Color(0xFF4ADE80);
  static const Color accentForegroundDark = Color(0xFFFFFFFF);

  // Destructive
  static const Color destructiveDark = Color(0xFF7F1D1D);
  static const Color destructiveForegroundDark = Color(0xFFFFFFFF);

  // Borders & Input - Dark
  static const Color borderDark = Color(0xFF363636);
  static const Color inputDark = Color(0xFF363636);
  static const Color ringDark = Color(0xFFE8844A);

  // Surface Elevation - Dark
  static const Color surface0Dark = Color(0xFF1A1A1A);
  static const Color surface1Dark = Color(0xFF252525);
  static const Color surface2Dark = Color(0xFF2E2E2E);
  static const Color surface3Dark = Color(0xFF363636);

  // ============================================================
  // LIGHT MODE COLORS (Secondary)
  // ============================================================

  // Core Colors - Light
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color foregroundLight = Color(0xFF1A1A1A);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardForegroundLight = Color(0xFF1A1A1A);
  static const Color popoverLight = Color(0xFFFFFFFF);
  static const Color popoverForegroundLight = Color(0xFF1A1A1A);

  // Primary - Orange/Coral
  static const Color primaryLight = Color(0xFFE8844A);
  static const Color primaryForegroundLight = Color(0xFFFFFFFF);

  // Secondary
  static const Color secondaryLight = Color(0xFFE4E4E7);
  static const Color secondaryForegroundLight = Color(0xFF1A1A1A);

  // Muted
  static const Color mutedLight = Color(0xFFF4F4F5);
  static const Color mutedForegroundLight = Color(0xFF71717A);

  // Accent - Green
  static const Color accentLight = Color(0xFFECFDF5);
  static const Color accentForegroundLight = Color(0xFF166534);

  // Destructive
  static const Color destructiveLight = Color(0xFFDC2626);
  static const Color destructiveForegroundLight = Color(0xFFFFFFFF);

  // Borders & Input - Light
  static const Color borderLight = Color(0xFFE4E4E7);
  static const Color inputLight = Color(0xFFE4E4E7);
  static const Color ringLight = Color(0xFFE8844A);

  // Surface Elevation - Light
  static const Color surface0Light = Color(0xFFF5F5F5);
  static const Color surface1Light = Color(0xFFFFFFFF);
  static const Color surface2Light = Color(0xFFFFFFFF);
  static const Color surface3Light = Color(0xFFF4F4F5);

  // ============================================================
  // SEMANTIC COLORS (Mode-independent references)
  // ============================================================

  // Success
  static const Color success = Color(0xFF4ADE80);
  static const Color successMuted = Color(0xFF166534);
  static const Color successLight = Color(0xFFDCFCE7);

  // Warning
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningMuted = Color(0xFF854D0E);
  static const Color warningLight = Color(0xFFFEF3C7);

  // Error
  static const Color error = Color(0xFFF87171);
  static const Color errorMuted = Color(0xFF7F1D1D);
  static const Color errorLight = Color(0xFFFEE2E2);

  // Info
  static const Color info = Color(0xFF60A5FA);
  static const Color infoMuted = Color(0xFF1E40AF);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Coach Tools
  static const Color coach = Color(0xFF0F766E);
  static const Color coachMuted = Color(0xFF115E59);

  // ============================================================
  // CHART COLORS
  // ============================================================

  static const Color chart1 = Color(0xFFE8844A); // Primary orange
  static const Color chart2 = Color(0xFFF5E6B3); // Cream/Gold
  static const Color chart3 = Color(0xFF4ADE80); // Green
  static const Color chart4 = Color(0xFF60A5FA); // Blue
  static const Color chart5 = Color(0xFFA78BFA); // Purple

  // Chart colors for dark mode (slightly adjusted)
  static const Color chart1Dark = Color(0xFFE8844A);
  static const Color chart2Dark = Color(0xFFF5E6B3);
  static const Color chart3Dark = Color(0xFFD4EDDA);
  static const Color chart4Dark = Color(0xFFD1E7F5);
  static const Color chart5Dark = Color(0xFF4A4A4A);

  // ============================================================
  // NEUTRAL GRAYS (Utility)
  // ============================================================

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // Gray scale
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF4F4F5);
  static const Color gray200 = Color(0xFFE4E4E7);
  static const Color gray300 = Color(0xFFD4D4D8);
  static const Color gray400 = Color(0xFFA1A1AA);
  static const Color gray500 = Color(0xFF71717A);
  static const Color gray600 = Color(0xFF52525B);
  static const Color gray700 = Color(0xFF3F3F46);
  static const Color gray800 = Color(0xFF27272A);
  static const Color gray900 = Color(0xFF18181B);
  static const Color gray950 = Color(0xFF09090B);

  // ============================================================
  // LEGACY ALIASES (for backward compatibility)
  // ============================================================

  // Text Colors (deprecated - use colorScheme instead)
  static const Color textPrimaryLight = foregroundLight;
  static const Color textSecondaryLight = mutedForegroundLight;
  static const Color textTertiaryLight = Color(0xFF9CA3AF);

  static const Color textPrimaryDark = foregroundDark;
  static const Color textSecondaryDark = mutedForegroundDark;
  static const Color textTertiaryDark = Color(0xFF71717A);

  // Divider Colors
  static const Color dividerLight = borderLight;
  static const Color dividerDark = borderDark;

  // Surface aliases
  static const Color surfaceLight = cardLight;
  static const Color surfaceDark = cardDark;

  // ============================================================
  // GRADIENT DEFINITIONS
  // ============================================================

  /// Primary gradient for cards and buttons
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8844A), Color(0xFFD97706)],
  );

  /// Card gradient (dark mode)
  static const LinearGradient cardGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E2E2E), Color(0xFF252525)],
  );

  /// Success gradient
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
  );

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Get primary color based on brightness
  static Color primary(Brightness brightness) {
    return brightness == Brightness.dark ? primaryDark : primaryLight;
  }

  /// Get background color based on brightness
  static Color background(Brightness brightness) {
    return brightness == Brightness.dark ? backgroundDark : backgroundLight;
  }

  /// Get surface color at specified level (0-3)
  static Color surface(Brightness brightness, int level) {
    if (brightness == Brightness.dark) {
      switch (level) {
        case 0:
          return surface0Dark;
        case 1:
          return surface1Dark;
        case 2:
          return surface2Dark;
        default:
          return surface3Dark;
      }
    } else {
      switch (level) {
        case 0:
          return surface0Light;
        case 1:
          return surface1Light;
        case 2:
          return surface2Light;
        default:
          return surface3Light;
      }
    }
  }

  /// Create a color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
}
