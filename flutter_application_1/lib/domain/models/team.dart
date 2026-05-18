class Team {
  Team({
    required this.id, 
    required this.nom, 
    required this.playerIds,
    this.niveau = 0,
    this.photoPath,
  });

  final int id;
  final String nom;
  final List<int> playerIds;
  final int niveau;
  String? photoPath;

  factory Team.fromJson(Map<String, dynamic> json) {
    final players = json['players'] as List<dynamic>?;
    final joueurIds = json['joueurIds'] as List<dynamic>?;

    return Team(
      id: json['id'] as int,
      nom: (json['nom'] ?? json['nomEquipe']) as String,
      niveau: json['niveau'] as int? ?? 0,
      playerIds: joueurIds != null
          ? joueurIds.cast<int>()
          : (players ?? const <dynamic>[])
              .map((p) => (p as Map<String, dynamic>)['id'] as int)
              .toList(),
      photoPath: json['photoPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'niveau': niveau,
      'joueurIds': playerIds,
      'photoPath': photoPath,
    };
  }
}
