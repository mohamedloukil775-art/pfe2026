class MatchScore {
  MatchScore({
    required this.setsEquipe1, 
    required this.setsEquipe2
  });

  final int setsEquipe1;
  final int setsEquipe2;

  factory MatchScore.fromJson(Map<String, dynamic> json) {
    return MatchScore(
      setsEquipe1: json['setsEquipe1'] as int,
      setsEquipe2: json['setsEquipe2'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setsEquipe1': setsEquipe1,
      'setsEquipe2': setsEquipe2,
    };
  }
}
