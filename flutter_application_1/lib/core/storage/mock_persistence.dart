import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class MockPersistence {
  static final _baseUrl = '${ApiConfig.storageUrl}';

  static Future<String?> _load(String key) async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/$key'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['value'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _save(String key, String value) async {
    try {
      await http
          .post(
            Uri.parse('$_baseUrl/$key'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'value': value}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> loadList(
    String key,
    List<Map<String, dynamic>> seed,
  ) async {
    final raw = await _load(key);
    if (raw == null || raw.isEmpty) {
      return seed.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return seed.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
        .toList();
  }

  static Future<void> saveList(
    String key,
    List<Map<String, dynamic>> value,
  ) async {
    await _save(key, jsonEncode(value));
  }

  static Future<Map<String, dynamic>> loadObject(
    String key,
    Map<String, dynamic> seed,
  ) async {
    final raw = await _load(key);
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
    await _save(key, jsonEncode(value));
  }
}
