import 'package:flutter/material.dart';

import '../state/theme_controller.dart';

class TdPalette {
  const TdPalette({
    required this.bg,
    required this.surface,
    required this.panel,
    required this.accent,
    required this.accentBright,
    required this.accentDim,
    required this.text,
    required this.muted,
    required this.dim,
    required this.isLight,
  });
  final Color bg,
      surface,
      panel,
      accent,
      accentBright,
      accentDim,
      text,
      muted,
      dim;
  final bool isLight;
}

abstract final class TdTheme {
  static TdPalette palette(TdThemeChoice choice) => switch (choice) {
    TdThemeChoice.lightGold => const TdPalette(
      bg: Color(0xFFF7F1E5),
      surface: Color(0xFFFFFAF0),
      panel: Color(0xFFFFFCF5),
      accent: Color(0xFFC58B17),
      accentBright: Color(0xFFE2A82F),
      accentDim: Color(0xFF8A641D),
      text: Color(0xFF17140F),
      muted: Color(0xFF665E50),
      dim: Color(0xFF938A7B),
      isLight: true,
    ),
    TdThemeChoice.cyberBlue => const TdPalette(
      bg: Color(0xFF031421),
      surface: Color(0xFF062033),
      panel: Color(0xFF082A42),
      accent: Color(0xFF17BFFF),
      accentBright: Color(0xFF66D7FF),
      accentDim: Color(0xFF0878A6),
      text: Color(0xFFF2FBFF),
      muted: Color(0xFFA9C8D8),
      dim: Color(0xFF66889A),
      isLight: false,
    ),
    _ => const TdPalette(
      bg: Color(0xFF17191C),
      surface: Color(0xFF212428),
      panel: Color(0xFF25282C),
      accent: Color(0xFFB9A477),
      accentBright: Color(0xFFD4C198),
      accentDim: Color(0xFF8F7C55),
      text: Color(0xFFF7F4EA),
      muted: Color(0xFFC8C2B4),
      dim: Color(0xFF7A7568),
      isLight: false,
    ),
  };

  static ThemeData forChoice(TdThemeChoice choice) {
    final p = palette(choice);
    final brightness = p.isLight ? Brightness.light : Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: p.accent,
          brightness: brightness,
        ).copyWith(
          surface: p.surface,
          primary: p.accent,
          onPrimary: p.bg,
          onSurface: p.text,
          secondary: p.accentBright,
        );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: p.accent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          letterSpacing: .3,
          color: p.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontFamily: 'Roboto',
          color: p.text,
          letterSpacing: .2,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
          color: p.text,
          height: 1.35,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
          color: p.muted,
          height: 1.35,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w600,
          letterSpacing: .4,
          color: p.accent,
        ),
      ),
      iconTheme: IconThemeData(color: p.accent),
      dividerColor: p.accent.withValues(alpha: .18),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.panel,
        contentTextStyle: TextStyle(
          color: p.text,
          fontFamily: 'Roboto',
          fontSize: 16,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
