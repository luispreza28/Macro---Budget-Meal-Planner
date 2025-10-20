import 'package:flutter/material.dart';

ThemeData buildHighContrastLight() {
  // Ensure >=4.5:1 text contrast. Use near-black on white, strong accents.
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF005BBB),
    brightness: Brightness.light,
  ).copyWith(
    primary: const Color(0xFF003A8C),
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
    secondary: const Color(0xFF006C3C),
    onSecondary: Colors.white,
    outline: const Color(0xFF1F1F1F),
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    textTheme: _largerBaseText(ThemeData.light().textTheme),
    focusColor: const Color(0xFF000000),
    highlightColor: const Color(0x33000000),
    splashFactory: InkSparkle.splashFactory,
  );
}

TextTheme _largerBaseText(TextTheme base) {
  // Minimums: body >= 16sp, titles >= 20sp
  return base.copyWith(
    bodyMedium: base.bodyMedium?.copyWith(fontSize: 16),
    bodyLarge: base.bodyLarge?.copyWith(fontSize: 18),
    titleMedium: base.titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
    titleLarge: base.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
    labelLarge: base.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
  );
}

