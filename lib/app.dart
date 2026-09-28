import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_info.dart';
import 'core/theme.dart';
import 'state/deck_controller.dart';
import 'state/theme_controller.dart';
import 'ui/screens/shell.dart';

class TechDeckApp extends StatelessWidget {
  const TechDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeckController()..load()),
        ChangeNotifierProvider(create: (_) => ThemeController()..load()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themes, _) {
          final palette = TdTheme.palette(themes.choice);
          final brightness = palette.isLight ? Brightness.dark : Brightness.light;
          return MaterialApp(
            title: AppInfo.name,
            debugShowCheckedModeBanner: false,
            theme: TdTheme.forChoice(themes.choice),
            builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: brightness,
                systemNavigationBarColor: palette.bg,
                systemNavigationBarIconBrightness: brightness,
              ),
              child: child ?? const SizedBox.shrink(),
            ),
            home: const MainShell(),
          );
        },
      ),
    );
  }
}
