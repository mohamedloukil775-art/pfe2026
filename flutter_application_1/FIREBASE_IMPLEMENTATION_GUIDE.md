# 🔧 Guide d'Implémentation - Nouvelles Fonctionnalités

## 📋 Vue d'ensemble

Ce guide explique comment utiliser les nouvelles fonctionnalités Firebase ajoutées au projet PadelChampionship.

---

## 🚀 Phase 1: Configuration Firebase

### 1.1 Créer un projet Firebase

1. Aller sur [Firebase Console](https://console.firebase.google.com)
2. Cliquer sur "Créer un projet"
3. Remplir les informations:
   - **Nom du projet**: `PadelChampionship`
   - **Localisation**: Choisir votre région

### 1.2 Ajouter Firebase à votre projet Flutter

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

Cela générera automatiquement `firebase_options.dart` avec vos credentials.

### 1.3 Installer les dépendances

```bash
flutter pub get
```

---

## 🔐 Phase 2: Configuration de l'Authentification

### 2.1 Activer Firebase Authentication

1. Dans Firebase Console → **Authentication**
2. Aller dans l'onglet **Sign-in method**
3. Activer **Email/Password**

### 2.2 Tester l'authentification

```dart
import 'package:firebase_auth/firebase_auth.dart';

// Login
final authService = FirebaseAuthService();
final user = await authService.loginUser(
  email: 'admin@padel.com',
  password: 'Admin123!',
);

// Register (Admin only)
final newUser = await authService.registerUser(
  email: 'joueur@padel.com',
  password: 'Player123!',
  nom: 'Jean Dupont',
  niveau: 5,
  role: UserRole.joueur,
);
```

---

## 📦 Phase 3: Configuration Firestore

### 3.1 Activer Firestore Database

1. Firebase Console → **Firestore Database**
2. Cliquer sur **Create database**
3. Sélectionner le mode: **Start in test mode** (pour développement)
4. Choisir votre région

### 3.2 Structure Firestore

L'application crée automatiquement les collections suivantes:

```
firestore/
├── users/
│   ├── admin@padel.com
│   │   ├── id: 123456
│   │   ├── nom: Admin User
│   │   ├── email: admin@padel.com
│   │   ├── role: admin
│   │   ├── niveau: 10
│   │   ├── status: actif
│   │   ├── teamId: 1
│   │   ├── photoPath: https://...
│   │   ├── createdAt: timestamp
│   │   └── updatedAt: timestamp
│   │
│   └── joueur@padel.com
│       ├── id: 654321
│       ├── nom: Joueur
│       ├── email: joueur@padel.com
│       ├── role: joueur
│       ├── niveau: 5
│       ├── status: actif
│       ├── teamId: null (ou 1 si assigné)
│       └── photoPath: null
│
├── teams/
│   ├── 1
│   │   ├── id: 1
│   │   ├── nom: Team Alpha
│   │   └── niveau: 5
│   │
│   └── 2
│       ├── id: 2
│       ├── nom: Team Beta
│       └── niveau: 8
│
└── playersTeams/
    ├── joueur@padel.com_team1
    │   ├── playerEmail: joueur@padel.com
    │   └── teamId: 1
    │
    └── autre@padel.com_team2
        ├── playerEmail: autre@padel.com
        └── teamId: 2
```

### 3.3 Règles Firestore (Sécurité)

Pour la production, mettre à jour les règles Firestore:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own document
    match /users/{email} {
      allow read: if request.auth.token.email == email;
      allow write: if request.auth.token.email == email || get(/databases/$(database)/documents/users/$(request.auth.token.email)).data.role == 'admin';
    }

    // Teams: Anyone can read, only admin can write
    match /teams/{teamId} {
      allow read: if request.auth != null;
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.token.email)).data.role == 'admin';
    }

    // Player-Team assignments
    match /playersTeams/{document=**} {
      allow read: if request.auth != null;
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.token.email)).data.role == 'admin';
    }
  }
}
```

---

## 📸 Phase 4: Configuration Firebase Storage

### 4.1 Activer Firebase Storage

1. Firebase Console → **Storage**
2. Cliquer sur **Create bucket**
3. Sélectionner votre région

### 4.2 Règles Storage

Pour la production:

```storage
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_images/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId && request.resource.size < 5 * 1024 * 1024;
      allow delete: if request.auth.uid == userId;
    }
  }
}
```

---

## 👤 Utilisation: Profil Joueur

### Accéder au profil

Les joueurs peuvent accéder à leur profil via le **BottomNavigationBar** → **Profil**

### Fonctionnalités disponibles:

#### 1. **Modifier le nom**
```dart
// Dans PlayerProfileScreen
await _firestoreService.updateUserProfile(
  email: user.email,
  nom: 'Nouveau Nom',
);
```

#### 2. **Changer le mot de passe**
```dart
await _authService.changePassword(
  currentPassword: currentPassword,
  newPassword: newPassword,
);
```

#### 3. **Télécharger une photo de profil**
```dart
final downloadUrl = await _storageService.uploadProfileImage(
  imageFile: imageFile,
  userEmail: user.email,
);
```

---

## 🛠️ Utilisation: Gestion d'Équipes (Admin)

### Accéder à la gestion d'équipes

1. Login en tant qu'admin
2. Aller dans **Admin → Team Management**

### Assigner un joueur à une équipe

```dart
// Validation automatique du niveau
final canJoin = await _firestoreService.canPlayerJoinTeam(
  playerLevel: 5,
  teamId: 1,
);

if (canJoin) {
  await _firestoreService.assignPlayerToTeam(
    playerEmail: 'joueur@padel.com',
    teamId: 1,
  );
}
```

### Règles de validation:

- ✅ Un joueur ne peut appartenir qu'à **UNE seule équipe**
- ✅ Le joueur doit être dans la **plage de niveau** (±2 niveaux de l'équipe)
- ❌ Impossible d'assigner un joueur s'il a déjà une équipe
- ✅ Les admins peuvent **retirer** un joueur d'une équipe

---

## 🔒 Sécurité et Rôles

### Contrôle d'accès basé sur les rôles

**Admin:**
- Créer de nouveaux utilisateurs (joueurs)
- Gérer les équipes
- Assigner les joueurs aux équipes
- Voir tous les profils

**Joueur:**
- Modifier son propre profil
- Changer son mot de passe
- Télécharger sa photo
- Voir son équipe (si assigné)
- Consulter son historique de matchs

### Navigation protégée

```dart
// RoleBasedNavigation vérifie automatiquement le rôle
if (user.role == UserRole.admin) {
  return AdminHomeScreen();
} else {
  return PlayerHomeScreen();
}
```

---

## 🎨 Thème Dark avec Accents Neon Green

Le projet utilise:
- **Couleur primaire (Neon Green)**: `#58D6B0`
- **Arrière-plan**: `#080B10` (noir profond)
- **Surface**: `#111318` (gris très foncé)
- **Accent secondaire**: `#DC6B2C` (orange)

Tous les boutons, champs de texte, et icônes utilisent ce thème automatiquement via `ThemeData`.

---

## ⚠️ Gestion des erreurs

### Exceptions courantes et solutions

| Erreur | Cause | Solution |
|--------|-------|----------|
| `user-not-found` | Email n'existe pas | Vérifier l'email |
| `wrong-password` | Mauvais mot de passe | Vérifier le mot de passe |
| `email-already-in-use` | Email déjà enregistré | Utiliser un autre email |
| `weak-password` | Mot de passe trop faible | Utiliser min 6 caractères |
| `permission-denied` | Pas d'accès à Firestore | Vérifier les règles Firestore |
| `network-request-failed` | Pas de connexion Internet | Vérifier la connexion |

### Logging des erreurs

```dart
try {
  // Code Firebase
} catch (e) {
  print('Erreur: $e');
  _showError(e.toString()); // Affiche à l'utilisateur
}
```

---

## 🧪 Tests

### Créer des utilisateurs de test

```bash
# En ligne de commande Firebase
firebase auth:create --email=admin@padel.com --password=Admin123! admin
firebase auth:create --email=joueur@padel.com --password=Player123! joueur
```

### Tester l'authentification

```dart
// Test Login
void testLogin() async {
  final authService = FirebaseAuthService();
  
  final user = await authService.loginUser(
    email: 'admin@padel.com',
    password: 'Admin123!',
  );
  
  print('Login réussi: ${user.email}');
}
```

---

## 📱 Déployer en Production

### Avant de déployer:

1. ✅ Désactiver le mode test de Firestore
2. ✅ Mettre en place les règles de sécurité
3. ✅ Activer HTTPS dans la console Firebase
4. ✅ Configurer le domaine autorisé dans Firebase Auth
5. ✅ Tester sur plusieurs appareils
6. ✅ Activer la vérification d'email

### Déployer l'app

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release
```

---

## 📚 Ressources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Plugin](https://firebase.flutter.dev/)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)

---

## ✅ Checklist d'Implémentation

- [ ] Firebase project créé
- [ ] FlutterFire configuré
- [ ] Firebase Auth activé
- [ ] Firestore database créé
- [ ] Firebase Storage activé
- [ ] Règles Firestore mises en place
- [ ] Utilisateurs de test créés
- [ ] App testée en local
- [ ] Déploiement en production

---

## 🎯 Prochaines étapes

1. **Notifications Push** - Firebase Cloud Messaging
2. **Analytics** - Google Analytics for Firebase
3. **Backup automatique** - Cloud Backup
4. **Performance Monitoring** - Firebase Performance
5. **Crash Reporting** - Firebase Crashlytics

---

**Créé pour PadelChampionship - Mai 2026**
