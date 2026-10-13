import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/ambassador_tier.dart';

/// Same visual language as the Shnell client: amber seed, Inter body text,
/// Outfit/Poppins for titles, 16 px rounded surfaces, gold bottom-nav accent.
class AppTheme {
  AppTheme._();

  /// Turned off in widget tests (no network to fetch fonts).
  static bool useGoogleFonts = true;

  static const Color gold = Color.fromARGB(255, 187, 152, 48);
  static const Color navUnselected = Color.fromARGB(255, 160, 160, 158);
  static const Color success = Color(0xFF2E7D32);
  static const Color danger = Color(0xFFC62828);
  static const Color warning = Color(0xFFEF8F00);

  static const Color facebook = Color(0xFF1877F2);
  static const Color whatsapp = Color(0xFF25D366);

  static const double radius = 16;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.amber,
      brightness: brightness,
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
        selectedItemColor: gold,
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

  static Color tierColor(AmbassadorTier tier) => switch (tier) {
    AmbassadorTier.bronze => const Color(0xFFB0703A),
    AmbassadorTier.silver => const Color(0xFF8A8D91),
    AmbassadorTier.gold => gold,
    AmbassadorTier.diamond => const Color(0xFF3A9BD9),
  };
}
