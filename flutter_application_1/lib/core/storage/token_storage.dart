import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _secureStorage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _userRoleKey = 'user_role';

  static Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  static Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      return await _secureStorage.read(key: key);
    }
  }

  static Future<void> _delete(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      await _secureStorage.delete(key: key);
    }
  }

  static Future<void> saveToken(String token) async {
    await _write(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    return await _read(_tokenKey);
  }

  static Future<void> saveUserInfo({
    required int userId,
    required String userName,
    required String userRole,
  }) async {
    await _write(_userIdKey, userId.toString());
    await _write(_userNameKey, userName);
    await _write(_userRoleKey, userRole);
  }

  static Future<Map<String, String?>> getUserInfo() async {
    return {
      'userId': await _read(_userIdKey),
      'userName': await _read(_userNameKey),
      'userRole': await _read(_userRoleKey),
    };
  }

  static Future<void> clearAll() async {
    await _delete(_tokenKey);
    await _delete(_userIdKey);
    await _delete(_userNameKey);
    await _delete(_userRoleKey);
  }
}
