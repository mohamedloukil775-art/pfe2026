import 'tournament_match.dart';

class Tournament {
  Tournament({
    required this.id,
    required this.nom,
    required this.date,
    required this.playerIds,
    this.equipeIds = const [],
    this.type = 'joueurs',
    this.maxParticipants = 8,
    this.complexeSportif = 'Vamos Sport',
    this.terrainNumero = 1,
    this.matches = const [],
  });

  final int id;
  final String nom;
  final DateTime date;
  final List<int> playerIds;
  final List<int> equipeIds;
  /// 'joueurs' or 'equipes'
  final String type;
  final int maxParticipants;
  final String complexeSportif;
  final int terrainNumero;
  final List<TournamentMatch> matches;

  bool get isTeamMode => type == 'equipes';

  List<int> get participantIds => isTeamMode ? equipeIds : playerIds;

  // keep old getter for compat
  int get maxPlayers => maxParticipants;

  factory Tournament.fromJson(Map<String, dynamic> json) {
    final rawMatches = (json['matches'] as List<dynamic>? ?? const <dynamic>[])
      .cast<Map<String, dynamic>>();
    final parsedMatches = rawMatches.map(TournamentMatch.fromJson).toList();

    final explicitPlayerIds =
      (json['joueurIds'] as List<dynamic>? ?? json['playerIds'] as List<dynamic>?);

    final inferredPlayerIds = parsedMatches
      .expand((m) => [m.joueur1, m.joueur2])
      .where((id) => id > 0)
      .toSet()
      .toList();

    final equipeIds = (json['equipeIds'] as List<dynamic>?)?.cast<int>() ?? const <int>[];
    final type = (json['type'] as String?) ?? 'joueurs';

    return Tournament(
      id: json['id'] as int,
      nom: json['nom'] as String,
      date: json['date'] != null
        ? DateTime.parse(json['date'] as String)
        : DateTime.now(),
      playerIds: explicitPlayerIds != null
        ? explicitPlayerIds.cast<int>()
        : inferredPlayerIds,
      equipeIds: equipeIds,
      type: type,
      maxParticipants: (json['maxParticipants'] ?? json['maxPlayers'] ?? json['formatJoueurs'] ?? 8) as int,
      complexeSportif: (json['complexeSportif'] ?? json['complexName'] ?? 'Vamos Sport') as String,
      terrainNumero: (json['terrainNumero'] ?? json['courtNumber'] ?? 1) as int,
      matches: parsedMatches,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'date': date.toIso8601String(),
      'type': type,
      'joueurIds': playerIds,
      'equipeIds': equipeIds,
      'maxParticipants': maxParticipants,
      'complexeSportif': complexeSportif,
      'terrainNumero': terrainNumero,
      'matches': matches.map((m) => m.toJson()).toList(),
    };
  }
}
