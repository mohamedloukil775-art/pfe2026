import '../enums/tournament_round.dart';

class TournamentMatch {
  TournamentMatch({
    required this.id,
    required this.round,
    required this.joueur1,
    required this.joueur2,
    this.vainqueur,
    this.complexeSportif = 'La Casa del Padel',
    this.terrainNumero = 1,
    this.heureDebut = '18:00',
  });

  final int id;
  final TournamentRound round;
  final int joueur1;
  final int joueur2;
  int? vainqueur;
  String complexeSportif;
  int terrainNumero;
  String heureDebut;

  factory TournamentMatch.fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      id: json['id'] as int,
      round: _parseTournamentRound((json['tour'] ?? json['round']) as String),
      joueur1: json['joueur1Id'] as int,
      joueur2: json['joueur2Id'] as int,
      vainqueur: (json['vainqueurId'] ?? json['winnerId']) as int?,
      complexeSportif:
          (json['complexeSportif'] ?? json['complexName'] ?? 'La Casa del Padel')
              as String,
      terrainNumero: (json['terrainNumero'] ?? json['courtNumber'] ?? 1) as int,
      heureDebut: (json['heureDebut'] ?? json['startTime'] ?? '18:00') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tour': _tournamentRoundToString(round),
      'joueur1Id': joueur1,
      'joueur2Id': joueur2,
      'vainqueurId': vainqueur,
      'complexeSportif': complexeSportif,
      'terrainNumero': terrainNumero,
      'heureDebut': heureDebut,
    };
  }

  static TournamentRound _parseTournamentRound(String tour) {
    switch (tour) {
      case 'Seizieme':
        return TournamentRound.seizieme;
      case 'Huitieme':
        return TournamentRound.huitieme;
      case 'Quart':
        return TournamentRound.quart;
      case 'Demi':
        return TournamentRound.demi;
      case 'Finale':
        return TournamentRound.finale;
      default:
        return TournamentRound.quart;
    }
  }

  static String _tournamentRoundToString(TournamentRound round) {
    switch (round) {
      case TournamentRound.seizieme:
        return 'Seizieme';
      case TournamentRound.huitieme:
        return 'Huitieme';
      case TournamentRound.quart:
        return 'Quart';
      case TournamentRound.demi:
        return 'Demi';
      case TournamentRound.finale:
        return 'Finale';
    }
  }
}
