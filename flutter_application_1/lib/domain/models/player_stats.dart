class PlayerStats {
  PlayerStats({
    required this.playerId,
    required this.nom,
    required this.matchsJoues,
    required this.victoires,
    required this.defaites,
    required this.nuls,
    required this.diffSets,
    required this.points,
    required this.matchsProgrammes,
    required this.tauxVictoire,
  });

  final int playerId;
  final String nom;
  final int matchsJoues;
  final int victoires;
  final int defaites;
  final int nuls;
  final int diffSets;
  final int points;
  final int matchsProgrammes;
  final double tauxVictoire;

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      playerId: (json['playerId'] ?? json['joueurId']) as int,
      nom: json['nom'] as String,
      matchsJoues: json['matchsJoues'] as int,
      victoires: json['victoires'] as int,
      defaites: json['defaites'] as int,
      nuls: json['nuls'] as int,
      diffSets: (json['diffSets'] ?? json['differenceSet']) as int,
      points: json['points'] as int,
      matchsProgrammes: json['matchsProgrammes'] as int,
      tauxVictoire: (json['tauxVictoire'] as num).toDouble(),
    );
  }
}
