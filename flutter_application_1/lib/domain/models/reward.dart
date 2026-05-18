class Reward {
  Reward({
    required this.joueurId,
    required this.mois,
    required this.position,
  });

  final int joueurId;
  final String mois;
  final int position;

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      joueurId: (json['joueurId'] ?? json['playerId']) as int,
      mois: json['mois'] as String? ?? '',
      position: json['position'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'joueurId': joueurId,
      'mois': mois,
      'position': position,
    };
  }
}
