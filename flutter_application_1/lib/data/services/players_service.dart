import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/exceptions/api_exceptions.dart';
import '../../core/storage/request_cache.dart';
import '../../core/storage/token_storage.dart';
import '../../domain/domain.dart';

class PlayersService {
  void _invalidateCaches() {
    RequestCache.invalidate('players:list');
    RequestCache.invalidate('players:stats');
    RequestCache.invalidate('players:history:');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<AppUser>> getAllPlayers() async {
    try {
      final cached = RequestCache.get<List<AppUser>>('players:list');
      if (cached != null) return cached;

      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.playersEndpoint}'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final players = data.map((json) => AppUser.fromJson(json)).toList();
        RequestCache.set('players:list', players);
        stopwatch.stop();
        debugPrint('Loaded players in ${stopwatch.elapsedMilliseconds}ms');
        return players;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else {
        throw ApiException('Erreur lors du chargement des joueurs', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de charger les joueurs: $e');
    }
  }

  Future<AppUser> createPlayer({
    required String nom,
    required String email,
    required String password,
    required int niveau,
    String? photoPath,
    int? clubId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.playersEndpoint}'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'nom': nom,
              'email': email,
              'password': password,
              'niveau': niveau,
              'clubId': clubId,
              'photoPath': photoPath,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _invalidateCaches();
        return AppUser.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw ValidationException(error['message'] ?? 'Données invalides');
      } else {
        throw ApiException('Erreur lors de la création du joueur', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de créer le joueur: $e');
    }
  }

  Future<void> updatePlayerLevel(int playerId, int newLevel) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.playersEndpoint}/$playerId/level'),
            headers: await _getHeaders(),
            body: jsonEncode({'niveau': newLevel, 'scoreTest': 0}),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException('Erreur lors de la mise à jour du niveau', response.statusCode);
      }

      _invalidateCaches();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de mettre à jour le niveau: $e');
    }
  }

  Future<void> blockPlayer(int playerId) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.playersEndpoint}/$playerId/block'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException('Erreur lors du blocage du joueur', response.statusCode);
      }

      _invalidateCaches();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de bloquer le joueur: $e');
    }
  }

  Future<void> unblockPlayer(int playerId) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.playersEndpoint}/$playerId/unblock'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException('Erreur lors du déblocage du joueur', response.statusCode);
      }

      _invalidateCaches();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de débloquer le joueur: $e');
    }
  }

  Future<void> deletePlayer(int playerId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.playersEndpoint}/$playerId'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException('Erreur lors de la suppression du joueur', response.statusCode);
      }

      _invalidateCaches();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de supprimer le joueur: $e');
    }
  }

  Future<PlayerStats> getPlayerStats(int playerId) async {
    try {
      final cacheKey = 'players:stats:$playerId';
      final cached = RequestCache.get<PlayerStats>(cacheKey);
      if (cached != null) return cached;

      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.playersEndpoint}/$playerId/stats'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final stats = PlayerStats.fromJson(jsonDecode(response.body));
        RequestCache.set(cacheKey, stats, ttl: const Duration(seconds: 20));
        stopwatch.stop();
        debugPrint('Loaded player stats in ${stopwatch.elapsedMilliseconds}ms');
        return stats;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else {
        throw ApiException('Erreur lors du chargement des statistiques joueur', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de charger les statistiques joueur: $e');
    }
  }

  Future<List<NiveauHistory>> getLevelHistory(int playerId) async {
    try {
      final cacheKey = 'players:history:$playerId';
      final cached = RequestCache.get<List<NiveauHistory>>(cacheKey);
      if (cached != null) return cached;

      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.playersEndpoint}/$playerId/level-history'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final history = data.map((json) => NiveauHistory.fromJson(json)).toList();
        RequestCache.set(cacheKey, history, ttl: const Duration(seconds: 20));
        stopwatch.stop();
        debugPrint('Loaded level history in ${stopwatch.elapsedMilliseconds}ms');
        return history;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else {
        throw ApiException('Erreur lors du chargement de l\'historique des niveaux', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de charger l\'historique des niveaux: $e');
    }
  }
}
