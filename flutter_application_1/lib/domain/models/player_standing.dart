class PlayerStanding {
  PlayerStanding({
    required this.joueurId,
    required this.nom,
    required this.niveau,
    required this.points,
    required this.victoires,
    required this.defaites,
    required this.differenceSet,
  });

  final int joueurId;
  final String nom;
  final int niveau;
  final int points;
  final int victoires;
  final int defaites;
  final int differenceSet;

  factory PlayerStanding.fromJson(Map<String, dynamic> json) {
    return PlayerStanding(
      joueurId: (json['joueurId'] ?? json['playerId']) as int,
      nom: json['nom'] as String,
      niveau: json['niveau'] as int? ?? 0,
      points: json['points'] as int,
      victoires: json['victoires'] as int,
      defaites: json['defaites'] as int,
      differenceSet: (json['differenceSet'] ?? json['diffSets']) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'joueurId': joueurId,
      'nom': nom,
      'niveau': niveau,
      'points': points,
      'victoires': victoires,
      'defaites': defaites,
      'differenceSet': differenceSet,
    };
  }
}
