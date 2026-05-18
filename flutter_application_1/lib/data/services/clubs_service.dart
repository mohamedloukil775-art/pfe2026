import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/domain.dart';
import '../../core/config/api_config.dart';
import '../../core/storage/request_cache.dart';
import '../../core/storage/token_storage.dart';
import '../../core/exceptions/api_exceptions.dart';

class ClubsService {
  void _invalidateCaches() {
    RequestCache.invalidate('clubs:list');
    RequestCache.invalidate('clubs:rankings');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Club>> getAllClubs() async {
    try {
      final cached = RequestCache.get<List<Club>>('clubs:list');
      if (cached != null) return cached;

      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.clubsEndpoint}'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final clubs = data.map((json) => Club.fromJson(json)).toList();
        RequestCache.set('clubs:list', clubs);
        stopwatch.stop();
        debugPrint('Loaded clubs in ${stopwatch.elapsedMilliseconds}ms');
        return clubs;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else {
        throw ApiException('Erreur lors du chargement des clubs', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de charger les clubs: $e');
    }
  }

  Future<Club> createClub({
    required String nom,
    required String localisation,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.clubsEndpoint}'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'nom': nom,
              'localisation': localisation,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _invalidateCaches();
        return Club.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw ValidationException(error['message'] ?? 'Données invalides');
      } else {
        throw ApiException('Erreur lors de la création du club', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de créer le club: $e');
    }
  }

  Future<List<ClubStanding>> getClubRankings() async {
    try {
      final cached = RequestCache.get<List<ClubStanding>>('clubs:rankings');
      if (cached != null) return cached;

      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.clubsEndpoint}/rankings'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final rankings = data.map((json) => ClubStanding.fromJson(json)).toList();
        RequestCache.set('clubs:rankings', rankings, ttl: const Duration(seconds: 20));
        stopwatch.stop();
        debugPrint('Loaded club rankings in ${stopwatch.elapsedMilliseconds}ms');
        return rankings;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else {
        throw ApiException('Erreur lors du chargement du classement des clubs', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de charger le classement des clubs: $e');
    }
  }
}
