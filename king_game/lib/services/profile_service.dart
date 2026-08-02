import 'package:shared_preferences/shared_preferences.dart';

/// Minimal on-device "registration": a persisted display name, checked once
/// at app start. Swappable later for real Firebase Auth without touching
/// any screen beyond [RegistrationScreen] and this service's implementation.
class ProfileService {
  static const _usernameKey = 'king_game.username';

  Future<String?> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }
}
