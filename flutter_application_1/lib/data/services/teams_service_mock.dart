import '../../core/exceptions/api_exceptions.dart';
import '../../core/storage/mock_persistence.dart';
import '../../domain/domain.dart';
import 'teams_service.dart';

class TeamsServiceMock {
  static const _storageKey = 'mock.teams';

  static final List<Map<String, dynamic>> _seedTeams = [
    {'id': 1, 'nom': 'Aigles', 'joueurIds': [2, 3], 'photoPath': null},
    {'id': 2, 'nom': 'Lions', 'joueurIds': [4, 5], 'photoPath': null},
    {'id': 3, 'nom': 'Tigres', 'joueurIds': [6, 7], 'photoPath': null},
    {'id': 4, 'nom': 'Faucons', 'joueurIds': [8, 9], 'photoPath': null},
  ];

  Future<List<Map<String, dynamic>>> _loadTeamMaps() {
    return MockPersistence.loadList(_storageKey, _seedTeams);
  }

  Future<void> _saveTeamMaps(List<Map<String, dynamic>> teams) {
    return MockPersistence.saveList(_storageKey, teams);
  }

  Future<List<Team>> getAllTeams() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final teams = await _loadTeamMaps();
    return teams.map(Team.fromJson).toList();
  }

  Future<Team> createTeam({
    required String nom,
    required int joueur1Id,
    required int joueur2Id,
    String? photoPath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final teams = await _loadTeamMaps();
    final newId = (teams.map((t) => t['id'] as int).fold(0, (a, b) => a > b ? a : b)) + 1;
    final team = Team(
      id: newId,
      nom: nom,
      playerIds: [joueur1Id, joueur2Id],
      photoPath: photoPath,
    );
    teams.add(team.toJson());
    await _saveTeamMaps(teams);
    return team;
  }

  Future<Team> updateTeam({
    required int teamId,
    required String nom,
    required int joueur1Id,
    required int joueur2Id,
    String? photoPath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final teams = await _loadTeamMaps();
    final idx = teams.indexWhere((t) => t['id'] == teamId);
    if (idx == -1) throw ApiException('Equipe introuvable');
    final updated = Team(
      id: teamId,
      nom: nom,
      playerIds: [joueur1Id, joueur2Id],
      photoPath: photoPath,
    );
    teams[idx] = updated.toJson();
    await _saveTeamMaps(teams);
    return updated;
  }

  Future<void> deleteTeam(int teamId) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final teams = await _loadTeamMaps();
    teams.removeWhere((t) => t['id'] == teamId);
    await _saveTeamMaps(teams);
  }

  Future<TeamStats> getTeamStats(int teamId) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final teams = await _loadTeamMaps();
    final idx = teams.indexWhere((t) => t['id'] == teamId);
    if (idx == -1) throw ApiException('Equipe introuvable');
    final team = Team.fromJson(teams[idx]);

    return TeamStats(
      teamId: team.id,
      nom: team.nom,
      matchsTermines: 8,
      matchsProgrammes: 2,
      victoires: 5,
      defaites: 2,
      nuls: 1,
      forfaits: 0,
      diffSets: 6,
      pointsTotal: 16,
      tauxVictoire: 0.62,
      recentMatches: [
        MatchEntry(
          id: 900 + team.id,
          date: DateTime.now().subtract(const Duration(days: 3)),
          terrain: 'Terrain A',
          equipe1Id: team.id,
          equipe2Id: 1,
          status: MatchStatus.valide,
          scoreValide: MatchScore(setsEquipe1: 2, setsEquipe2: 1),
        ),
      ],
    );
  }
}
