class ClubStanding {
  ClubStanding({
    required this.position,
    required this.clubId,
    required this.nom,
    required this.localisation,
    required this.nombreJoueurs,
    required this.pointsTotal,
    required this.niveauMoyen,
  });

  final int position;
  final int clubId;
  final String nom;
  final String localisation;
  final int nombreJoueurs;
  final int pointsTotal;
  final double niveauMoyen;

  factory ClubStanding.fromJson(Map<String, dynamic> json) {
    return ClubStanding(
      position: json['position'] as int,
      clubId: json['id'] as int,
      nom: json['nom'] as String,
      localisation: json['localisation'] as String,
      nombreJoueurs: json['nombreJoueurs'] as int,
      pointsTotal: json['pointsTotal'] as int,
      niveauMoyen: (json['niveauMoyen'] as num).toDouble(),
    );
  }
}