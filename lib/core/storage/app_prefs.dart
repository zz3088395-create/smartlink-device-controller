import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive preferences only. Never store tokens here.
class AppPrefs {
  static const String _lastUsernameKey = 'smartlink.last_username';

  Future<String?> readLastUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastUsernameKey);
  }

  Future<void> writeLastUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUsernameKey, username);
  }
}
