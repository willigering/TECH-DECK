import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';

abstract final class TdTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      surface: TdColors.bg,
      primary: TdColors.gold,
      onPrimary: TdColors.bg,
      secondary: TdColors.goldSoft,
      onSecondary: TdColors.bg,
      error: TdColors.danger,
      onSurface: TdColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: TdColors.bg,
      canvasColor: TdColors.bg,
      fontFamily: 'Rajdhani',
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: TdColors.gold,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: TdColors.bg,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 16,
          letterSpacing: 3,
          color: TdColors.gold,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.w700,
          color: TdColors.gold,
          letterSpacing: 4,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.w600,
          color: TdColors.gold,
          letterSpacing: 2,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Orbitron',
          color: TdColors.text,
          letterSpacing: 1.4,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Rajdhani',
          fontWeight: FontWeight.w500,
          color: TdColors.text,
          height: 1.35,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Rajdhani',
          fontWeight: FontWeight.w500,
          color: TdColors.textMuted,
          height: 1.35,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.w600,
          letterSpacing: 2.2,
          color: TdColors.gold,
        ),
      ),
      dividerColor: TdColors.goldLine,
      iconTheme: const IconThemeData(color: TdColors.gold),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: TdColors.bgPanel,
        contentTextStyle: const TextStyle(
          fontFamily: 'Rajdhani',
          color: TdColors.text,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: TdColors.goldLine),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
