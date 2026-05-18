import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/domain.dart';
import '../../core/config/api_config.dart';
import '../../core/storage/token_storage.dart';
import '../../core/exceptions/api_exceptions.dart';

class AuthService {
  Future<Map<String, String>> _getHeaders({bool includeAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await TokenStorage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<AppUser> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Sauvegarder le token
        await TokenStorage.saveToken(data['token'] as String);

        // Sauvegarder les infos utilisateur
        // Backend returns user fields at root level. Keep fallback for legacy payloads.
        final userData = (data['utilisateur'] as Map<String, dynamic>?) ??
            (data as Map<String, dynamic>);
        await TokenStorage.saveUserInfo(
          userId: userData['id'] as int,
          userName: userData['nom'] as String,
          userRole: userData['role'] as String,
        );

        // Retourner l'utilisateur
        return AppUser.fromJson(userData);
      } else if (response.statusCode == 401) {
        throw ApiException('Email ou mot de passe incorrect', 401);
      } else {
        throw ApiException('Erreur de connexion', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de se connecter au serveur: $e');
    }
  }

  Future<AppUser> signup({
    required String nom,
    required String email,
    required String password,
    required String confirmPassword,
    int niveau = 3,
    int? clubId,
  }) async {
    try {
      // Valider les passwords côté client
      if (password != confirmPassword) {
        throw ApiException('Les mots de passe ne correspondent pas');
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/register'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'nom': nom,
              'email': email,
              'password': password,
              'confirmPassword': confirmPassword,
              'niveau': niveau,
              'clubId': clubId,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Sauvegarder le token
        await TokenStorage.saveToken(data['token'] as String);

        // Sauvegarder les infos utilisateur
        final userData = (data['utilisateur'] as Map<String, dynamic>?) ??
            (data as Map<String, dynamic>);
        await TokenStorage.saveUserInfo(
          userId: userData['id'] as int,
          userName: userData['nom'] as String,
          userRole: userData['role'] as String,
        );

        // Retourner l'utilisateur
        return AppUser.fromJson(userData);
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        throw ApiException(data['message'] ?? 'Erreur d\'inscription', 400);
      } else {
        throw ApiException('Erreur lors de l\'inscription', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de créer le compte: $e');
    }
  }

  Future<void> logout() async {
    await TokenStorage.clearAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await TokenStorage.getToken();
    return token != null;
  }
}
