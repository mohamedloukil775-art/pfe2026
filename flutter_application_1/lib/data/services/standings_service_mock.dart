import '../../domain/domain.dart';

class StandingsServiceMock {
  static final List<PlayerStanding> _standings = [
    PlayerStanding(joueurId: 2, nom: 'Ali Ben', niveau: 5, points: 42, victoires: 6, defaites: 2, differenceSet: 8),
    PlayerStanding(joueurId: 3, nom: 'Sana', niveau: 4, points: 36, victoires: 5, defaites: 3, differenceSet: 4),
    PlayerStanding(joueurId: 4, nom: 'Yassine', niveau: 6, points: 33, victoires: 4, defaites: 3, differenceSet: 2),
  ];

  Future<List<PlayerStanding>> getStandings() async {
    await Future.delayed(const Duration(milliseconds: 140));
    return List<PlayerStanding>.from(_standings);
  }

  Future<List<Reward>> getMonthlyTop3() async {
    await Future.delayed(const Duration(milliseconds: 120));
    return [
      Reward(joueurId: 2, mois: 'Mai', position: 1),
      Reward(joueurId: 3, mois: 'Mai', position: 2),
      Reward(joueurId: 4, mois: 'Mai', position: 3),
    ];
  }
}
