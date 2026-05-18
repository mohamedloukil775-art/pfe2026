import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/team.dart';
import '../../domain/enums/user_role.dart';
import '../../domain/enums/user_status.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  static const String usersCollection = 'users';
  static const String teamsCollection = 'teams';
  static const String playersTeamsCollection = 'playersTeams';

  // ===================== USERS =====================

  /// Create or update user in Firestore
  Future<void> createUser(AppUser user) async {
    try {
      await _firestore.collection(usersCollection).doc(user.email).set({
        'id': user.id,
        'nom': user.nom,
        'email': user.email,
        'role': user.role.toString().split('.').last,
        'niveau': user.niveau,
        'status': user.status.toString().split('.').last,
        'clubId': user.clubId,
        'photoPath': user.photoPath,
        'teamId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Erreur lors de la création de l\'utilisateur: $e';
    }
  }

  /// Get user by email
  Future<AppUser?> getUserByEmail(String email) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(email).get();

      if (!doc.exists) return null;

      final data = doc.data()!;

      return AppUser(
        id: data['id'] as int,
        nom: data['nom'] as String,
        email: data['email'] as String,
        password: '', // Don't store password in Firestore
        role: data['role'] == 'admin' ? UserRole.admin : UserRole.joueur,
        niveau: data['niveau'] as int,
        status: data['status'] == 'bloque' ? UserStatus.bloque : UserStatus.actif,
        clubId: data['clubId'] as int?,
        photoPath: data['photoPath'] as String?,
      );
    } catch (e) {
      throw 'Erreur lors de la récupération de l\'utilisateur: $e';
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String email,
    String? nom,
    String? photoPath,
  }) async {
    try {
      await _firestore.collection(usersCollection).doc(email).update({
        if (nom != null) 'nom': nom,
        if (photoPath != null) 'photoPath': photoPath,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Erreur lors de la mise à jour du profil: $e';
    }
  }

  /// Get all users (Admin only)
  Future<List<AppUser>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection(usersCollection).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AppUser(
          id: data['id'] as int,
          nom: data['nom'] as String,
          email: data['email'] as String,
          password: '',
          role: data['role'] == 'admin' ? UserRole.admin : UserRole.joueur,
          niveau: data['niveau'] as int,
          status: data['status'] == 'bloque' ? UserStatus.bloque : UserStatus.actif,
          clubId: data['clubId'] as int?,
          photoPath: data['photoPath'] as String?,
        );
      }).toList();
    } catch (e) {
      throw 'Erreur lors de la récupération des utilisateurs: $e';
    }
  }

  // ===================== TEAMS =====================

  /// Create a new team
  Future<void> createTeam(Team team) async {
    try {
      await _firestore.collection(teamsCollection).doc(team.id.toString()).set({
        'id': team.id,
        'nom': team.nom,
        'niveau': team.niveau,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Erreur lors de la création de l\'équipe: $e';
    }
  }

  /// Get team by ID
  Future<Team?> getTeamById(int teamId) async {
    try {
      final doc = await _firestore.collection(teamsCollection).doc(teamId.toString()).get();

      if (!doc.exists) return null;

      final data = doc.data()!;

      return Team(
        id: data['id'] as int,
        nom: data['nom'] as String,
        niveau: data['niveau'] as int,
        playerIds: (data['joueurIds'] as List<dynamic>? ?? const <dynamic>[]).cast<int>(),
      );
    } catch (e) {
      throw 'Erreur lors de la récupération de l\'équipe: $e';
    }
  }

  /// Get all teams
  Future<List<Team>> getAllTeams() async {
    try {
      final snapshot = await _firestore.collection(teamsCollection).get();

      return snapshot.docs.map<Team>((doc) {
        final data = doc.data();
        return Team(
          id: data['id'] as int,
          nom: data['nom'] as String,
          niveau: data['niveau'] as int,
          playerIds: (data['joueurIds'] as List<dynamic>? ?? const <dynamic>[]).cast<int>(),
        );
      }).toList();
    } catch (e) {
      throw 'Erreur lors de la récupération des équipes: $e';
    }
  }

  // ===================== TEAM ASSIGNMENTS =====================

  /// Assign player to team (with validation)
  Future<void> assignPlayerToTeam({
    required String playerEmail,
    required int teamId,
  }) async {
    try {
      // Check if player already has a team
      final userDoc = await _firestore.collection(usersCollection).doc(playerEmail).get();

      if (!userDoc.exists) {
        throw 'Utilisateur non trouvé';
      }

      final userData = userDoc.data()!;
      final existingTeamId = userData['teamId'];

      if (existingTeamId != null) {
        throw 'Cet utilisateur appartient déjà à une équipe (ID: $existingTeamId). '
            'Veuillez d\'abord le retirer de son équipe actuelle.';
      }

      // Assign player to team
      await _firestore.collection(usersCollection).doc(playerEmail).update({
        'teamId': teamId,
        'teamAssignedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Erreur lors de l\'assignation à l\'équipe: $e';
    }
  }

  /// Remove player from team
  Future<void> removePlayerFromTeam(String playerEmail) async {
    try {
      await _firestore.collection(usersCollection).doc(playerEmail).update({
        'teamId': FieldValue.delete(),
        'teamRemovedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Erreur lors du retrait de l\'équipe: $e';
    }
  }

  /// Get players in team
  Future<List<AppUser>> getPlayersInTeam(int teamId) async {
    try {
      final snapshot = await _firestore
          .collection(usersCollection)
          .where('teamId', isEqualTo: teamId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AppUser(
          id: data['id'] as int,
          nom: data['nom'] as String,
          email: data['email'] as String,
          password: '',
          role: data['role'] == 'admin' ? UserRole.admin : UserRole.joueur,
          niveau: data['niveau'] as int,
          status: data['status'] == 'bloque' ? UserStatus.bloque : UserStatus.actif,
          clubId: data['clubId'] as int?,
          photoPath: data['photoPath'] as String?,
        );
      }).toList();
    } catch (e) {
      throw 'Erreur lors de la récupération des joueurs de l\'équipe: $e';
    }
  }

  /// Get player's team ID
  Future<int?> getPlayerTeamId(String playerEmail) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(playerEmail).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return data['teamId'] as int?;
    } catch (e) {
      throw 'Erreur lors de la récupération de l\'équipe du joueur: $e';
    }
  }

  /// Validate if player can join team (check level compatibility)
  Future<bool> canPlayerJoinTeam({
    required int playerLevel,
    required int teamId,
  }) async {
    try {
      final team = await getTeamById(teamId);
      if (team == null) return false;

      // Allow join if player is within 2 levels of team level
      return (playerLevel - team.niveau).abs() <= 2;
    } catch (e) {
      throw 'Erreur lors de la validation du niveau: $e';
    }
  }
}
