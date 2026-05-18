import '../../domain/domain.dart';

class ClubsServiceMock {
  Future<List<ClubStanding>> getClubRankings() async {
    await Future.delayed(const Duration(milliseconds: 140));
    return [
      ClubStanding(
        position: 1,
        clubId: 1,
        nom: 'Padel Elite',
        localisation: 'Tunis',
        nombreJoueurs: 8,
        pointsTotal: 145,
        niveauMoyen: 5.4,
      ),
      ClubStanding(
        position: 2,
        clubId: 2,
        nom: 'Padel Nord',
        localisation: 'Bizerte',
        nombreJoueurs: 6,
        pointsTotal: 120,
        niveauMoyen: 4.9,
      ),
    ];
  }
}
