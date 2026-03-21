import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// =============================================================================
/// COLOR PALETTE DEFINITIONS
/// =============================================================================

enum ColorPalette {
  sunset, // Orange/Yellow - Warm & Energetic
  ocean, // Blue/Teal - Calm & Professional
  forest, // Green/Emerald - Natural & Fresh
  lavender, // Purple/Violet - Creative & Premium
  rose, // Pink/Rose - Soft & Elegant
  midnight, // Dark Blue/Navy - Sleek & Modern
}

/// Color palette data class
class PaletteColors {
  final String name;
  final String emoji;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondary;
  final Color secondaryLight;
  final Color secondaryDark;
  final Color accent;

  const PaletteColors({
    required this.name,
    required this.emoji,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.secondaryLight,
    required this.secondaryDark,
    required this.accent,
  });
}

/// =============================================================================
/// APP THEME - Multi-Palette Design System
/// =============================================================================

class AppTheme {
  AppTheme._();

  // ===========================================================================
  // COLOR PALETTES
  // ===========================================================================

  static const Map<ColorPalette, PaletteColors> palettes = {
    // Sunset - Orange/Yellow (Default)
    ColorPalette.sunset: PaletteColors(
      name: 'Sunset',
      emoji: '🌅',
      primary: Color(0xFFF97316), // Vibrant Orange
      primaryLight: Color(0xFFFB923C), // Light Orange
      primaryDark: Color(0xFFEA580C), // Deep Orange
      secondary: Color(0xFFFBBF24), // Golden Yellow
      secondaryLight: Color(0xFFFCD34D), // Light Yellow
      secondaryDark: Color(0xFFF59E0B), // Amber
      accent: Color(0xFFFF6B35), // Coral Orange
    ),

    // Ocean - Blue/Teal
    ColorPalette.ocean: PaletteColors(
      name: 'Ocean',
      emoji: '🌊',
      primary: Color(0xFF0EA5E9), // Sky Blue
      primaryLight: Color(0xFF38BDF8), // Light Blue
      primaryDark: Color(0xFF0284C7), // Deep Blue
      secondary: Color(0xFF14B8A6), // Teal
      secondaryLight: Color(0xFF2DD4BF), // Light Teal
      secondaryDark: Color(0xFF0D9488), // Deep Teal
      accent: Color(0xFF06B6D4), // Cyan
    ),

    // Forest - Green/Emerald
    ColorPalette.forest: PaletteColors(
      name: 'Forest',
      emoji: '🌲',
      primary: Color(0xFF22C55E), // Green
      primaryLight: Color(0xFF4ADE80), // Light Green
      primaryDark: Color(0xFF16A34A), // Deep Green
      secondary: Color(0xFF10B981), // Emerald
      secondaryLight: Color(0xFF34D399), // Light Emerald
      secondaryDark: Color(0xFF059669), // Deep Emerald
      accent: Color(0xFF84CC16), // Lime
    ),

    // Lavender - Purple/Violet
    ColorPalette.lavender: PaletteColors(
      name: 'Lavender',
      emoji: '💜',
      primary: Color(0xFF8B5CF6), // Violet
      primaryLight: Color(0xFFA78BFA), // Light Violet
      primaryDark: Color(0xFF7C3AED), // Deep Violet
      secondary: Color(0xFFEC4899), // Pink
      secondaryLight: Color(0xFFF472B6), // Light Pink
      secondaryDark: Color(0xFFDB2777), // Deep Pink
      accent: Color(0xFFA855F7), // Purple
    ),

    // Rose - Pink/Rose
    ColorPalette.rose: PaletteColors(
      name: 'Rose',
      emoji: '🌸',
      primary: Color(0xFFF43F5E), // Rose
      primaryLight: Color(0xFFFB7185), // Light Rose
      primaryDark: Color(0xFFE11D48), // Deep Rose
      secondary: Color(0xFFEC4899), // Pink
      secondaryLight: Color(0xFFF472B6), // Light Pink
      secondaryDark: Color(0xFFDB2777), // Deep Pink
      accent: Color(0xFFFF6B9D), // Coral Pink
    ),

    // Midnight - Dark Blue/Navy
    ColorPalette.midnight: PaletteColors(
      name: 'Midnight',
      emoji: '🌙',
      primary: Color(0xFF6366F1), // Indigo
      primaryLight: Color(0xFF818CF8), // Light Indigo
      primaryDark: Color(0xFF4F46E5), // Deep Indigo
      secondary: Color(0xFF3B82F6), // Blue
      secondaryLight: Color(0xFF60A5FA), // Light Blue
      secondaryDark: Color(0xFF2563EB), // Deep Blue
      accent: Color(0xFF8B5CF6), // Violet
    ),
  };

  // Current palette - this gets updated by the theme provider
  static ColorPalette _currentPalette = ColorPalette.ocean;

  static ColorPalette get currentPalette => _currentPalette;

  static void setPalette(ColorPalette palette) {
    _currentPalette = palette;
  }

  static PaletteColors get colors => palettes[_currentPalette]!;

  // ===========================================================================
  // DYNAMIC COLOR GETTERS (based on current palette)
  // ===========================================================================

  static Color get primaryColor => colors.primary;
  static Color get primaryLight => colors.primaryLight;
  static Color get primaryDark => colors.primaryDark;
  static Color get secondaryColor => colors.secondary;
  static Color get secondaryLight => colors.secondaryLight;
  static Color get secondaryDark => colors.secondaryDark;
  static Color get accentColor => colors.accent;

  // ===========================================================================
  // SEMANTIC COLORS (constant across palettes)
  // ===========================================================================

  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFFBBF24);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

  // ===========================================================================
  // LIGHT THEME COLORS
  // ===========================================================================

  static const Color lightBackground = Color(0xFFFFFBF5);
  static const Color lightSurface = Color(0xFFFFFDF9);
  static const Color lightCard = Color(0xFFFFFDF9);
  static const Color lightDivider = Color(0xFFD1D5DB);
  static const Color lightTextPrimary = Color(0xFF451A03);
  static const Color lightTextSecondary = Color(0xFF92400E);
  static const Color lightTextHint = Color(0xFFC2762E);

  // ===========================================================================
  // DARK THEME COLORS
  // ===========================================================================

  static const Color darkBackground = Color(0xFF1C1410);
  static const Color darkSurface = Color(0xFF2C211A);
  static const Color darkCard = Color(0xFF2C211A);
  static const Color darkDivider = Color(0xFF4B5563);
  static const Color darkTextPrimary = Color(0xFFFFF7ED);
  static const Color darkTextSecondary = Color(0xFFFED7AA);
  static const Color darkTextHint = Color(0xFFC2762E);

  // ===========================================================================
  // DESIGN TOKENS
  // ===========================================================================

  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 100.0;

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ===========================================================================
  // SHADOWS
  // ===========================================================================

  static List<BoxShadow> shadowSm(bool isDark) => [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> shadowMd(bool isDark) => [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> shadowLg(bool isDark) => [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  // ===========================================================================
  // TYPOGRAPHY
  // ===========================================================================

  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.1,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0.4,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.5,
      ),
    );
  }

  // ===========================================================================
  // THEME BUILDERS
  // ===========================================================================

  static ThemeData buildLightTheme(ColorPalette palette) {
    final paletteColors = palettes[palette]!;

    final colorScheme = ColorScheme.light(
      primary: paletteColors.primary,
      primaryContainer: paletteColors.primaryLight.withOpacity(0.2),
      secondary: paletteColors.secondary,
      secondaryContainer: paletteColors.secondaryLight.withOpacity(0.2),
      tertiary: paletteColors.accent,
      surface: lightSurface,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightTextPrimary,
      onError: Colors.white,
      outline: lightDivider,
      shadow: Colors.black.withOpacity(0.1),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBackground,
      textTheme: _buildTextTheme(lightTextPrimary),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: lightBackground,
        surfaceTintColor: Colors.transparent,
        foregroundColor: lightTextPrimary,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        iconTheme: const IconThemeData(color: lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: lightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: lightDivider.withOpacity(0.5)),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: paletteColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: lightDivider,
          disabledForegroundColor: lightTextHint,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: paletteColors.primary,
          side: BorderSide(color: paletteColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: paletteColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        backgroundColor: paletteColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: lightDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: paletteColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(
          color: lightTextSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.poppins(
          color: lightTextHint,
          fontSize: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurface,
        selectedColor: paletteColors.primaryLight.withOpacity(0.2),
        disabledColor: lightDivider,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
          side: const BorderSide(color: lightDivider),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        elevation: 8,
        selectedItemColor: paletteColors.primary,
        unselectedItemColor: lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        elevation: 0,
        indicatorColor: paletteColors.primaryLight.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: paletteColors.primary,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: lightTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: paletteColors.primary, size: 24);
          }
          return const IconThemeData(color: lightTextSecondary, size: 24);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: lightDivider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightTextPrimary,
        contentTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
        dragHandleColor: lightDivider,
        dragHandleSize: Size(40, 4),
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: lightTextSecondary,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
        ),
        subtitleTextStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: lightTextSecondary,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected))
            return paletteColors.primary;
          return lightTextHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return paletteColors.primary.withOpacity(0.4);
          }
          return lightDivider;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: paletteColors.primary,
        linearTrackColor: lightDivider,
        circularTrackColor: lightDivider,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: paletteColors.primary,
        inactiveTrackColor: lightDivider,
        thumbColor: paletteColors.primary,
        overlayColor: paletteColors.primary.withOpacity(0.12),
        valueIndicatorColor: paletteColors.primary,
        valueIndicatorTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: paletteColors.primary,
        unselectedLabelColor: lightTextSecondary,
        indicatorColor: paletteColors.primary,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicatorSize: TabBarIndicatorSize.label,
      ),
    );
  }

  static ThemeData buildDarkTheme(ColorPalette palette) {
    final paletteColors = palettes[palette]!;

    final colorScheme = ColorScheme.dark(
      primary: paletteColors.primaryLight,
      primaryContainer: paletteColors.primaryDark.withOpacity(0.3),
      secondary: paletteColors.secondaryLight,
      secondaryContainer: paletteColors.secondaryDark.withOpacity(0.3),
      tertiary: paletteColors.accent,
      surface: darkSurface,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkTextPrimary,
      onError: Colors.white,
      outline: darkDivider,
      shadow: Colors.black.withOpacity(0.3),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      textTheme: _buildTextTheme(darkTextPrimary),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: darkBackground,
        surfaceTintColor: Colors.transparent,
        foregroundColor: darkTextPrimary,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        iconTheme: const IconThemeData(color: darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: darkDivider.withOpacity(0.5)),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: paletteColors.primaryLight,
          foregroundColor: Colors.white,
          disabledBackgroundColor: darkDivider,
          disabledForegroundColor: darkTextHint,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: paletteColors.primaryLight,
          side: BorderSide(color: paletteColors.primaryLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: paletteColors.primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        backgroundColor: paletteColors.primaryLight,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: paletteColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(
          color: darkTextSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.poppins(
          color: darkTextHint,
          fontSize: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        selectedColor: paletteColors.primaryDark.withOpacity(0.3),
        disabledColor: darkDivider,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
          side: const BorderSide(color: darkDivider),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        elevation: 8,
        selectedItemColor: paletteColors.primaryLight,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        elevation: 0,
        indicatorColor: paletteColors.primaryDark.withOpacity(0.3),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: paletteColors.primaryLight,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: darkTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: paletteColors.primaryLight, size: 24);
          }
          return const IconThemeData(color: darkTextSecondary, size: 24);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCard,
        contentTextStyle: GoogleFonts.poppins(
          color: darkTextPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
        dragHandleColor: darkDivider,
        dragHandleSize: Size(40, 4),
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: darkTextSecondary,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        subtitleTextStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: darkTextSecondary,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected))
            return paletteColors.primaryLight;
          return darkTextHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return paletteColors.primaryLight.withOpacity(0.4);
          }
          return darkDivider;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: paletteColors.primaryLight,
        linearTrackColor: darkDivider,
        circularTrackColor: darkDivider,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: paletteColors.primaryLight,
        inactiveTrackColor: darkDivider,
        thumbColor: paletteColors.primaryLight,
        overlayColor: paletteColors.primaryLight.withOpacity(0.12),
        valueIndicatorColor: paletteColors.primaryLight,
        valueIndicatorTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: paletteColors.primaryLight,
        unselectedLabelColor: darkTextSecondary,
        indicatorColor: paletteColors.primaryLight,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicatorSize: TabBarIndicatorSize.label,
      ),
    );
  }

  // Legacy getters for backward compatibility
  static ThemeData get lightTheme => buildLightTheme(_currentPalette);
  static ThemeData get darkTheme => buildDarkTheme(_currentPalette);
}

// Extension for easy color access
extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
