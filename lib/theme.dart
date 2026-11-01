import 'package:flutter/material.dart';

const kInk = Color(0xFF14232B);
const kTeal = Color(0xFF0F5C63);
const kSaffron = Color(0xFFE9A23B);
const kPaper = Color(0xFFF5F8F7);
const kError = Color(0xFFB3261E);

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
    textTheme: base.textTheme.apply(
      fontSizeFactor: 1.1,
      bodyColor: kInk,
      displayColor: kInk,
    ),
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
