import '../../domain/domain.dart';
import 'matches_service_mock.dart';
import 'players_service_mock.dart';
import 'teams_service_mock.dart';

class StandingsServiceMock {
  Future<List<PlayerStanding>> getStandings() async {
    final results = await Future.wait([
      MatchesServiceMock().getAllMatches(),
      TeamsServiceMock().getAllTeams(),
      PlayersServiceMock().getAllPlayers(),
    ]);

    final matches = results[0] as List<MatchEntry>;
    final teams   = results[1] as List<Team>;
    final players = results[2] as List<AppUser>;

    final teamMap   = {for (final t in teams)   t.id: t};
    final playerMap = {for (final p in players) p.id: p};

    // joueurId → {points, victoires, defaites, differenceSet}
    final Map<int, Map<String, int>> stats = {};

    void addStats(int playerId, int pts, int v, int d, int diff) {
      stats.putIfAbsent(playerId, () => {
        'points': 0,
        'victoires': 0,
        'defaites': 0,
        'differenceSet': 0,
      });
      stats[playerId]!['points']        = stats[playerId]!['points']!        + pts;
      stats[playerId]!['victoires']     = stats[playerId]!['victoires']!     + v;
      stats[playerId]!['defaites']      = stats[playerId]!['defaites']!      + d;
      stats[playerId]!['differenceSet'] = stats[playerId]!['differenceSet']! + diff;
    }

    for (final match in matches) {
      if (match.status != MatchStatus.valide) continue;
      final score = match.scoreValide;
      if (score == null) continue;

      final team1 = teamMap[match.equipe1Id];
      final team2 = teamMap[match.equipe2Id];
      if (team1 == null || team2 == null) continue;

      final s1 = score.setsEquipe1;
      final s2 = score.setsEquipe2;
      final diff = s1 - s2;

      int pts1, pts2, v1, v2, d1, d2;
      if (s1 > s2) {
        // Equipe 1 gagne
        pts1 = 3; v1 = 1; d1 = 0;
        pts2 = 0; v2 = 0; d2 = 1;
      } else if (s2 > s1) {
        // Equipe 2 gagne
        pts1 = 0; v1 = 0; d1 = 1;
        pts2 = 3; v2 = 1; d2 = 0;
      } else {
        // Egalite
        pts1 = 1; v1 = 0; d1 = 0;
        pts2 = 1; v2 = 0; d2 = 0;
      }

      for (final pid in team1.playerIds) {
        addStats(pid, pts1, v1, d1, diff);
      }
      for (final pid in team2.playerIds) {
        addStats(pid, pts2, v2, d2, -diff);
      }
    }

    final standings = <PlayerStanding>[];
    for (final entry in stats.entries) {
      final player = playerMap[entry.key];
      if (player == null) continue;
      standings.add(PlayerStanding(
        joueurId: entry.key,
        nom: player.nom,
        niveau: player.niveau,
        points: entry.value['points']!,
        victoires: entry.value['victoires']!,
        defaites: entry.value['defaites']!,
        differenceSet: entry.value['differenceSet']!,
      ));
    }

    standings.sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);
      if (b.victoires != a.victoires) return b.victoires.compareTo(a.victoires);
      return b.differenceSet.compareTo(a.differenceSet);
    });

    return standings;
  }

  Future<List<Reward>> getMonthlyTop3() async {
    final standings = await getStandings();
    return standings
        .take(3)
        .toList()
        .asMap()
        .entries
        .map((e) => Reward(
              joueurId: e.value.joueurId,
              mois: DateTime.now().toIso8601String().substring(0, 7),
              position: e.key + 1,
            ))
        .toList();
  }
}
