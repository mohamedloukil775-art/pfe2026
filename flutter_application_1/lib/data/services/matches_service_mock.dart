import '../../core/storage/mock_persistence.dart';
import '../../domain/domain.dart';

class MatchesServiceMock {
  static const _storageKey = 'mock.matches';

  static List<Map<String, dynamic>> _seedMatches() => [
        {
          'id': 1,
          'date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          'terrain': 'Terrain 1',
          'equipe1Id': 1,
          'equipe2Id': 2,
          'myEquipeId': 1,
          'equipe1Nom': 'Aigles',
          'equipe2Nom': 'Lions',
          'statut': 'Programme',
        },
        {
          'id': 2,
          'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'terrain': 'Terrain 2',
          'equipe1Id': 1,
          'equipe2Id': 3,
          'myEquipeId': 1,
          'equipe1Nom': 'Aigles',
          'equipe2Nom': 'Tigres',
          'statut': 'Valide',
          'scoreValide': {'setsEquipe1': 2, 'setsEquipe2': 0},
        },
      ];

  Future<List<Map<String, dynamic>>> _loadMatchMaps() {
    return MockPersistence.loadList(_storageKey, _seedMatches());
  }

  Future<void> _saveMatchMaps(List<Map<String, dynamic>> matches) {
    return MockPersistence.saveList(_storageKey, matches);
  }

  Future<List<MatchEntry>> getAllMatches() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final matches = await _loadMatchMaps();
    return matches.map(MatchEntry.fromJson).toList();
  }

  Future<List<MatchEntry>> getMyMatches({int? teamId}) async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (teamId == null) return const [];

    final matches = await _loadMatchMaps();
    return matches
        .map(MatchEntry.fromJson)
        .where((match) =>
            match.myEquipeId == teamId ||
            match.equipe1Id == teamId ||
            match.equipe2Id == teamId)
        .toList();
  }

  Future<MatchEntry> scheduleMatch({
    required DateTime date,
    required String terrain,
    required int equipe1Id,
    required int equipe2Id,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final matches = await _loadMatchMaps();
    final newId = (matches.map((m) => m['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;
    final match = MatchEntry(
      id: newId,
      date: date,
      terrain: terrain,
      equipe1Id: equipe1Id,
      equipe2Id: equipe2Id,
      status: MatchStatus.programme,
    );
    matches.add(match.toJson());
    await _saveMatchMaps(matches);
    return match;
  }

  Future<void> submitScore({
    required int matchId,
    required int equipeId,
    required int setsEquipe1,
    required int setsEquipe2,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final matches = await _loadMatchMaps();
    final idx = matches.indexWhere((m) => m['id'] == matchId);
    if (idx == -1) return;
    matches[idx]['scoreValide'] = {
      'setsEquipe1': setsEquipe1,
      'setsEquipe2': setsEquipe2,
    };
    matches[idx]['statut'] = 'ResultatSaisi';
    await _saveMatchMaps(matches);
  }

  Future<void> validateScore({
    required int matchId,
    required int setsEquipe1,
    required int setsEquipe2,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final matches = await _loadMatchMaps();
    final idx = matches.indexWhere((m) => m['id'] == matchId);
    if (idx == -1) return;
    matches[idx]['scoreValide'] = {
      'setsEquipe1': setsEquipe1,
      'setsEquipe2': setsEquipe2,
    };
    matches[idx]['statut'] = 'Valide';
    await _saveMatchMaps(matches);
  }

  Future<void> deleteMatch(int matchId) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final matches = await _loadMatchMaps();
    matches.removeWhere((m) => m['id'] == matchId);
    await _saveMatchMaps(matches);
  }
}
