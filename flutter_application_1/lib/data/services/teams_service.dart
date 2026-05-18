import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/domain.dart';
import '../../core/config/api_config.dart';
import '../../core/storage/request_cache.dart';
import '../../core/storage/token_storage.dart';
import '../../core/exceptions/api_exceptions.dart';

class TeamStats {
  TeamStats({
    required this.teamId,
    required this.nom,
    required this.matchsTermines,
    required this.matchsProgrammes,
    required this.victoires,
    required this.defaites,
    required this.nuls,
    required this.forfaits,
    required this.diffSets,
    required this.pointsTotal,
    required this.tauxVictoire,
    required this.recentMatches,
  });

  final int teamId;
  final String nom;
  final int matchsTermines;
  final int matchsProgrammes;
  final int victoires;
  final int defaites;
  final int nuls;
  final int forfaits;
  final int diffSets;
  final int pointsTotal;
  final double tauxVictoire;
  final List<MatchEntry> recentMatches;

  factory TeamStats.fromJson(Map<String, dynamic> json) {
    final matches = (json['recentMatches'] as List<dynamic>? ?? const [])
        .map((entry) => MatchEntry.fromJson(entry as Map<String, dynamic>))
        .toList();

    return TeamStats(
      teamId: json['teamId'] as int,
      nom: json['nom'] as String,
      matchsTermines: json['matchsTermines'] as int,
      matchsProgrammes: json['matchsProgrammes'] as int,
      victoires: json['victoires'] as int,
      defaites: json['defaites'] as int,
      nuls: json['nuls'] as int,
      forfaits: json['forfaits'] as int,
      diffSets: json['diffSets'] as int,
      pointsTotal: json['pointsTotal'] as int,
      tauxVictoire: (json['tauxVictoire'] as num).toDouble(),
      recentMatches: matches,
    );
  }
}

class TeamsService {
  void _invalidateCaches() {
    RequestCache.invalidate('teams:list');
    RequestCache.invalidate('teams:stats:');
  }

  String _extractErrorMessage(String body, String fallback) {
    if (body.trim().isEmpty) return fallback;
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['title'] ?? data['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Response is not JSON, return plain text body.
    }
    return body;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Team>> getAllTeams() async {
    try {
      final cached = RequestCache.get<List<Team>>('teams:list');
      if (cached != null) return cached;

      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.teamsEndpoint}'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final teams = data.map((json) => Team.fromJson(json)).toList();
        RequestCache.set('teams:list', teams);
        stopwatch.stop();
        debugPrint('Loaded teams in ${stopwatch.elapsedMilliseconds}ms');
        return teams;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else {
        throw ApiException('Erreur lors du chargement des équipes', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de charger les équipes: $e');
    }
  }

  Future<Team> createTeam({
    required String nom,
    required int joueur1Id,
    required int joueur2Id,
    String? photoPath,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.teamsEndpoint}'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'nomEquipe': nom,
              'playerIds': [joueur1Id, joueur2Id],
              'photoPath': photoPath,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _invalidateCaches();
        return Team.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode == 400) {
        throw ValidationException(
          _extractErrorMessage(response.body, 'Donnees invalides'),
        );
      } else {
        throw ApiException(
          _extractErrorMessage(response.body, 'Erreur lors de la creation de l\'equipe'),
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de créer l\'équipe: $e');
    }
  }

  Future<void> deleteTeam(int teamId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.teamsEndpoint}/$teamId'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          _extractErrorMessage(response.body, 'Erreur lors de la suppression de l\'equipe'),
          response.statusCode,
        );
      }

      _invalidateCaches();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de supprimer l\'équipe: $e');
    }
  }

  Future<TeamStats> getTeamStats(int teamId) async {
    try {
      final cacheKey = 'teams:stats:$teamId';
      final cached = RequestCache.get<TeamStats>(cacheKey);
      if (cached != null) return cached;

      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.teamsEndpoint}/$teamId/stats'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final stats = TeamStats.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        RequestCache.set(cacheKey, stats, ttl: const Duration(seconds: 20));
        stopwatch.stop();
        debugPrint('Loaded team stats in ${stopwatch.elapsedMilliseconds}ms');
        return stats;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode == 404) {
        throw NotFoundException('Equipe introuvable');
      } else {
        throw ApiException(
          _extractErrorMessage(response.body, 'Erreur lors du chargement des statistiques de l\'equipe'),
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de charger les statistiques de l\'equipe: $e');
    }
  }

  Future<Team> updateTeam({
    required int teamId,
    required String nom,
    required int joueur1Id,
    required int joueur2Id,
    String? photoPath,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.teamsEndpoint}/$teamId'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'nomEquipe': nom,
              'playerIds': [joueur1Id, joueur2Id],
              'photoPath': photoPath,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        _invalidateCaches();
        return Team.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode == 400) {
        throw ValidationException(
          _extractErrorMessage(response.body, 'Donnees invalides'),
        );
      } else {
        throw ApiException(
          _extractErrorMessage(response.body, 'Erreur lors de la modification de l\'equipe'),
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de modifier l\'équipe: $e');
    }
  }
}
