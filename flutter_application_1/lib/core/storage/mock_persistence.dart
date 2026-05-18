import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MockPersistence {
  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<List<Map<String, dynamic>>> loadList(
    String key,
    List<Map<String, dynamic>> seed,
  ) async {
    final prefs = await _prefs();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return seed.map((entry) => Map<String, dynamic>.from(entry)).toList();
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return seed.map((entry) => Map<String, dynamic>.from(entry)).toList();
    }

    return decoded
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry.cast<String, dynamic>()))
        .toList();
  }

  static Future<void> saveList(
    String key,
    List<Map<String, dynamic>> value,
  ) async {
    final prefs = await _prefs();
    await prefs.setString(key, jsonEncode(value));
  }

  static Future<Map<String, dynamic>> loadObject(
    String key,
    Map<String, dynamic> seed,
  ) async {
    final prefs = await _prefs();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return Map<String, dynamic>.from(seed);
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return Map<String, dynamic>.from(seed);
    }

    return Map<String, dynamic>.from(decoded.cast<String, dynamic>());
  }

  static Future<void> saveObject(
    String key,
    Map<String, dynamic> value,
  ) async {
    final prefs = await _prefs();
    await prefs.setString(key, jsonEncode(value));
  }
}
