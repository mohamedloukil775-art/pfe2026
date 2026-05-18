import '../enums/match_status.dart';
import 'match_score.dart';

class MatchEntry {
  MatchEntry({
    required this.id,
    required this.date,
    required this.terrain,
    required this.equipe1Id,
    required this.equipe2Id,
    this.myEquipeId,
    this.equipe1Nom,
    this.equipe2Nom,
    this.status = MatchStatus.programme,
    this.scoreEquipe1,
    this.scoreEquipe2,
    this.scoreValide,
  });

  final int id;
  final DateTime date;
  final String terrain;
  final int equipe1Id;
  final int equipe2Id;
  final int? myEquipeId;
  final String? equipe1Nom;
  final String? equipe2Nom;
  MatchStatus status;
  MatchScore? scoreEquipe1;
  MatchScore? scoreEquipe2;
  MatchScore? scoreValide;

  factory MatchEntry.fromJson(Map<String, dynamic> json) {
    final score1 = json['scoreEquipe1'];
    final score2 = json['scoreEquipe2'];
    MatchScore? combinedScore;
    if (score1 is int && score2 is int) {
      combinedScore = MatchScore(setsEquipe1: score1, setsEquipe2: score2);
    }

    return MatchEntry(
      id: json['id'] as int,
      date: DateTime.parse(json['date'] as String),
      terrain: json['terrain'] as String,
      equipe1Id: json['equipe1Id'] as int? ?? 0,
      equipe2Id: json['equipe2Id'] as int? ?? 0,
      myEquipeId: json['myEquipeId'] as int?,
      equipe1Nom: json['equipe1'] as String?,
      equipe2Nom: json['equipe2'] as String?,
      status: _parseMatchStatus((json['statut'] ?? json['Statut']) as String),
      scoreEquipe1: json['scoreEquipe1'] != null 
          && json['scoreEquipe1'] is Map<String, dynamic>
          ? MatchScore.fromJson(json['scoreEquipe1'] as Map<String, dynamic>)
          : null,
      scoreEquipe2: json['scoreEquipe2'] != null 
          && json['scoreEquipe2'] is Map<String, dynamic>
          ? MatchScore.fromJson(json['scoreEquipe2'] as Map<String, dynamic>)
          : null,
      scoreValide: json['scoreValide'] != null 
          ? MatchScore.fromJson(json['scoreValide'] as Map<String, dynamic>)
          : combinedScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'terrain': terrain,
      'equipe1Id': equipe1Id,
      'equipe2Id': equipe2Id,
      'myEquipeId': myEquipeId,
      'statut': _matchStatusToString(status),
      'scoreEquipe1': scoreEquipe1?.toJson(),
      'scoreEquipe2': scoreEquipe2?.toJson(),
      'scoreValide': scoreValide?.toJson(),
    };
  }

  static MatchStatus _parseMatchStatus(String statut) {
    switch (statut) {
      case 'Programme':
        return MatchStatus.programme;
      case 'ResultatSaisi':
        return MatchStatus.resultatSaisi;
      case 'Valide':
        return MatchStatus.valide;
      case 'Forfait':
        return MatchStatus.forfait;
      default:
        return MatchStatus.programme;
    }
  }

  static String _matchStatusToString(MatchStatus status) {
    switch (status) {
      case MatchStatus.programme:
        return 'Programme';
      case MatchStatus.resultatSaisi:
        return 'ResultatSaisi';
      case MatchStatus.valide:
        return 'Valide';
      case MatchStatus.forfait:
        return 'Forfait';
    }
  }
}
