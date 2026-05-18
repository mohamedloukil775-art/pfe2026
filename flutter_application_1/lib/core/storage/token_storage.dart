import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _userRoleKey = 'user_role';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> saveUserInfo({
    required int userId,
    required String userName,
    required String userRole,
  }) async {
    await _storage.write(key: _userIdKey, value: userId.toString());
    await _storage.write(key: _userNameKey, value: userName);
    await _storage.write(key: _userRoleKey, value: userRole);
  }

  static Future<Map<String, String?>> getUserInfo() async {
    return {
      'userId': await _storage.read(key: _userIdKey),
      'userName': await _storage.read(key: _userNameKey),
      'userRole': await _storage.read(key: _userRoleKey),
    };
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
