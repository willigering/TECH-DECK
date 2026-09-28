import 'package:flutter/material.dart';

import '../state/theme_controller.dart';

class TdPalette {
  const TdPalette({
    required this.bg, required this.surface, required this.panel,
    required this.accent, required this.accentBright, required this.accentDim,
    required this.text, required this.muted, required this.dim,
    required this.isLight,
  });
  final Color bg, surface, panel, accent, accentBright, accentDim, text, muted, dim;
  final bool isLight;
}

abstract final class TdTheme {
  static TdPalette palette(TdThemeChoice choice) => switch (choice) {
    TdThemeChoice.lightGold => const TdPalette(
      bg: Color(0xFFF7F1E5), surface: Color(0xFFFFFAF0), panel: Color(0xFFFFFCF5),
      accent: Color(0xFFC58B17), accentBright: Color(0xFFE2A82F), accentDim: Color(0xFF8A641D),
      text: Color(0xFF17140F), muted: Color(0xFF665E50), dim: Color(0xFF938A7B), isLight: true),
    TdThemeChoice.oledBlack => const TdPalette(
      bg: Color(0xFF000000), surface: Color(0xFF030303), panel: Color(0xFF050505),
      accent: Color(0xFF00BFFF), accentBright: Color(0xFF6DDBFF), accentDim: Color(0xFF006D91),
      text: Color(0xFFFFFFFF), muted: Color(0xFFB8C1C7), dim: Color(0xFF667078), isLight: false),
    TdThemeChoice.cyberBlue => const TdPalette(
      bg: Color(0xFF031421), surface: Color(0xFF062033), panel: Color(0xFF082A42),
      accent: Color(0xFF17BFFF), accentBright: Color(0xFF66D7FF), accentDim: Color(0xFF0878A6),
      text: Color(0xFFF2FBFF), muted: Color(0xFFA9C8D8), dim: Color(0xFF66889A), isLight: false),
    TdThemeChoice.terminalGreen => const TdPalette(
      bg: Color(0xFF00130C), surface: Color(0xFF001B11), panel: Color(0xFF03251A),
      accent: Color(0xFF21F39A), accentBright: Color(0xFF70FFC0), accentDim: Color(0xFF0A8A57),
      text: Color(0xFFE9FFF5), muted: Color(0xFFA1D8BE), dim: Color(0xFF548A70), isLight: false),
    _ => const TdPalette(
      bg: Color(0xFF050505), surface: Color(0xFF0A0A0A), panel: Color(0xFF0C0C0C),
      accent: Color(0xFFFFD700), accentBright: Color(0xFFFFE566), accentDim: Color(0xFFB8860B),
      text: Color(0xFFF7F4EA), muted: Color(0xFFC8C2B4), dim: Color(0xFF7A7568), isLight: false),
  };

  static ThemeData forChoice(TdThemeChoice choice) {
    final p = palette(choice);
    final brightness = p.isLight ? Brightness.light : Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: p.accent, brightness: brightness).copyWith(
      surface: p.surface, primary: p.accent, onPrimary: p.bg, onSurface: p.text,
      secondary: p.accentBright,
    );
    return ThemeData(
      useMaterial3: true, brightness: brightness, colorScheme: scheme,
      scaffoldBackgroundColor: p.bg, canvasColor: p.bg, fontFamily: 'Rajdhani',
      appBarTheme: AppBarTheme(backgroundColor: Colors.transparent, foregroundColor: p.accent, elevation: 0,
        centerTitle: true, titleTextStyle: TextStyle(fontFamily:'Orbitron',fontSize:16,letterSpacing:3,color:p.accent,fontWeight:FontWeight.w600)),
      textTheme: TextTheme(
        titleLarge: TextStyle(fontFamily:'Orbitron',color:p.text,letterSpacing:1.4),
        bodyLarge: TextStyle(fontFamily:'Rajdhani',fontWeight:FontWeight.w500,color:p.text,height:1.35),
        bodyMedium: TextStyle(fontFamily:'Rajdhani',fontWeight:FontWeight.w500,color:p.muted,height:1.35),
        labelLarge: TextStyle(fontFamily:'Orbitron',fontWeight:FontWeight.w600,letterSpacing:2.2,color:p.accent),
      ),
      iconTheme: IconThemeData(color:p.accent), dividerColor:p.accent.withValues(alpha:.55),
      snackBarTheme: SnackBarThemeData(backgroundColor:p.panel,contentTextStyle:TextStyle(color:p.text,fontFamily:'Rajdhani',fontSize:16),behavior:SnackBarBehavior.floating),
    );
  }
}

extension TdThemeContext on BuildContext {
  TdPalette get td => TdTheme.palette(read<TdThemeChoice>());
}
