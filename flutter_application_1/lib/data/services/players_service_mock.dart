import '../../core/exceptions/api_exceptions.dart';
import '../../core/storage/mock_persistence.dart';
import '../../core/storage/request_cache.dart';
import '../../domain/domain.dart';
import 'auth_service_mock.dart';
import 'matches_service_mock.dart';
import 'tournaments_service_mock.dart';

class PlayersServiceMock {
  static const _playersKey = 'mock.players';
  static const _historyKey = 'mock.players.history';

  static final List<Map<String, dynamic>> _seedPlayers = [
    {'id': 1,  'nom': 'Admin Club',       'email': 'admin@padel.com',     'motDePasse': 'Admin123!',  'role': 'Admin',  'niveau': 10, 'statut': 'Actif',  'clubId': 1, 'photoPath': null},
    {'id': 2,  'nom': 'Sallemi Imen',     'email': 'imen@padel.com',      'motDePasse': 'Joueur123!', 'role': 'Joueur', 'niveau': 7,  'statut': 'Actif',  'clubId': 1, 'photoPath': null},
    {'id': 3,  'nom': 'Mehrez Karim',     'email': 'karim@padel.com',     'motDePasse': 'Joueur123!', 'role': 'Joueur', 'niveau': 6,  'statut': 'Actif',  'clubId': 1, 'photoPath': null},
    {'id': 4,  'nom': 'Ben Ali Nour',     'email': 'nour@padel.com',      'motDePasse': 'Joueur123!', 'role': 'Joueur', 'niveau': 8,  'statut': 'Actif',  'clubId': 1, 'photoPath': null},
    {'id': 5,  'nom': 'Trabelsi Yassine','email': 'yassine@padel.com',   'motDePasse': 'Joueur123!', 'role': 'Joueur', 'niveau': 5,  'statut': 'Actif',  'clubId': 1, 'photoPath': null},
    {'id': 6,  'nom': 'Chaabane Rania',  'email': 'rania@padel.com',     'motDePasse': 'Joueur123!', 'role': 'Joueur', 'niveau': 7,  'statut': 'Actif',  'clubId': 2, 'photoPath': null},
    {'id': 7,  'nom': 'Jebali Mohamed',  'email': 'mohamed@padel.com',   'motDePasse': 'Joueur123!', 'role': 'Joueur', 'niveau': 4,  'statut': 'Actif',  'clubId': 2, 'photoPath': null},
    {'id': 8,  'nom': 'Sfaxi Leila',     'email': 'leila@padel.com',     'motDePasse': 'Joueur123!', 'role': 'Joueur', 'niveau': 6,  'statut': 'Actif',  'clubId': 2, 'photoPath': null},
    {'id': 9,  'nom': 'Hmidi Bilel',     'email': 'bilel@padel.com',     'motDePasse': 'Joueur123!', 'role': 'Joueur', 'niveau': 9,  'statut': 'Actif',  'clubId': 3, 'photoPath': null},
    {'id': 10, 'nom': 'Ayari Sara',      'email': 'sara@padel.com',      'motDePasse': 'Joueur123!', 'role': 'Joueur', 'niveau': 5,  'statut': 'Actif',  'clubId': 3, 'photoPath': null},
    {'id': 11, 'nom': 'Bouzid Fares',    'email': 'fares@padel.com',     'motDePasse': 'Joueur123!', 'role': 'Joueur', 'niveau': 7,  'statut': 'Actif',  'clubId': 3, 'photoPath': null},
    {'id': 12, 'nom': 'Khelifi Amira',   'email': 'amira@padel.com',     'motDePasse': 'Joueur123!', 'role': 'Joueur', 'niveau': 6,  'statut': 'Bloque', 'clubId': 4, 'photoPath': null},
    {'id': 13, 'nom': 'Mzoughi Tarek',   'email': 'tarek@padel.com',     'motDePasse': 'Joueur123!', 'role': 'Joueur', 'niveau': 8,  'statut': 'Actif',  'clubId': 4, 'photoPath': null},
  ];

  static final Map<String, List<Map<String, dynamic>>> _seedHistory = {
    '2': [
      {
        'id': 1,
        'dateTest': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        'scoreTest': 40,
        'niveauAttribue': 4,
      },
      {
        'id': 2,
        'dateTest': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        'scoreTest': 50,
        'niveauAttribue': 5,
      },
    ],
  };

  Future<List<Map<String, dynamic>>> _loadPlayerMaps() {
    return MockPersistence.loadList(_playersKey, _seedPlayers);
  }

  Future<void> _savePlayerMaps(List<Map<String, dynamic>> players) {
    return MockPersistence.saveList(_playersKey, players);
  }

  Future<Map<String, dynamic>> _loadHistoryState() {
    return MockPersistence.loadObject(_historyKey, _seedHistory);
  }

  Future<void> _saveHistoryState(Map<String, dynamic> state) {
    return MockPersistence.saveObject(_historyKey, state);
  }

  List<NiveauHistory> _parseHistory(List<dynamic> rawHistory) {
    return rawHistory
        .whereType<Map>()
        .map((entry) {
          final map = Map<String, dynamic>.from(entry.cast<String, dynamic>());
          return NiveauHistory(
            id: map['id'] as int,
            dateTest: DateTime.parse(map['dateTest'] as String),
            scoreTest: map['scoreTest'] as int,
            niveauAttribue: map['niveauAttribue'] as int,
          );
        })
        .toList();
  }

  Future<List<AppUser>> getAllPlayers() async {
    final cached = RequestCache.get<List<AppUser>>('players:list');
    if (cached != null) return cached;

    await Future.delayed(const Duration(milliseconds: 300));
    final players = (await _loadPlayerMaps()).map(AppUser.fromJson).toList();
    // Only cache if we got real data from the backend (not just the seed admin)
    if (players.length > 1) {
      RequestCache.set('players:list', players, ttl: const Duration(seconds: 5));
    }
    return players;
  }

  Future<AppUser> createPlayer({
    required String nom,
    required String email,
    required String password,
    required int niveau,
    String? photoPath,
    int? clubId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final players = await _loadPlayerMaps();
    // Prevent creating duplicate accounts with the same email
    final exists = players.any((m) => (m['email'] as String).toLowerCase() == email.toLowerCase());
    if (exists) {
      throw ApiException('Cet email est déjà utilisé');
    }
    final newId =
        players.map((m) => m['id'] as int).fold(0, (p, e) => p > e ? p : e) + 1;
    final map = {
      'id': newId,
      'nom': nom,
      'email': email,
      'motDePasse': password,
      'role': 'Joueur',
      'niveau': niveau,
      'statut': 'Actif',
      'clubId': clubId,
      'photoPath': photoPath,
    };
    players.add(map);
    await _savePlayerMaps(players);
    await AuthServiceMock.registerPlayerAccount(
      id: newId,
      nom: nom,
      email: email,
      password: password,
      niveau: niveau,
      clubId: clubId,
      photoPath: photoPath,
    );
    RequestCache.invalidate('players:list');
    RequestCache.invalidate('players:stats');
    return AppUser.fromJson(map);
  }

  Future<void> updatePlayerPhoto(int playerId, String photoPath) async {
    final players = await _loadPlayerMaps();
    final idx = players.indexWhere((m) => m['id'] == playerId);
    if (idx == -1) throw ApiException('Joueur non trouvé');
    players[idx]['photoPath'] = photoPath;
    await _savePlayerMaps(players);
    RequestCache.invalidate('players:list');
  }

  Future<void> updatePlayerName(int playerId, String newName) async {
    final players = await _loadPlayerMaps();
    final idx = players.indexWhere((m) => m['id'] == playerId);
    if (idx == -1) throw ApiException('Joueur non trouvé');
    players[idx]['nom'] = newName;
    await _savePlayerMaps(players);
    RequestCache.invalidate('players:list');
    RequestCache.invalidate('players:stats');
  }

  Future<void> updatePlayerLevel(int playerId, int newLevel) async {
    final players = await _loadPlayerMaps();
    final idx = players.indexWhere((m) => m['id'] == playerId);
    if (idx == -1) throw ApiException('Joueur non trouvé');
    players[idx]['niveau'] = newLevel;
    await _savePlayerMaps(players);
    RequestCache.invalidate('players:list');
    RequestCache.invalidate('players:stats');
  }

  Future<void> addLevelTest(
    int playerId, {
    required DateTime dateTest,
    required int scoreTest,
    required int niveauAttribue,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final historyState = await _loadHistoryState();
    final playerKey = playerId.toString();
    final list = List<Map<String, dynamic>>.from(
      (historyState[playerKey] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry.cast<String, dynamic>())),
    );
    final newId = list.isEmpty
        ? 1
        : (list.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
    list.add({
      'id': newId,
      'dateTest': dateTest.toIso8601String(),
      'scoreTest': scoreTest,
      'niveauAttribue': niveauAttribue,
    });
    historyState[playerKey] = list;
    await _saveHistoryState(historyState);
  }

  Future<List<NiveauHistory>> getLevelHistory(int playerId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final historyState = await _loadHistoryState();
    final raw = historyState[playerId.toString()] as List<dynamic>?;
    return List.unmodifiable(_parseHistory(raw ?? const <dynamic>[]));
  }

  Future<void> blockPlayer(int playerId) async {
    final players = await _loadPlayerMaps();
    final idx = players.indexWhere((m) => m['id'] == playerId);
    if (idx == -1) throw ApiException('Joueur non trouvé');
    players[idx]['statut'] = 'Bloque';
    await _savePlayerMaps(players);
    RequestCache.invalidate('players:list');
  }

  Future<void> unblockPlayer(int playerId) async {
    final players = await _loadPlayerMaps();
    final idx = players.indexWhere((m) => m['id'] == playerId);
    if (idx == -1) throw ApiException('Joueur non trouvé');
    players[idx]['statut'] = 'Actif';
    await _savePlayerMaps(players);
    RequestCache.invalidate('players:list');
  }

  Future<void> deletePlayer(int playerId) async {
    final players = await _loadPlayerMaps();
    players.removeWhere((m) => m['id'] == playerId);
    await _savePlayerMaps(players);
    final historyState = await _loadHistoryState();
    historyState.remove(playerId.toString());
    await _saveHistoryState(historyState);
    RequestCache.invalidate('players:list');
  }

  Future<PlayerStats> getPlayerStats(int playerId, {List<int> teamIds = const []}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final players = await _loadPlayerMaps();
    final player = players.firstWhere(
      (m) => m['id'] == playerId,
      orElse: () => throw ApiException('Joueur non trouvé'),
    );

    final matches = await MatchesServiceMock().getMyMatches(teamIds: teamIds);
    final completedMatches = matches.where((match) => match.status != MatchStatus.programme).toList();
    final upcomingMatches = matches.where((match) => match.status == MatchStatus.programme).toList();

    var victoires = 0;
    var defaites = 0;
    var nuls = 0;
    var diffSets = 0;

    for (final match in completedMatches) {
      final score = match.scoreValide;
      if (score == null || match.myEquipeId == null) continue;

      final isEquipe1 = match.myEquipeId == match.equipe1Id;
      final myScore = isEquipe1 ? score.setsEquipe1 : score.setsEquipe2;
      final oppScore = isEquipe1 ? score.setsEquipe2 : score.setsEquipe1;

      diffSets += myScore - oppScore;
      if (myScore > oppScore) {
        victoires += 1;
      } else if (myScore < oppScore) {
        defaites += 1;
      } else {
        nuls += 1;
      }
    }

    final tStats = await TournamentsServiceMock().getTournamentPlayerStats(playerId);
    final tVictoires = tStats['victoires'] ?? 0;
    final tDefaites  = tStats['defaites']  ?? 0;

    final totalMatchs   = completedMatches.length + tVictoires + tDefaites;
    final totalVictoires = victoires + tVictoires;
    final totalDefaites  = defaites  + tDefaites;
    final matchsProgrammes = upcomingMatches.length;
    final tauxVictoire = totalMatchs == 0 ? 0.0 : totalVictoires / totalMatchs;

    return PlayerStats(
      playerId: playerId,
      nom: player['nom'] as String,
      matchsJoues: totalMatchs,
      victoires: totalVictoires,
      defaites: totalDefaites,
      nuls: nuls,
      diffSets: diffSets,
      points: totalVictoires * 3 + nuls,
      matchsProgrammes: matchsProgrammes,
      tauxVictoire: tauxVictoire,
    );
  }
}
