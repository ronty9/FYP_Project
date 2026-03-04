import 'package:shared_preferences/shared_preferences.dart';

/// Persists and provides the AI backend server URL.
///
/// Default auto-detects the environment:
///   • iOS simulator  → http://127.0.0.1:8000
///   • Android emulator → http://10.0.2.2:8000
///   • Physical device  → must be set once via [setUrl]
///
/// Override at any time by calling [setUrl]; the value survives app restarts.
class ServerConfig {
  ServerConfig._();

  static const _kPrefsKey = 'ai_server_url';

  // Sensible defaults depending on platform.
  static const String _defaultIos = 'http://127.0.0.1:8000';
  static const String _defaultAndroid = 'http://10.0.2.2:8000';

  // Ensure production builds use an HTTPS URL. Replace with real Cloud Run URL later.
  static const String _defaultProduction =
      'https://PLACEHOLDER-FOR-YOUR-CLOUD-RUN-URL.run.app';

  static String get defaultUrl {
    const isProduction = bool.fromEnvironment('dart.vm.product');
    if (isProduction) {
      return _defaultProduction;
    }

    // ignore: do_not_use_environment
    const isAndroid =
        bool.fromEnvironment('dart.library.io') &&
        identical(0, 0.0); // placeholder; always use iOS default
    return isAndroid ? _defaultAndroid : _defaultIos;
  }

  /// Returns the saved URL, or the platform default if nothing has been saved.
  static Future<String> getUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPrefsKey) ?? _defaultIos;
  }

  /// Persist a new server URL (e.g. an ngrok HTTPS URL or local IP).
  static Future<void> setUrl(String url) async {
    // Strip trailing slash for consistency.
    final clean = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, clean);
  }

  /// Remove saved URL and revert to the platform default.
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrefsKey);
  }
}
