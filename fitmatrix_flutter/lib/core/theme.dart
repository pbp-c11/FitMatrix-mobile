import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MatrixColors {
  static const primary = Color(0xFF03B863);
  static const emerald = Color(0xFF0AAE5A);
  static const ink = Color(0xFF072E1C);
  static const text = Color(0xFF144531);
  static const muted = Color(0x99144531);
  static const background = Color(0xFFEEFDF2);
  static const card = Color(0xE6FFFFFF);
  static const highlight = Color(0xFFE6FF05);
  static const mint = Color(0xFFCBFFC7);
  static const border = Color(0x23085A39);
}

ThemeData buildMatrixTheme() {
  final baseText = GoogleFonts.soraTextTheme();
  final displayText = GoogleFonts.spaceGroteskTextTheme();

  final textTheme = baseText.copyWith(
    displayLarge: displayText.displayLarge?.copyWith(color: MatrixColors.ink),
    displayMedium: displayText.displayMedium?.copyWith(color: MatrixColors.ink),
    displaySmall: displayText.displaySmall?.copyWith(color: MatrixColors.ink),
    headlineLarge: displayText.headlineLarge?.copyWith(color: MatrixColors.ink),
    headlineMedium: displayText.headlineMedium?.copyWith(color: MatrixColors.ink),
    headlineSmall: displayText.headlineSmall?.copyWith(color: MatrixColors.ink),
    titleLarge: baseText.titleLarge?.copyWith(color: MatrixColors.ink, fontWeight: FontWeight.w700),
    titleMedium: baseText.titleMedium?.copyWith(color: MatrixColors.text, fontWeight: FontWeight.w600),
    bodyLarge: baseText.bodyLarge?.copyWith(color: MatrixColors.text),
    bodyMedium: baseText.bodyMedium?.copyWith(color: MatrixColors.text),
    bodySmall: baseText.bodySmall?.copyWith(color: MatrixColors.muted),
    labelLarge: baseText.labelLarge?.copyWith(color: MatrixColors.ink, fontWeight: FontWeight.w700),
  );

  final colorScheme = ColorScheme.fromSeed(
    seedColor: MatrixColors.primary,
    primary: MatrixColors.primary,
    secondary: MatrixColors.emerald,
    surface: MatrixColors.card,
  );

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: MatrixColors.background,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: MatrixColors.background.withAlpha(235),
      elevation: 0,
      foregroundColor: MatrixColors.ink,
      centerTitle: false,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: MatrixColors.ink,
      ),
    ),
    cardTheme: const CardThemeData(
      color: MatrixColors.card,
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MatrixColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MatrixColors.emerald, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: const TextStyle(color: MatrixColors.muted),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: MatrixColors.mint.withAlpha(102),
      side: const BorderSide(color: MatrixColors.border),
      labelStyle: const TextStyle(color: MatrixColors.text, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: MatrixColors.primary,
        foregroundColor: MatrixColors.ink,
        textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, letterSpacing: 0.4),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MatrixColors.ink,
        textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
    ),
  );
}

class MatrixGradients {
  static const global = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD9FEDC),
      Color(0xFFF0FDF4),
      Color(0xFFF6FFF4),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEDFDF3),
      Color(0xFFCFFF93),
    ],
  );
}
