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
    this.scoreSet1,
    this.scoreSet2,
    this.scoreSet3,
  });

  final int id;
  final TournamentRound round;
  final int joueur1;
  final int joueur2;
  int? vainqueur;
  String complexeSportif;
  int terrainNumero;
  String heureDebut;
  // Scores par manche : "6-4", "3-6", "10-7" (j1Score-j2Score)
  String? scoreSet1;
  String? scoreSet2;
  String? scoreSet3;

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
      scoreSet1: json['scoreSet1'] as String?,
      scoreSet2: json['scoreSet2'] as String?,
      scoreSet3: json['scoreSet3'] as String?,
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
      if (scoreSet1 != null) 'scoreSet1': scoreSet1,
      if (scoreSet2 != null) 'scoreSet2': scoreSet2,
      if (scoreSet3 != null) 'scoreSet3': scoreSet3,
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
