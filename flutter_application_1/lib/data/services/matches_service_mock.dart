import '../../core/storage/mock_persistence.dart';
import '../../domain/domain.dart';

class MatchesServiceMock {
  static const _storageKey = 'mock.matches';

  static List<Map<String, dynamic>> _seedMatches() => [];

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

  Future<List<MatchEntry>> getMyMatches({List<int> teamIds = const []}) async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (teamIds.isEmpty) return const [];

    final matchMaps = await _loadMatchMaps();

    // Load team names to enrich match entries
    final teamMaps = await MockPersistence.loadList('mock.teams', []);
    final teamNames = <int, String>{};
    for (final t in teamMaps) {
      final id = t['id'] as int?;
      final nom = (t['nom'] ?? t['nomEquipe']) as String?;
      if (id != null && nom != null) teamNames[id] = nom;
    }

    final result = <MatchEntry>[];
    for (final raw in matchMaps) {
      final m = MatchEntry.fromJson(raw);
      final matchingTeamId = teamIds.firstWhere(
        (tid) => m.equipe1Id == tid || m.equipe2Id == tid,
        orElse: () => -1,
      );
      if (matchingTeamId == -1) continue;

      result.add(MatchEntry(
        id: m.id,
        date: m.date,
        terrain: m.terrain,
        equipe1Id: m.equipe1Id,
        equipe2Id: m.equipe2Id,
        myEquipeId: matchingTeamId,
        equipe1Nom: teamNames[m.equipe1Id] ?? m.equipe1Nom,
        equipe2Nom: teamNames[m.equipe2Id] ?? m.equipe2Nom,
        status: m.status,
        scoreEquipe1: m.scoreEquipe1,
        scoreEquipe2: m.scoreEquipe2,
        scoreValide: m.scoreValide,
      ));
    }
    return result;
  }

  Future<MatchEntry> scheduleMatch({
    required DateTime date,
    required String terrain,
    required int equipe1Id,
    required int equipe2Id,
    String complexeSportif = 'Vamos Sport',
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final matches = await _loadMatchMaps();
    final newId = (matches.map((m) => m['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;
    final match = MatchEntry(
      id: newId,
      date: date,
      terrain: terrain,
      complexeSportif: complexeSportif,
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
    String? scoreSet1,
    String? scoreSet2,
    String? scoreSet3,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final matches = await _loadMatchMaps();
    final idx = matches.indexWhere((m) => m['id'] == matchId);
    if (idx == -1) return;
    matches[idx]['scoreValide'] = {
      'setsEquipe1': setsEquipe1,
      'setsEquipe2': setsEquipe2,
    };
    if (scoreSet1 != null) matches[idx]['scoreSet1'] = scoreSet1;
    if (scoreSet2 != null) matches[idx]['scoreSet2'] = scoreSet2;
    if (scoreSet3 != null) matches[idx]['scoreSet3'] = scoreSet3;
    matches[idx]['statut'] = 'ResultatSaisi';
    await _saveMatchMaps(matches);
  }

  Future<void> validateScore({
    required int matchId,
    required int setsEquipe1,
    required int setsEquipe2,
    String? scoreSet1,
    String? scoreSet2,
    String? scoreSet3,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final matches = await _loadMatchMaps();
    final idx = matches.indexWhere((m) => m['id'] == matchId);
    if (idx == -1) return;
    matches[idx]['scoreValide'] = {
      'setsEquipe1': setsEquipe1,
      'setsEquipe2': setsEquipe2,
    };
    if (scoreSet1 != null) matches[idx]['scoreSet1'] = scoreSet1;
    if (scoreSet2 != null) matches[idx]['scoreSet2'] = scoreSet2;
    if (scoreSet3 != null) matches[idx]['scoreSet3'] = scoreSet3;
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
