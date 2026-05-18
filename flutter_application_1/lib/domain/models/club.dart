class Club {
  Club({
    required this.id, 
    required this.nom, 
    required this.localisation
  });

  final int id;
  final String nom;
  final String localisation;

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] as int,
      nom: json['nom'] as String,
      localisation: json['localisation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'localisation': localisation,
    };
  }
}
