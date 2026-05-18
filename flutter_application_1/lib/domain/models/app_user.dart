import '../enums/user_role.dart';
import '../enums/user_status.dart';

class AppUser {
  AppUser({
    required this.id,
    required this.nom,
    required this.email,
    required this.password,
    required this.role,
    required this.niveau,
    this.status = UserStatus.actif,
    this.clubId,
    this.photoPath,
     this.teamId,
  });

  final int id;
  final String nom;
  final String email;
  final String password;
  final UserRole role;
  int niveau;
  UserStatus status;
  int? clubId;
  String? photoPath;
    int? teamId;

  String get categorieNiveau {
    if (niveau <= 3) return 'Débutant';
    if (niveau <= 6) return 'Intermédiaire';
    if (niveau <= 8) return 'Avancé';
    return 'Expert';
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final roleValue = (json['role'] as String? ?? 'Joueur').toLowerCase().trim();
    final statutValue = (json['statut'] as String? ?? 'Actif').toLowerCase();

    return AppUser(
      id: json['id'] as int,
      nom: json['nom'] as String,
      email: json['email'] as String,
      password: json['motDePasse'] as String? ?? '',
      role: roleValue.contains('admin') ? UserRole.admin : UserRole.joueur,
      niveau: json['niveau'] as int? ?? 1,
      status: statutValue == 'bloque' ? UserStatus.bloque : UserStatus.actif,
      clubId: json['clubId'] as int?,
      photoPath: json['photoPath'] as String?,
       teamId: json['teamId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'role': role == UserRole.admin ? 'Admin' : 'Joueur',
      'niveau': niveau,
      'statut': status == UserStatus.bloque ? 'Bloque' : 'Actif',
      'clubId': clubId,
      'photoPath': photoPath,
       'teamId': teamId,
    };
  }
}
