import 'package:flutter/material.dart';

const kInk = Color(0xFF14232B);
const kTeal = Color(0xFF0F5C63);
const kSaffron = Color(0xFFE9A23B);
const kPaper = Color(0xFFF5F8F7);
const kError = Color(0xFFB3261E);

TextStyle? _scaleTextStyle(TextStyle? style) {
  final size = style?.fontSize;
  if (style == null || size == null) return style;
  return style.copyWith(fontSize: size * 1.1);
}

TextTheme _buildReadableTextTheme(TextTheme source) {
  // Apply colors without a font-size factor first. Some Material 3 text
  // styles intentionally have a null fontSize, which makes apply(1.1)
  // assert on newer Flutter versions.
  final colored = source.apply(
    bodyColor: kInk,
    displayColor: kInk,
  );
  return colored.copyWith(
    displayLarge: _scaleTextStyle(colored.displayLarge),
    displayMedium: _scaleTextStyle(colored.displayMedium),
    displaySmall: _scaleTextStyle(colored.displaySmall),
    headlineLarge: _scaleTextStyle(colored.headlineLarge),
    headlineMedium: _scaleTextStyle(colored.headlineMedium),
    headlineSmall: _scaleTextStyle(colored.headlineSmall),
    titleLarge: _scaleTextStyle(colored.titleLarge),
    titleMedium: _scaleTextStyle(colored.titleMedium),
    titleSmall: _scaleTextStyle(colored.titleSmall),
    bodyLarge: _scaleTextStyle(colored.bodyLarge),
    bodyMedium: _scaleTextStyle(colored.bodyMedium),
    bodySmall: _scaleTextStyle(colored.bodySmall),
    labelLarge: _scaleTextStyle(colored.labelLarge),
    labelMedium: _scaleTextStyle(colored.labelMedium),
    labelSmall: _scaleTextStyle(colored.labelSmall),
  );
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kTeal,
    primary: kTeal,
    secondary: kSaffron,
    surface: kPaper,
    error: kError,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: kPaper,
    textTheme: _buildReadableTextTheme(base.textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: kPaper,
      foregroundColor: kInk,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 18),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
