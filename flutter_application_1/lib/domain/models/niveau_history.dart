class NiveauHistory {
  NiveauHistory({
    required this.id,
    required this.dateTest,
    required this.scoreTest,
    required this.niveauAttribue,
  });

  final int id;
  final DateTime dateTest;
  final int scoreTest;
  final int niveauAttribue;

  factory NiveauHistory.fromJson(Map<String, dynamic> json) {
    return NiveauHistory(
      id: json['id'] as int,
      dateTest: DateTime.parse(json['dateTest'] as String),
      scoreTest: json['scoreTest'] as int,
      niveauAttribue: json['niveauAttribue'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateTest': dateTest.toIso8601String(),
      'scoreTest': scoreTest,
      'niveauAttribue': niveauAttribue,
    };
  }
}
