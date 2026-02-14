import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Application Theme Configuration
///
/// Provides dark and light theme data based on the design system.
/// Dark mode is primary (optimized), light mode is secondary.
///
/// Usage:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
///   themeMode: ThemeMode.dark, // Dark mode as default
/// )
/// ```
///
/// See docs/DESIGN_STYLE.md for complete design documentation.
class AppTheme {
  AppTheme._();

  // ============================================================
  // SPACING CONSTANTS
  // ============================================================

  /// Base spacing unit (4px)
  static const double spacingUnit = 4.0;

  /// Spacing scale
  static const double spacing1 = spacingUnit; // 4px
  static const double spacing2 = spacingUnit * 2; // 8px
  static const double spacing3 = spacingUnit * 3; // 12px
  static const double spacing4 = spacingUnit * 4; // 16px
  static const double spacing5 = spacingUnit * 5; // 20px
  static const double spacing6 = spacingUnit * 6; // 24px
  static const double spacing8 = spacingUnit * 8; // 32px
  static const double spacing10 = spacingUnit * 10; // 40px
  static const double spacing12 = spacingUnit * 12; // 48px
  static const double spacing16 = spacingUnit * 16; // 64px

  // ============================================================
  // BORDER RADIUS CONSTANTS
  // ============================================================

  static const double radiusNone = 0;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radius2xl = 24;
  static const double radiusFull = 9999;

  /// Common border radius values
  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );
  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );
  static const BorderRadius borderRadiusLg = BorderRadius.all(
    Radius.circular(radiusLg),
  );
  static const BorderRadius borderRadiusXl = BorderRadius.all(
    Radius.circular(radiusXl),
  );
  static const BorderRadius borderRadiusFull = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  // ============================================================
  // PADDING CONSTANTS
  // ============================================================

  /// Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: spacing5,
    vertical: spacing4,
  );

  /// Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(spacing5);

  /// List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: spacing4,
    vertical: spacing3,
  );

  /// Button padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: spacing6,
    vertical: spacing4,
  );

  /// Compact button padding
  static const EdgeInsets buttonPaddingCompact = EdgeInsets.symmetric(
    horizontal: spacing4,
    vertical: spacing3,
  );

  // ============================================================
  // ANIMATION CONSTANTS
  // ============================================================

  static const Duration durationInstant = Duration.zero;
  static const Duration durationFast = Duration(milliseconds: 100);
  static const Duration durationNormal = Duration(milliseconds: 200);
  static const Duration durationSlow = Duration(milliseconds: 300);
  static const Duration durationSlower = Duration(milliseconds: 400);

  static const Curve curveDefault = Curves.easeInOut;
  static const Curve curveEnter = Curves.easeOut;
  static const Curve curveExit = Curves.easeIn;

  // ============================================================
  // DARK THEME (Primary)
  // ============================================================

  /// Dark Theme - Primary, optimized theme
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _darkColorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      fontFamily: AppTextStyles.fontFamilySans,
      appBarTheme: _darkAppBarTheme,
      cardTheme: _darkCardTheme,
      elevatedButtonTheme: _darkElevatedButtonTheme,
      outlinedButtonTheme: _darkOutlinedButtonTheme,
      textButtonTheme: _darkTextButtonTheme,
      filledButtonTheme: _darkFilledButtonTheme,
      inputDecorationTheme: _darkInputDecorationTheme,
      dividerTheme: _darkDividerTheme,
      textTheme: _textTheme,
      iconTheme: const IconThemeData(color: AppColors.mutedForegroundDark),
      floatingActionButtonTheme: _darkFabTheme,
      bottomNavigationBarTheme: _darkBottomNavTheme,
      navigationBarTheme: _darkNavigationBarTheme,
      snackBarTheme: _snackBarTheme,
      chipTheme: _darkChipTheme,
      dialogTheme: _darkDialogTheme,
      bottomSheetTheme: _darkBottomSheetTheme,
      listTileTheme: _darkListTileTheme,
      switchTheme: _darkSwitchTheme,
      checkboxTheme: _darkCheckboxTheme,
      radioTheme: _darkRadioTheme,
      progressIndicatorTheme: _darkProgressTheme,
      sliderTheme: _darkSliderTheme,
      tabBarTheme: _darkTabBarTheme,
      tooltipTheme: _tooltipTheme,
      extensions: const [AppColorsExtension.dark()],
    );
  }

  // ============================================================
  // LIGHT THEME (Secondary)
  // ============================================================

  /// Light Theme - Secondary theme
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _lightColorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      fontFamily: AppTextStyles.fontFamilySans,
      appBarTheme: _lightAppBarTheme,
      cardTheme: _lightCardTheme,
      elevatedButtonTheme: _lightElevatedButtonTheme,
      outlinedButtonTheme: _lightOutlinedButtonTheme,
      textButtonTheme: _lightTextButtonTheme,
      filledButtonTheme: _lightFilledButtonTheme,
      inputDecorationTheme: _lightInputDecorationTheme,
      dividerTheme: _lightDividerTheme,
      textTheme: _textTheme,
      iconTheme: const IconThemeData(color: AppColors.mutedForegroundLight),
      floatingActionButtonTheme: _lightFabTheme,
      bottomNavigationBarTheme: _lightBottomNavTheme,
      navigationBarTheme: _lightNavigationBarTheme,
      snackBarTheme: _snackBarTheme,
      chipTheme: _lightChipTheme,
      dialogTheme: _lightDialogTheme,
      bottomSheetTheme: _lightBottomSheetTheme,
      listTileTheme: _lightListTileTheme,
      switchTheme: _lightSwitchTheme,
      checkboxTheme: _lightCheckboxTheme,
      radioTheme: _lightRadioTheme,
      progressIndicatorTheme: _lightProgressTheme,
      sliderTheme: _lightSliderTheme,
      tabBarTheme: _lightTabBarTheme,
      tooltipTheme: _tooltipTheme,
      extensions: const [AppColorsExtension.light()],
    );
  }

  // ============================================================
  // COLOR SCHEMES
  // ============================================================

  static const ColorScheme _darkColorScheme = ColorScheme.dark(
    brightness: Brightness.dark,
    primary: AppColors.primaryDark,
    onPrimary: AppColors.primaryForegroundDark,
    primaryContainer: AppColors.surface2Dark,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondaryDark,
    onSecondary: AppColors.secondaryForegroundDark,
    secondaryContainer: AppColors.surface2Dark,
    onSecondaryContainer: AppColors.secondaryForegroundDark,
    tertiary: AppColors.accentDark,
    onTertiary: AppColors.accentForegroundDark,
    tertiaryContainer: AppColors.successMuted,
    onTertiaryContainer: AppColors.accentDark,
    error: AppColors.error,
    onError: AppColors.white,
    errorContainer: AppColors.errorMuted,
    onErrorContainer: AppColors.error,
    surface: AppColors.surface1Dark,
    onSurface: AppColors.foregroundDark,
    surfaceContainerHighest: AppColors.surface3Dark,
    onSurfaceVariant: AppColors.mutedForegroundDark,
    outline: AppColors.borderDark,
    outlineVariant: AppColors.surface3Dark,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.foregroundDark,
    onInverseSurface: AppColors.backgroundDark,
    inversePrimary: AppColors.primaryLight,
  );

  static const ColorScheme _lightColorScheme = ColorScheme.light(
    brightness: Brightness.light,
    primary: AppColors.primaryLight,
    onPrimary: AppColors.primaryForegroundLight,
    primaryContainer: AppColors.surface2Light,
    onPrimaryContainer: AppColors.primaryLight,
    secondary: AppColors.secondaryLight,
    onSecondary: AppColors.secondaryForegroundLight,
    secondaryContainer: AppColors.surface3Light,
    onSecondaryContainer: AppColors.secondaryForegroundLight,
    tertiary: AppColors.accentForegroundLight,
    onTertiary: AppColors.white,
    tertiaryContainer: AppColors.accentLight,
    onTertiaryContainer: AppColors.accentForegroundLight,
    error: AppColors.destructiveLight,
    onError: AppColors.white,
    errorContainer: AppColors.errorLight,
    onErrorContainer: AppColors.destructiveLight,
    surface: AppColors.surface1Light,
    onSurface: AppColors.foregroundLight,
    surfaceContainerHighest: AppColors.surface3Light,
    onSurfaceVariant: AppColors.mutedForegroundLight,
    outline: AppColors.borderLight,
    outlineVariant: AppColors.secondaryLight,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.foregroundLight,
    onInverseSurface: AppColors.backgroundLight,
    inversePrimary: AppColors.primaryDark,
  );

  // ============================================================
  // APP BAR THEMES
  // ============================================================

  static const AppBarTheme _darkAppBarTheme = AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: AppColors.backgroundDark,
    foregroundColor: AppColors.foregroundDark,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
    titleTextStyle: AppTextStyles.titleLarge,
    centerTitle: false,
    iconTheme: IconThemeData(color: AppColors.foregroundDark),
  );

  static const AppBarTheme _lightAppBarTheme = AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: AppColors.backgroundLight,
    foregroundColor: AppColors.foregroundLight,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
    titleTextStyle: AppTextStyles.titleLarge,
    centerTitle: false,
    iconTheme: IconThemeData(color: AppColors.foregroundLight),
  );

  // ============================================================
  // CARD THEMES
  // ============================================================

  static const CardThemeData _darkCardTheme = CardThemeData(
    elevation: 0,
    color: AppColors.cardDark,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: borderRadiusLg,
      side: BorderSide(color: AppColors.borderDark, width: 1),
    ),
    margin: EdgeInsets.zero,
  );

  static const CardThemeData _lightCardTheme = CardThemeData(
    elevation: 0,
    color: AppColors.cardLight,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: borderRadiusLg,
      side: BorderSide(color: AppColors.borderLight, width: 1),
    ),
    margin: EdgeInsets.zero,
  );

  // ============================================================
  // BUTTON THEMES
  // ============================================================

  // Elevated Button (Primary filled)
  static final ElevatedButtonThemeData _darkElevatedButtonTheme =
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.primaryForegroundDark,
          disabledBackgroundColor: AppColors.mutedDark,
          disabledForegroundColor: AppColors.mutedForegroundDark,
          padding: buttonPadding,
          shape: const RoundedRectangleBorder(borderRadius: borderRadiusMd),
          textStyle: AppTextStyles.button,
        ),
      );

  static final ElevatedButtonThemeData _lightElevatedButtonTheme =
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primaryForegroundLight,
          disabledBackgroundColor: AppColors.mutedLight,
          disabledForegroundColor: AppColors.mutedForegroundLight,
          padding: buttonPadding,
          shape: const RoundedRectangleBorder(borderRadius: borderRadiusMd),
          textStyle: AppTextStyles.button,
        ),
      );

  // Filled Button (Primary variant)
  static final FilledButtonThemeData _darkFilledButtonTheme =
      FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.primaryForegroundDark,
          disabledBackgroundColor: AppColors.mutedDark,
          disabledForegroundColor: AppColors.mutedForegroundDark,
          padding: buttonPadding,
          shape: const RoundedRectangleBorder(borderRadius: borderRadiusMd),
          textStyle: AppTextStyles.button,
        ),
      );

  static final FilledButtonThemeData _lightFilledButtonTheme =
      FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primaryForegroundLight,
          disabledBackgroundColor: AppColors.mutedLight,
          disabledForegroundColor: AppColors.mutedForegroundLight,
          padding: buttonPadding,
          shape: const RoundedRectangleBorder(borderRadius: borderRadiusMd),
          textStyle: AppTextStyles.button,
        ),
      );

  // Outlined Button
  static final OutlinedButtonThemeData _darkOutlinedButtonTheme =
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foregroundDark,
          disabledForegroundColor: AppColors.mutedForegroundDark,
          padding: buttonPadding,
          shape: const RoundedRectangleBorder(borderRadius: borderRadiusMd),
          side: const BorderSide(color: AppColors.borderDark),
          textStyle: AppTextStyles.button,
        ),
      );

  static final OutlinedButtonThemeData _lightOutlinedButtonTheme =
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foregroundLight,
          disabledForegroundColor: AppColors.mutedForegroundLight,
          padding: buttonPadding,
          shape: const RoundedRectangleBorder(borderRadius: borderRadiusMd),
          side: const BorderSide(color: AppColors.borderLight),
          textStyle: AppTextStyles.button,
        ),
      );

  // Text Button (Ghost)
  static final TextButtonThemeData _darkTextButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryDark,
      disabledForegroundColor: AppColors.mutedForegroundDark,
      padding: buttonPaddingCompact,
      shape: const RoundedRectangleBorder(borderRadius: borderRadiusMd),
      textStyle: AppTextStyles.button,
    ),
  );

  static final TextButtonThemeData _lightTextButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryLight,
      disabledForegroundColor: AppColors.mutedForegroundLight,
      padding: buttonPaddingCompact,
      shape: const RoundedRectangleBorder(borderRadius: borderRadiusMd),
      textStyle: AppTextStyles.button,
    ),
  );

  // ============================================================
  // INPUT THEMES
  // ============================================================

  static const InputDecorationTheme _darkInputDecorationTheme =
      InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputDark,
        border: OutlineInputBorder(
          borderRadius: borderRadiusMd,
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusMd,
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusMd,
          borderSide: BorderSide(color: AppColors.ringDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadiusMd,
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadiusMd,
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusMd,
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: AppColors.mutedForegroundDark),
        labelStyle: TextStyle(color: AppColors.mutedForegroundDark),
        errorStyle: TextStyle(color: AppColors.error, fontSize: 12),
      );

  static const InputDecorationTheme _lightInputDecorationTheme =
      InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface1Light,
        border: OutlineInputBorder(
          borderRadius: borderRadiusMd,
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusMd,
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusMd,
          borderSide: BorderSide(color: AppColors.ringLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadiusMd,
          borderSide: BorderSide(color: AppColors.destructiveLight),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadiusMd,
          borderSide: BorderSide(color: AppColors.destructiveLight, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusMd,
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: AppColors.mutedForegroundLight),
        labelStyle: TextStyle(color: AppColors.mutedForegroundLight),
        errorStyle: TextStyle(color: AppColors.destructiveLight, fontSize: 12),
      );

  // ============================================================
  // DIVIDER THEMES
  // ============================================================

  static const DividerThemeData _darkDividerTheme = DividerThemeData(
    color: AppColors.borderDark,
    thickness: 1,
    space: 1,
  );

  static const DividerThemeData _lightDividerTheme = DividerThemeData(
    color: AppColors.borderLight,
    thickness: 1,
    space: 1,
  );

  // ============================================================
  // TEXT THEME
  // ============================================================

  static const TextTheme _textTheme = TextTheme(
    displayLarge: AppTextStyles.displayLarge,
    displayMedium: AppTextStyles.displayMedium,
    displaySmall: AppTextStyles.displaySmall,
    headlineLarge: AppTextStyles.headlineLarge,
    headlineMedium: AppTextStyles.headlineMedium,
    headlineSmall: AppTextStyles.headlineSmall,
    titleLarge: AppTextStyles.titleLarge,
    titleMedium: AppTextStyles.titleMedium,
    titleSmall: AppTextStyles.titleSmall,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    bodySmall: AppTextStyles.bodySmall,
    labelLarge: AppTextStyles.labelLarge,
    labelMedium: AppTextStyles.labelMedium,
    labelSmall: AppTextStyles.labelSmall,
  );

  // ============================================================
  // FAB THEMES
  // ============================================================

  static const FloatingActionButtonThemeData _darkFabTheme =
      FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: StadiumBorder(),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.primaryForegroundDark,
      );

  static const FloatingActionButtonThemeData _lightFabTheme =
      FloatingActionButtonThemeData(
        elevation: 2,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 4,
        shape: StadiumBorder(),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.primaryForegroundLight,
      );

  // ============================================================
  // NAVIGATION THEMES
  // ============================================================

  static const BottomNavigationBarThemeData _darkBottomNavTheme =
      BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface1Dark,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.mutedForegroundDark,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      );

  static const BottomNavigationBarThemeData _lightBottomNavTheme =
      BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface1Light,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.mutedForegroundLight,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      );

  static final NavigationBarThemeData _darkNavigationBarTheme =
      NavigationBarThemeData(
        backgroundColor: AppColors.surface1Dark,
        indicatorColor: AppColors.primaryDark.withOpacity(0.2),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryDark);
          }
          return const IconThemeData(color: AppColors.mutedForegroundDark);
        }),
      );

  static final NavigationBarThemeData _lightNavigationBarTheme =
      NavigationBarThemeData(
        backgroundColor: AppColors.surface1Light,
        indicatorColor: AppColors.primaryLight.withOpacity(0.2),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryLight);
          }
          return const IconThemeData(color: AppColors.mutedForegroundLight);
        }),
      );

  // ============================================================
  // DIALOG & SHEET THEMES
  // ============================================================

  static const DialogThemeData _darkDialogTheme = DialogThemeData(
    backgroundColor: AppColors.surface2Dark,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: borderRadiusXl),
  );

  static const DialogThemeData _lightDialogTheme = DialogThemeData(
    backgroundColor: AppColors.surface1Light,
    surfaceTintColor: Colors.transparent,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: borderRadiusXl),
  );

  static const BottomSheetThemeData _darkBottomSheetTheme =
      BottomSheetThemeData(
        backgroundColor: AppColors.surface1Dark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radiusXl),
            topRight: Radius.circular(radiusXl),
          ),
        ),
      );

  static const BottomSheetThemeData _lightBottomSheetTheme =
      BottomSheetThemeData(
        backgroundColor: AppColors.surface1Light,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radiusXl),
            topRight: Radius.circular(radiusXl),
          ),
        ),
      );

  // ============================================================
  // CHIP THEMES
  // ============================================================

  static final ChipThemeData _darkChipTheme = ChipThemeData(
    backgroundColor: AppColors.secondaryDark,
    selectedColor: AppColors.primaryDark,
    disabledColor: AppColors.mutedDark,
    labelStyle: AppTextStyles.labelMedium,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: const RoundedRectangleBorder(borderRadius: borderRadiusFull),
    side: BorderSide.none,
  );

  static final ChipThemeData _lightChipTheme = ChipThemeData(
    backgroundColor: AppColors.secondaryLight,
    selectedColor: AppColors.primaryLight,
    disabledColor: AppColors.mutedLight,
    labelStyle: AppTextStyles.labelMedium,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: const RoundedRectangleBorder(borderRadius: borderRadiusFull),
    side: BorderSide.none,
  );

  // ============================================================
  // LIST TILE THEMES
  // ============================================================

  static const ListTileThemeData _darkListTileTheme = ListTileThemeData(
    tileColor: Colors.transparent,
    selectedTileColor: AppColors.surface2Dark,
    iconColor: AppColors.mutedForegroundDark,
    textColor: AppColors.foregroundDark,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: borderRadiusMd),
  );

  static const ListTileThemeData _lightListTileTheme = ListTileThemeData(
    tileColor: Colors.transparent,
    selectedTileColor: AppColors.surface2Light,
    iconColor: AppColors.mutedForegroundLight,
    textColor: AppColors.foregroundLight,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: borderRadiusMd),
  );

  // ============================================================
  // SWITCH, CHECKBOX, RADIO THEMES
  // ============================================================

  static final SwitchThemeData _darkSwitchTheme = SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.white;
      return AppColors.mutedForegroundDark;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.primaryDark;
      return AppColors.surface3Dark;
    }),
  );

  static final SwitchThemeData _lightSwitchTheme = SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.white;
      return AppColors.mutedForegroundLight;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.primaryLight;
      return AppColors.secondaryLight;
    }),
  );

  static final CheckboxThemeData _darkCheckboxTheme = CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.primaryDark;
      return Colors.transparent;
    }),
    checkColor: WidgetStateProperty.all(AppColors.primaryForegroundDark),
    side: const BorderSide(color: AppColors.borderDark, width: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  );

  static final CheckboxThemeData _lightCheckboxTheme = CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.primaryLight;
      return Colors.transparent;
    }),
    checkColor: WidgetStateProperty.all(AppColors.primaryForegroundLight),
    side: const BorderSide(color: AppColors.borderLight, width: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  );

  static final RadioThemeData _darkRadioTheme = RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.primaryDark;
      return AppColors.borderDark;
    }),
  );

  static final RadioThemeData _lightRadioTheme = RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.primaryLight;
      return AppColors.borderLight;
    }),
  );

  // ============================================================
  // PROGRESS & SLIDER THEMES
  // ============================================================

  static const ProgressIndicatorThemeData _darkProgressTheme =
      ProgressIndicatorThemeData(
        color: AppColors.primaryDark,
        linearTrackColor: AppColors.surface3Dark,
        circularTrackColor: AppColors.surface3Dark,
      );

  static const ProgressIndicatorThemeData _lightProgressTheme =
      ProgressIndicatorThemeData(
        color: AppColors.primaryLight,
        linearTrackColor: AppColors.secondaryLight,
        circularTrackColor: AppColors.secondaryLight,
      );

  static final SliderThemeData _darkSliderTheme = SliderThemeData(
    activeTrackColor: AppColors.primaryDark,
    inactiveTrackColor: AppColors.surface3Dark,
    thumbColor: AppColors.primaryDark,
    overlayColor: AppColors.primaryDark.withOpacity(0.2),
  );

  static final SliderThemeData _lightSliderTheme = SliderThemeData(
    activeTrackColor: AppColors.primaryLight,
    inactiveTrackColor: AppColors.secondaryLight,
    thumbColor: AppColors.primaryLight,
    overlayColor: AppColors.primaryLight.withOpacity(0.2),
  );

  // ============================================================
  // TAB BAR THEMES
  // ============================================================

  static const TabBarThemeData _darkTabBarTheme = TabBarThemeData(
    labelColor: AppColors.foregroundDark,
    unselectedLabelColor: AppColors.mutedForegroundDark,
    indicatorColor: AppColors.primaryDark,
    indicatorSize: TabBarIndicatorSize.tab,
    dividerColor: AppColors.borderDark,
  );

  static const TabBarThemeData _lightTabBarTheme = TabBarThemeData(
    labelColor: AppColors.foregroundLight,
    unselectedLabelColor: AppColors.mutedForegroundLight,
    indicatorColor: AppColors.primaryLight,
    indicatorSize: TabBarIndicatorSize.tab,
    dividerColor: AppColors.borderLight,
  );

  // ============================================================
  // SNACKBAR & TOOLTIP THEMES
  // ============================================================

  static const SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: borderRadiusMd),
  );

  static const TooltipThemeData _tooltipTheme = TooltipThemeData(
    decoration: BoxDecoration(
      color: AppColors.gray900,
      borderRadius: borderRadiusSm,
    ),
    textStyle: AppTextStyles.bodySmall,
  );
}

// ============================================================
// THEME EXTENSION FOR CUSTOM COLORS
// ============================================================

/// Extension to access custom app colors via Theme
///
/// Usage:
/// ```dart
/// final appColors = Theme.of(context).extension<AppColorsExtension>()!;
/// appColors.success // Access success color
/// ```
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.success,
    required this.successMuted,
    required this.warning,
    required this.warningMuted,
    required this.info,
    required this.infoMuted,
    required this.chart1,
    required this.chart2,
    required this.chart3,
    required this.chart4,
    required this.chart5,
  });

  /// Dark mode colors
  const AppColorsExtension.dark()
    : success = AppColors.success,
      successMuted = AppColors.successMuted,
      warning = AppColors.warning,
      warningMuted = AppColors.warningMuted,
      info = AppColors.info,
      infoMuted = AppColors.infoMuted,
      chart1 = AppColors.chart1Dark,
      chart2 = AppColors.chart2Dark,
      chart3 = AppColors.chart3Dark,
      chart4 = AppColors.chart4Dark,
      chart5 = AppColors.chart5Dark;

  /// Light mode colors
  const AppColorsExtension.light()
    : success = AppColors.success,
      successMuted = AppColors.successLight,
      warning = AppColors.warning,
      warningMuted = AppColors.warningLight,
      info = AppColors.info,
      infoMuted = AppColors.infoLight,
      chart1 = AppColors.chart1,
      chart2 = AppColors.chart2,
      chart3 = AppColors.chart3,
      chart4 = AppColors.chart4,
      chart5 = AppColors.chart5;

  final Color success;
  final Color successMuted;
  final Color warning;
  final Color warningMuted;
  final Color info;
  final Color infoMuted;
  final Color chart1;
  final Color chart2;
  final Color chart3;
  final Color chart4;
  final Color chart5;

  @override
  AppColorsExtension copyWith({
    Color? success,
    Color? successMuted,
    Color? warning,
    Color? warningMuted,
    Color? info,
    Color? infoMuted,
    Color? chart1,
    Color? chart2,
    Color? chart3,
    Color? chart4,
    Color? chart5,
  }) {
    return AppColorsExtension(
      success: success ?? this.success,
      successMuted: successMuted ?? this.successMuted,
      warning: warning ?? this.warning,
      warningMuted: warningMuted ?? this.warningMuted,
      info: info ?? this.info,
      infoMuted: infoMuted ?? this.infoMuted,
      chart1: chart1 ?? this.chart1,
      chart2: chart2 ?? this.chart2,
      chart3: chart3 ?? this.chart3,
      chart4: chart4 ?? this.chart4,
      chart5: chart5 ?? this.chart5,
    );
  }

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      success: Color.lerp(success, other.success, t)!,
      successMuted: Color.lerp(successMuted, other.successMuted, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningMuted: Color.lerp(warningMuted, other.warningMuted, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoMuted: Color.lerp(infoMuted, other.infoMuted, t)!,
      chart1: Color.lerp(chart1, other.chart1, t)!,
      chart2: Color.lerp(chart2, other.chart2, t)!,
      chart3: Color.lerp(chart3, other.chart3, t)!,
      chart4: Color.lerp(chart4, other.chart4, t)!,
      chart5: Color.lerp(chart5, other.chart5, t)!,
    );
  }
}
