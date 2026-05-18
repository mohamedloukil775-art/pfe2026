import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/app_user.dart';
import '../../domain/enums/user_role.dart';
import '../../domain/enums/user_status.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Stream of authentication changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Get current authenticated user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  /// Register a new user (Admin only)
  Future<AppUser> registerUser({
    required String email,
    required String password,
    required String nom,
    required int niveau,
    required UserRole role,
    String? clubId,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create AppUser object
      final appUser = AppUser(
        id: userCredential.user!.uid.hashCode,
        nom: nom,
        email: email,
        password: password,
        role: role,
        niveau: niveau,
        status: UserStatus.actif,
        clubId: clubId != null ? int.tryParse(clubId) : null,
        photoPath: null,
      );

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Login user
  Future<AppUser> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final appUser = AppUser(
        id: userCredential.user!.uid.hashCode,
        nom: userCredential.user!.displayName ?? email.split('@')[0],
        email: email,
        password: password,
        role: UserRole.joueur, // Default role, should be fetched from Firestore
        niveau: 1,
        status: UserStatus.actif,
        photoPath: userCredential.user!.photoURL,
      );

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw 'Erreur lors de la déconnexion: $e';
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw 'Utilisateur non authentifié';

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update user display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      await _firebaseAuth.currentUser?.updateDisplayName(displayName);
    } catch (e) {
      throw 'Erreur lors de la mise à jour du nom: $e';
    }
  }

  /// Update user profile photo
  Future<void> updateProfilePhoto(String photoURL) async {
    try {
      await _firebaseAuth.currentUser?.updatePhotoURL(photoURL);
    } catch (e) {
      throw 'Erreur lors de la mise à jour de la photo: $e';
    }
  }

  /// Handle Firebase auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Utilisateur non trouvé';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      case 'invalid-email':
        return 'Email invalide';
      case 'user-disabled':
        return 'Cet utilisateur a été désactivé';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }
}
