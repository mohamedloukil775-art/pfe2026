import '../../core/exceptions/api_exceptions.dart';
import '../../core/storage/mock_persistence.dart';
import '../../core/storage/token_storage.dart';
import '../../domain/domain.dart';

/// Mock AuthService for testing without backend.
///
/// Users are persisted with SharedPreferences so accounts created by the admin
/// remain available after the app is closed and restarted.
class AuthServiceMock {
  static const _storageKey = 'mock.auth';

  static final Map<String, dynamic> _seed = {
    'users': <String, String>{
      'admin@padel.com': 'Admin123!',
      'ali@padel.com': 'Player123!',
    },
    'details': <String, Map<String, dynamic>>{
      'admin@padel.com': {
        'id': 1,
        'nom': 'Admin Club',
        'email': 'admin@padel.com',
        'motDePasse': 'Admin123!',
        'role': 'Admin',
        'niveau': 10,
        'statut': 'Actif',
        'clubId': 1,
      },
      'ali@padel.com': {
        'id': 2,
        'nom': 'Ali Ben',
        'email': 'ali@padel.com',
        'motDePasse': 'Player123!',
        'role': 'Joueur',
        'niveau': 5,
        'statut': 'Actif',
        'clubId': 1,
      },
    },
  };

  static Future<Map<String, dynamic>> _loadAuthState() {
    return MockPersistence.loadObject(_storageKey, _seed);
  }

  static Future<void> _saveAuthState(Map<String, dynamic> state) {
    return MockPersistence.saveObject(_storageKey, state);
  }

  static Map<String, String> _readUsers(Map<String, dynamic> state) {
    final rawUsers = state['users'] as Map?;
    if (rawUsers == null) return <String, String>{};
    return rawUsers.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  static Map<String, Map<String, dynamic>> _readDetails(Map<String, dynamic> state) {
    final rawDetails = state['details'] as Map?;
    if (rawDetails == null) return <String, Map<String, dynamic>>{};
    return rawDetails.map(
      (key, value) => MapEntry(
        key.toString(),
        Map<String, dynamic>.from(value as Map),
      ),
    );
  }

  static Future<void> registerPlayerAccount({
    required int id,
    required String nom,
    required String email,
    required String password,
    required int niveau,
    int? clubId,
    String? photoPath,
  }) async {
    final state = await _loadAuthState();
    final users = _readUsers(state);
    final details = _readDetails(state);

    users[email] = password;
    details[email] = {
      'id': id,
      'nom': nom,
      'email': email,
      'motDePasse': password,
      'role': 'Joueur',
      'niveau': niveau,
      'statut': 'Actif',
      'clubId': clubId,
      'photoPath': photoPath,
    };

    state['users'] = users;
    state['details'] = details;
    await _saveAuthState(state);
  }

  Future<AppUser> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final state = await _loadAuthState();
    final users = _readUsers(state);
    final details = _readDetails(state);

    if (!users.containsKey(email) || users[email] != password) {
      throw ApiException('Email ou mot de passe incorrect', 401);
    }

    final userData = details[email];
    if (userData == null) {
      throw ApiException('Compte introuvable', 404);
    }

    await TokenStorage.saveToken('mock-token-$email');
    await TokenStorage.saveUserInfo(
      userId: userData['id'] as int,
      userName: userData['nom'] as String,
      userRole: userData['role'] as String,
    );

    return AppUser.fromJson(userData);
  }

  Future<AppUser> signup({
    required String nom,
    required String email,
    required String password,
    required String confirmPassword,
    int niveau = 3,
    int? clubId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (password != confirmPassword) {
      throw ApiException('Les mots de passe ne correspondent pas');
    }

    final state = await _loadAuthState();
    final users = _readUsers(state);
    final details = _readDetails(state);

    if (users.containsKey(email)) {
      throw ApiException('Cet email est déjà utilisé', 400);
    }

    final newUserId = details.isEmpty
        ? 1
        : details.values
                .map((entry) => entry['id'] as int)
                .fold(0, (a, b) => a > b ? a : b) +
            1;
    final userData = {
      'id': newUserId,
      'nom': nom,
      'email': email,
      'motDePasse': password,
      'role': 'Joueur',
      'niveau': niveau,
      'statut': 'Actif',
      'clubId': clubId,
    };

    users[email] = password;
    details[email] = userData;
    state['users'] = users;
    state['details'] = details;
    await _saveAuthState(state);

    await TokenStorage.saveToken('mock-token-$email');
    await TokenStorage.saveUserInfo(
      userId: newUserId,
      userName: nom,
      userRole: 'Joueur',
    );

    return AppUser.fromJson(userData);
  }

  Future<void> logout() async {
    await TokenStorage.clearAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await TokenStorage.getToken();
    return token != null;
  }
}
