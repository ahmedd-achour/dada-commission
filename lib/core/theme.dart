import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Samsung-inspired palette (deep "Samsung blue" + fresh green, as on the
/// boot/loading screen) on top of the Shnell layout language: Inter body
/// text, Outfit/Poppins titles, 16 px rounded surfaces.
class AppTheme {
  AppTheme._();

  /// Turned off in widget tests (no network to fetch fonts).
  static bool useGoogleFonts = true;

  /// Samsung brand blue.
  static const Color blue = Color(0xFF1428A0);

  /// Brighter blue used in the middle of the brand gradient.
  static const Color blueBright = Color(0xFF2F6BFF);

  /// Fresh green of the loading-screen gradient.
  static const Color green = Color(0xFF14B88A);

  /// Blue -> green brand gradient (headers, wallet card, splash).
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue, blueBright, green],
  );

  static const Color navUnselected = Color(0xFF9AA0AE);
  static const Color success = Color(0xFF2E7D32);
  static const Color danger = Color(0xFFC62828);
  static const Color warning = Color(0xFFEF8F00);

  static const Color facebook = Color(0xFF1877F2);
  static const Color whatsapp = Color(0xFF25D366);

  static const double radius = 16;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: brightness,
      primary: dark ? const Color(0xFF9DB1FF) : blue,
      onPrimary: dark ? const Color(0xFF0A1550) : Colors.white,
      secondary: green,
      onSecondary: Colors.white,
    );
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: useGoogleFonts ? GoogleFonts.inter().fontFamily : null,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: rounded,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: rounded,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: rounded,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: navUnselected,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: rounded,
      ),
    );
  }

  /// Brand / big titles (Outfit, like the "Shnell." wordmark).
  static TextStyle display({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.bold,
    Color? color,
  }) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
    return useGoogleFonts ? GoogleFonts.outfit(textStyle: base) : base;
  }

  /// Secondary copy (Poppins in the Shnell auth screens).
  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
    return useGoogleFonts ? GoogleFonts.poppins(textStyle: base) : base;
  }
}
