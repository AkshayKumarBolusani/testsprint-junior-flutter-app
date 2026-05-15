import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Reliable session persistence — SharedPreferences survives force-quit on Android.
class AuthSessionStorage {
  AuthSessionStorage(this._prefs);

  final SharedPreferences _prefs;
  static const _kToken = 'auth_jwt_token';
  static const _kUserJson = 'auth_user_json';

  String? _memoryToken;

  String? get cachedToken {
    final mem = _memoryToken;
    if (mem != null && mem.isNotEmpty) return mem;
    return _prefs.getString(_kToken);
  }

  String? get cachedUserJson => _prefs.getString(_kUserJson);

  Future<String?> readToken() async {
    final mem = _memoryToken;
    if (mem != null && mem.isNotEmpty) return mem;
    final disk = _prefs.getString(_kToken);
    if (disk != null && disk.isNotEmpty) {
      _memoryToken = disk;
    }
    return disk;
  }

  Future<void> saveSession({
    required String token,
    required Map<String, dynamic> userJson,
  }) async {
    _memoryToken = token;
    await _prefs.setString(_kToken, token);
    await _prefs.setString(_kUserJson, jsonEncode(userJson));
  }

  Future<void> clearSession() async {
    _memoryToken = null;
    await _prefs.remove(_kToken);
    await _prefs.remove(_kUserJson);
  }
}
