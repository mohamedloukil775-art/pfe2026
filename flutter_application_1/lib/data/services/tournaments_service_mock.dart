import '../../core/storage/mock_persistence.dart';
import '../../domain/domain.dart';

class TournamentsServiceMock {
  static const _storageKey = 'mock.tournaments.v2';
  static const _statsKey   = 'mock.tournament_player_stats';

  static final List<Map<String, dynamic>> _seedTournaments = [
    {
      'id': 1,
      'nom': 'Tournoi Printemps',
      'type': 'joueurs',
      'date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'joueurIds': [2, 3, 4, 5, 6, 7, 8, 9],
      'equipeIds': [],
      'maxParticipants': 8,
      'complexeSportif': 'La Casa del Padel',
      'terrainNumero': 2,
      'matches': [
        {
          'id': 11,
          'tour': 'Quart',
          'joueur1Id': 2,
          'joueur2Id': 3,
          'vainqueurId': 2,
          'complexeSportif': 'La Casa del Padel',
          'terrainNumero': 1,
          'heureDebut': '18:00',
        },
        {
          'id': 12,
          'tour': 'Quart',
          'joueur1Id': 4,
          'joueur2Id': 5,
          'vainqueurId': 4,
          'complexeSportif': 'La Casa del Padel',
          'terrainNumero': 2,
          'heureDebut': '19:00',
        },
        {
          'id': 13,
          'tour': 'Quart',
          'joueur1Id': 6,
          'joueur2Id': 7,
          'complexeSportif': 'La Casa del Padel',
          'terrainNumero': 3,
          'heureDebut': '20:00',
        },
        {
          'id': 14,
          'tour': 'Quart',
          'joueur1Id': 8,
          'joueur2Id': 9,
          'complexeSportif': 'La Casa del Padel',
          'terrainNumero': 4,
          'heureDebut': '21:00',
        },
        {
          'id': 15,
          'tour': 'Demi',
          'joueur1Id': 2,
          'joueur2Id': 4,
          'complexeSportif': 'La Casa del Padel',
          'terrainNumero': 1,
          'heureDebut': '18:00',
        },
        {
          'id': 16,
          'tour': 'Demi',
          'joueur1Id': 0,
          'joueur2Id': 0,
          'complexeSportif': 'La Casa del Padel',
          'terrainNumero': 2,
          'heureDebut': '20:00',
        },
        {
          'id': 17,
          'tour': 'Finale',
          'joueur1Id': 0,
          'joueur2Id': 0,
          'vainqueurId': null,
          'complexeSportif': 'La Casa del Padel',
          'terrainNumero': 1,
          'heureDebut': '20:00',
        },
      ],
    },
  ];

  // ── Round helpers ──────────────────────────────────────────────────────────

  int _roundOrder(TournamentRound round) {
    switch (round) {
      case TournamentRound.seizieme: return 0;
      case TournamentRound.huitieme: return 1;
      case TournamentRound.quart:    return 2;
      case TournamentRound.demi:     return 3;
      case TournamentRound.finale:   return 4;
    }
  }

  TournamentRound _roundFromOrder(int order) {
    switch (order) {
      case 0: return TournamentRound.seizieme;
      case 1: return TournamentRound.huitieme;
      case 2: return TournamentRound.quart;
      case 3: return TournamentRound.demi;
      default: return TournamentRound.finale;
    }
  }

  String _roundToString(TournamentRound round) {
    switch (round) {
      case TournamentRound.seizieme: return 'Seizieme';
      case TournamentRound.huitieme: return 'Huitieme';
      case TournamentRound.quart:    return 'Quart';
      case TournamentRound.demi:     return 'Demi';
      case TournamentRound.finale:   return 'Finale';
    }
  }

  TournamentRound _initialRoundForSize(int size) {
    if (size >= 32) return TournamentRound.seizieme;
    if (size >= 16) return TournamentRound.huitieme;
    if (size >= 8)  return TournamentRound.quart;
    return TournamentRound.demi;  // 4 participants
  }

  int _maxRoundOrderForSize(int size) {
    return _roundOrder(TournamentRound.finale);
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _loadTournamentMaps() {
    return MockPersistence.loadList(_storageKey, _seedTournaments);
  }

  Future<void> _saveTournamentMaps(List<Map<String, dynamic>> tournaments) {
    return MockPersistence.saveList(_storageKey, tournaments);
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<List<Tournament>> getAllTournaments() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final tournaments = await _loadTournamentMaps();
    return tournaments.map(Tournament.fromJson).toList();
  }

  Future<Tournament> createTournament({
    required String nom,
    required DateTime date,
    required List<int> participantIds,
    required String type,
    int maxParticipants = 8,
    String complexeSportif = 'Vamos Sport',
    int terrainNumero = 1,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final tournaments = await _loadTournamentMaps();
    final newId = (tournaments.map((t) => t['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;
    final ids = participantIds.take(maxParticipants).toList();
    final matches = <Map<String, dynamic>>[];

    if (ids.length >= 4 && ids.length % 2 == 0) {
      final firstRound = _initialRoundForSize(ids.length);
      final roundStr = _roundToString(firstRound);
      for (var i = 0; i < ids.length; i += 2) {
        final hour = 18 + (i ~/ 2);
        matches.add({
          'id': newId * 100 + (i ~/ 2) + 1,
          'tour': roundStr,
          'joueur1Id': ids[i],
          'joueur2Id': ids[i + 1],
          'vainqueurId': null,
          'complexeSportif': complexeSportif,
          'terrainNumero': (i ~/ 2) % 4 + 1,
          'heureDebut': '${hour.toString().padLeft(2, '0')}:00',
        });
      }
      // Pre-create subsequent round placeholders
      final totalRounds = _roundOrder(TournamentRound.finale) - _roundOrder(firstRound) + 1;
      var prevCount = ids.length ~/ 2;
      for (var r = 1; r < totalRounds; r++) {
        final nextRound = _roundFromOrder(_roundOrder(firstRound) + r);
        final nextRoundStr = _roundToString(nextRound);
        final nextCount = prevCount ~/ 2;
        for (var j = 0; j < nextCount; j++) {
          matches.add({
            'id': newId * 100 + 50 + r * 10 + j + 1,
            'tour': nextRoundStr,
            'joueur1Id': 0,
            'joueur2Id': 0,
            'vainqueurId': null,
            'complexeSportif': complexeSportif,
            'terrainNumero': j % 4 + 1,
            'heureDebut': '18:00',
          });
        }
        prevCount = nextCount;
      }
    }

    final tMap = <String, dynamic>{
      'id': newId,
      'nom': nom,
      'type': type,
      'date': date.toIso8601String(),
      'joueurIds': type == 'joueurs' ? ids : [],
      'equipeIds': type == 'equipes' ? ids : [],
      'maxParticipants': maxParticipants,
      'complexeSportif': complexeSportif,
      'terrainNumero': terrainNumero,
      'matches': matches,
    };

    tournaments.add(tMap);
    await _saveTournamentMaps(tournaments);
    return Tournament.fromJson(tMap);
  }

  Future<void> deleteTournament(int tournamentId) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final tournaments = await _loadTournamentMaps();
    tournaments.removeWhere((t) => t['id'] == tournamentId);
    await _saveTournamentMaps(tournaments);
  }

  Future<List<TournamentMatch>> getTournamentMatches(int tournamentId) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final tournaments = await _loadTournamentMaps();
    final tournament = tournaments.firstWhere((t) => t['id'] == tournamentId);
    return Tournament.fromJson(tournament).matches;
  }

  /// Sets the winner of a match and auto-advances them to the next round.
  Future<void> setMatchWinner({
    required int tournamentId,
    required int matchId,
    required int winnerId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final tournaments = await _loadTournamentMaps();
    final tIndex = tournaments.indexWhere((t) => t['id'] == tournamentId);
    if (tIndex == -1) return;

    final tMap = Map<String, dynamic>.from(tournaments[tIndex]);
    final rawMatches = (tMap['matches'] as List<dynamic>)
        .map((m) => Map<String, dynamic>.from(m as Map))
        .toList();

    // Set winner on current match
    final mIndex = rawMatches.indexWhere((m) => m['id'] == matchId);
    if (mIndex == -1) return;
    rawMatches[mIndex]['vainqueurId'] = winnerId;

    // Auto-advance: find position in current round
    final currentTour = rawMatches[mIndex]['tour'] as String;
    final currentRound = Tournament.fromJson(tMap).matches
        .firstWhere((m) => m.id == matchId)
        .round;
    final currentOrder = _roundOrder(currentRound);
    final maxOrder = _maxRoundOrderForSize(
      (tMap['maxParticipants'] ?? tMap['maxPlayers'] ?? 8) as int,
    );

    if (currentOrder < maxOrder) {
      // Get sorted current-round matches to find position
      final currentRoundMatches = rawMatches
          .where((m) => m['tour'] == currentTour)
          .toList()
        ..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
      final posInRound = currentRoundMatches.indexWhere((m) => m['id'] == matchId);
      if (posInRound == -1) return;

      final nextMatchPos = posInRound ~/ 2;
      final isJoueur1 = posInRound % 2 == 0;
      final nextRound = _roundFromOrder(currentOrder + 1);
      final nextRoundStr = _roundToString(nextRound);

      final nextRoundMatches = rawMatches
          .where((m) => m['tour'] == nextRoundStr)
          .toList()
        ..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));

      if (nextMatchPos < nextRoundMatches.length) {
        final nextMatchId = nextRoundMatches[nextMatchPos]['id'] as int;
        final nmIndex = rawMatches.indexWhere((m) => m['id'] == nextMatchId);
        if (nmIndex != -1) {
          if (isJoueur1) {
            rawMatches[nmIndex]['joueur1Id'] = winnerId;
          } else {
            rawMatches[nmIndex]['joueur2Id'] = winnerId;
          }
        }
      }
    }

    tMap['matches'] = rawMatches;
    tournaments[tIndex] = tMap;
    await _saveTournamentMaps(tournaments);

    // Track win/loss stats for player-mode tournaments
    if ((tMap['type'] as String?) == 'joueurs') {
      final lm = rawMatches[mIndex];
      final j1 = lm['joueur1Id'] as int;
      final j2 = lm['joueur2Id'] as int;
      if (j1 > 0 && j2 > 0) {
        final loserId = j1 == winnerId ? j2 : j1;
        await _updateTournamentStats(winnerId: winnerId, loserId: loserId);
      }
    }
  }

  Future<List<Tournament>> getTournamentsForPlayer(
    int playerId, {
    List<int> teamIds = const [],
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final tournaments = await _loadTournamentMaps();
    return tournaments.map(Tournament.fromJson).where((t) {
      if (t.type == 'joueurs') return t.playerIds.contains(playerId);
      return teamIds.any((tid) => t.equipeIds.contains(tid));
    }).toList();
  }

  Future<Map<String, int>> getTournamentPlayerStats(int playerId) async {
    final stats = await MockPersistence.loadObject(_statsKey, <String, dynamic>{});
    final raw = (stats[playerId.toString()] as Map?)?.cast<String, dynamic>() ?? {};
    return {
      'victoires': (raw['victoires'] as int?) ?? 0,
      'defaites':  (raw['defaites']  as int?) ?? 0,
    };
  }

  Future<void> _updateTournamentStats({
    required int winnerId,
    required int loserId,
  }) async {
    final stats = await MockPersistence.loadObject(_statsKey, <String, dynamic>{});

    final wKey = winnerId.toString();
    final wMap = Map<String, dynamic>.from(
        (stats[wKey] as Map?)?.cast<String, dynamic>() ?? {});
    wMap['victoires'] = ((wMap['victoires'] as int?) ?? 0) + 1;
    stats[wKey] = wMap;

    if (loserId > 0) {
      final lKey = loserId.toString();
      final lMap = Map<String, dynamic>.from(
          (stats[lKey] as Map?)?.cast<String, dynamic>() ?? {});
      lMap['defaites'] = ((lMap['defaites'] as int?) ?? 0) + 1;
      stats[lKey] = lMap;
    }

    await MockPersistence.saveObject(_statsKey, stats);
  }

  Future<void> updateMatchSchedule({
    required int tournamentId,
    required int matchId,
    required String complexeSportif,
    required int terrainNumero,
    required String heureDebut,
    DateTime? matchDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final tournaments = await _loadTournamentMaps();
    final tIndex = tournaments.indexWhere((t) => t['id'] == tournamentId);
    if (tIndex == -1) return;

    final tMap = Map<String, dynamic>.from(tournaments[tIndex]);
    final rawMatches = (tMap['matches'] as List<dynamic>)
        .map((m) => Map<String, dynamic>.from(m as Map))
        .toList();

    final mIndex = rawMatches.indexWhere((m) => m['id'] == matchId);
    if (mIndex == -1) return;

    rawMatches[mIndex]['complexeSportif'] = complexeSportif;
    rawMatches[mIndex]['terrainNumero'] = terrainNumero;
    rawMatches[mIndex]['heureDebut'] = heureDebut;
    if (matchDate != null) {
      rawMatches[mIndex]['matchDate'] = matchDate.toIso8601String();
    }

    tMap['matches'] = rawMatches;
    tournaments[tIndex] = tMap;
    await _saveTournamentMaps(tournaments);
  }
}
