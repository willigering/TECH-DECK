import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The checked default makes the welcome screen a first-launch introduction.
class WelcomeController extends ChangeNotifier {
  static const preferenceKey = 'welcome_do_not_show_again';
  bool loading = true;
  bool visible = false;
  bool doNotShowAgain = true;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(preferenceKey);
      doNotShowAgain = saved ?? true;
      visible = saved != true;
    } catch (_) {
      visible = true;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void show() {
    visible = true;
    notifyListeners();
  }

  Future<void> dismiss({required bool doNotShowAgain}) async {
    this.doNotShowAgain = doNotShowAgain;
    visible = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool(preferenceKey, doNotShowAgain)) {
      throw StateError('Welcome preference could not be saved');
    }
  }
}
