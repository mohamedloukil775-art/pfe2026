import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/domain.dart';
import '../../core/config/api_config.dart';
import '../../core/storage/request_cache.dart';
import '../../core/storage/token_storage.dart';
import '../../core/exceptions/api_exceptions.dart';

class TournamentsService {
  void _invalidateCaches() {
    RequestCache.invalidate('tournaments:list');
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

  Future<List<Tournament>> getAllTournaments() async {
    try {
      final cached = RequestCache.get<List<Tournament>>('tournaments:list');
      if (cached != null) return cached;

      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tournamentsEndpoint}'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final tournaments = data.map((json) => Tournament.fromJson(json)).toList();
        RequestCache.set('tournaments:list', tournaments);
        stopwatch.stop();
        debugPrint('Loaded tournaments in ${stopwatch.elapsedMilliseconds}ms');
        return tournaments;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else {
        throw ApiException('Erreur lors du chargement des tournois', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de charger les tournois: $e');
    }
  }

  Future<Tournament> createTournament({
    required String nom,
    required DateTime date,
    required List<int> playerIds,
    int maxPlayers = 8,
    String complexeSportif = 'Vamos Sport',
    int terrainNumero = 1,
    int clubId = 1,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tournamentsEndpoint}'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'nom': nom,
              'date': date.toIso8601String(),
              'clubId': clubId,
              'playerIds': playerIds,
              'maxPlayers': maxPlayers,
              'complexeSportif': complexeSportif,
              'terrainNumero': terrainNumero,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _invalidateCaches();
        return Tournament.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode == 400) {
        throw ValidationException(
          _extractErrorMessage(response.body, 'Données invalides'),
        );
      } else {
        throw ApiException('Erreur lors de la création du tournoi', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de créer le tournoi: $e');
    }
  }

  Future<List<TournamentMatch>> getTournamentMatches(int tournamentId) async {
    try {
      final tournaments = await getAllTournaments();
      final tournament = tournaments.firstWhere(
        (t) => t.id == tournamentId,
        orElse: () => Tournament(
          id: -1,
          nom: '',
          date: DateTime.now(),
          playerIds: const [],
        ),
      );
      if (tournament.id == -1) {
        throw ApiException('Tournoi introuvable');
      }
      return tournament.matches;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de charger les matchs du tournoi: $e');
    }
  }

  Future<void> setMatchWinner({
    required int tournamentId,
    required int matchId,
    required int winnerId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tournamentsEndpoint}/$tournamentId/winner'),
            headers: await _getHeaders(),
            body: jsonEncode({'matchId': matchId, 'winnerId': winnerId}),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode == 400) {
        throw ValidationException(
          _extractErrorMessage(response.body, 'Vainqueur invalide'),
        );
      } else if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException('Erreur lors de la définition du vainqueur', response.statusCode);
      }

      _invalidateCaches();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de définir le vainqueur: $e');
    }
  }
}
