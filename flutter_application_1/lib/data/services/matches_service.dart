import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/domain.dart';
import '../../core/config/api_config.dart';
import '../../core/storage/request_cache.dart';
import '../../core/storage/token_storage.dart';
import '../../core/exceptions/api_exceptions.dart';

class MatchesService {
  void _invalidateCaches() {
    RequestCache.invalidate('matches:list');
    RequestCache.invalidate('matches:mine');
  }

  String _extractErrorMessage(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString() ?? fallback;
      }
      if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded;
      }
    } catch (_) {
      // Keep fallback for non-JSON payloads.
    }
    return fallback;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<MatchEntry>> getAllMatches() async {
    try {
      final cached = RequestCache.get<List<MatchEntry>>('matches:list');
      if (cached != null) return cached;

      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.matchesEndpoint}'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final matches = data.map((json) => MatchEntry.fromJson(json)).toList();
        RequestCache.set('matches:list', matches);
        stopwatch.stop();
        debugPrint('Loaded matches in ${stopwatch.elapsedMilliseconds}ms');
        return matches;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else {
        throw ApiException('Erreur lors du chargement des matchs', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de charger les matchs: $e');
    }
  }

  Future<List<MatchEntry>> getMyMatches() async {
    try {
      final cached = RequestCache.get<List<MatchEntry>>('matches:mine');
      if (cached != null) return cached;

      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.matchesEndpoint}/mine'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final matches = data.map((json) => MatchEntry.fromJson(json)).toList();
        RequestCache.set('matches:mine', matches, ttl: const Duration(seconds: 20));
        stopwatch.stop();
        debugPrint('Loaded my matches in ${stopwatch.elapsedMilliseconds}ms');
        return matches;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else {
        throw ApiException('Erreur lors du chargement de mes matchs', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de charger mes matchs: $e');
    }
  }

  Future<MatchEntry> scheduleMatch({
    required DateTime date,
    required String terrain,
    required int equipe1Id,
    required int equipe2Id,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.matchesEndpoint}/schedule'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'date': date.toIso8601String(),
              'terrain': terrain,
              'equipe1Id': equipe1Id,
              'equipe2Id': equipe2Id,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _invalidateCaches();
        // Schedule endpoint currently returns no payload.
        return MatchEntry(
          id: 0,
          date: date,
          terrain: terrain,
          equipe1Id: equipe1Id,
          equipe2Id: equipe2Id,
        );
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode == 400) {
        throw ValidationException(
          _extractErrorMessage(response.body, 'Données invalides'),
        );
      } else {
        throw ApiException('Erreur lors de la planification du match', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de planifier le match: $e');
    }
  }

  Future<void> submitScore({
    required int matchId,
    required int equipeId,
    required int setsEquipe1,
    required int setsEquipe2,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.matchesEndpoint}/$matchId/submit-score'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'equipeId': equipeId,
              'scoreEquipe1': setsEquipe1,
              'scoreEquipe2': setsEquipe2,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode == 400) {
        throw ValidationException(
          _extractErrorMessage(response.body, 'Score invalide'),
        );
      } else if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException('Erreur lors de la saisie du score', response.statusCode);
      }

      _invalidateCaches();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de saisir le score: $e');
    }
  }

  Future<void> validateScore({
    required int matchId,
    required int setsEquipe1,
    required int setsEquipe2,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.matchesEndpoint}/$matchId/validate'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'scoreEquipe1': setsEquipe1,
              'scoreEquipe2': setsEquipe2,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode == 400) {
        throw ValidationException(
          _extractErrorMessage(response.body, 'Validation invalide'),
        );
      } else if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException('Erreur lors de la validation du score', response.statusCode);
      }

      _invalidateCaches();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de valider le score: $e');
    }
  }

  Future<void> deleteMatch(int matchId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.matchesEndpoint}/$matchId'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException('Erreur lors de la suppression du match', response.statusCode);
      }

      _invalidateCaches();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de supprimer le match: $e');
    }
  }
}
