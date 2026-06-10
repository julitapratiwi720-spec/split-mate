import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const _keyUserId = 'user_id';
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyUserEmail = 'user_email';
  static const _keyUserName = 'user_name';

  // Simpan sesi login
  Future<void> saveUserSession({
    required String uid,
    required String email,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, uid);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserName, name ?? '');
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  // Cek apakah sudah login
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Ambil user id
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  // Ambil email
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  // Ambil nama
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  // Hapus sesi (logout)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}


