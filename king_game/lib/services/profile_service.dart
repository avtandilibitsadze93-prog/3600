import 'package:shared_preferences/shared_preferences.dart';

import '../models/avatar.dart';

/// Minimal on-device "registration": a persisted display name and chosen
/// avatar, checked once at app start. Swappable later for real Firebase
/// Auth without touching any screen beyond [RegistrationScreen] and this
/// service's implementation.
class ProfileService {
  static const _usernameKey = 'king_game.username';
  static const _avatarKey = 'king_game.avatarId';

  Future<String?> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  Future<String> loadAvatarId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarKey) ?? kDefaultAvatar.id;
  }

  Future<void> saveAvatarId(String avatarId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarKey, avatarId);
  }
}
