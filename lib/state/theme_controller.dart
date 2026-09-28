import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TdThemeChoice { darkGold, lightGold, oledBlack, cyberBlue, terminalGreen }

class ThemeController extends ChangeNotifier {
  static const _key = 'theme_choice';
  TdThemeChoice _choice = TdThemeChoice.darkGold;
  TdThemeChoice get choice => _choice;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    _choice = TdThemeChoice.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => TdThemeChoice.darkGold,
    );
    notifyListeners();
  }

  Future<void> setTheme(TdThemeChoice value) async {
    _choice = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value.name);
  }
}
