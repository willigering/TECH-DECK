import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_info.dart';
import 'core/theme.dart';
import 'state/deck_controller.dart';
import 'ui/screens/shell.dart';

class TechDeckApp extends StatelessWidget {
  const TechDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DeckController()..load(),
      child: MaterialApp(
        title: AppInfo.name,
        debugShowCheckedModeBanner: false,
        theme: TdTheme.dark(),
        builder: (context, child) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              systemNavigationBarColor: Color(0xFF070605),
              systemNavigationBarIconBrightness: Brightness.light,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const MainShell(),
      ),
    );
  }
}
