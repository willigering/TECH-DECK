import 'package:shared_preferences/shared_preferences.dart';

/// Nur Backend-URL und optionales App-Token. Niemals den KI-API-Schlüssel.
class AiSettings {
  static const defaultUrl = 'http://10.0.2.2:8787';
  static const _urlKey = 'ai_backend_url';
  static const _tokenKey = 'ai_backend_token';

  Future<String> backendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_urlKey)?.trim();
    if (value == null || value.isEmpty) return defaultUrl;
    return value.replaceAll(RegExp(r'/$'), '');
  }

  Future<void> setBackendUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, url.trim().replaceAll(RegExp(r'/$'), ''));
  }

  Future<String> backendToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey)?.trim() ?? '';
  }

  Future<void> setBackendToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token.trim());
  }
}
