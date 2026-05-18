# 🚀 Guide de Démarrage - Application Championnat Padel

## ✅ État actuel (Semaine 9 terminée)

### Architecture Flutter - TERMINÉ ✓
Votre application Flutter a été restructurée en architecture modulaire professionnelle :

```
lib/
├── main.dart                     # Point d'entrée simplifié
├── core/                         # Configuration et utilitaires
│   ├── config/
│   │   └── api_config.dart      # Configuration API (URL, endpoints)
│   ├── storage/
│   │   └── token_storage.dart   # Gestion JWT sécurisée
│   └── exceptions/
│       └── api_exceptions.dart  # Gestion des erreurs API
├── domain/                       # Modèles métier
│   ├── models/                  # 10 modèles (User, Team, Match, etc.)
│   └── enums/                   # 4 enums (UserRole, MatchStatus, etc.)
├── data/                         # Couche de données
│   └── services/                # 7 services API (Auth, Players, Teams, Matches, etc.)
└── features/                     # Fonctionnalités UI
    ├── auth/
    │   └── login_screen.dart    # Écran de connexion
    ├── admin/
    │   └── admin_home_screen.dart # Accueil admin (5 onglets)
    └── player/
        └── player_home_screen.dart # Accueil joueur
```

### Backend ASP.NET Core - PRÊT ✓
Backend complet avec 7 contrôleurs REST API dans `backend/PadelChampionship.Api/`

---

## 📋 Prochaines Étapes

### Étape 1 : Installer .NET SDK 8.0

1. **Télécharger .NET SDK** :
   - Aller sur https://dotnet.microsoft.com/download
   - Télécharger `.NET 8.0 SDK` (Windows x64)
   - Exécuter l'installateur

2. **Vérifier l'installation** :
   ```powershell
   dotnet --version
   ```
   Résultat attendu : `8.x.x`

### Étape 2 : Lancer le backend

1. **Naviguer vers le dossier backend** :
   ```powershell
   cd backend\PadelChampionship.Api
   ```

2. **Restaurer les dépendances** :
   ```powershell
   dotnet restore
   ```

3. **Lancer le serveur** :
   ```powershell
   dotnet run
   ```

4. **Vérifier le lancement** :
   - Le serveur démarre sur `dotnet --versionhttp://localhost:5000`
   - Swagger UI disponible sur `http://localhost:5000/swagger`

5. **Tester l'API** :
   - Ouvrir http://localhost:5000/swagger dans le navigateur
   - Tester l'endpoint `POST /api/auth/login` avec :
     ```json
     {
       "email": "admin@padel.com",
       "motDePasse": "Admin123!"
     }
     ```

### Étape 3 : Configurer Flutter pour l'API

1. **Modifier `lib/core/config/api_config.dart`** selon votre environnement :

   **Pour émulateur Android** :
   ```dart
   static const String baseUrl = 'http://10.0.2.2:5000/api';
   ```

   **Pour iOS Simulator** :
   ```dart
   static const String baseUrl = 'http://localhost:5000/api';
   ```

   **Pour appareil physique** (trouver votre IP avec `ipconfig`) :
   ```dart
   static const String baseUrl = 'http://192.168.x.x:5000/api';
   ```

2. **Important pour Windows :** Autoriser l'accès réseau
   ```powershell
   netsh advfirewall firewall add rule name="ASP.NET Dev" dir=in action=allow protocol=TCP localport=5000
   ```

### Étape 4 : Lancer l'application Flutter

1. **Retour au dossier racine** :
   ```powershell
   cd ..\..
   ```

2. **Lancer sur émulateur/appareil** :
   ```powershell
   flutter run
   ```

3. **Tester la connexion** :
   - Email: `admin@padel.com`
   - Mot de passe: `Admin123!`

---

## 🧪 Tests de Validation

### Test 1 : Backend fonctionne
- [ ] `dotnet run` démarre sans erreur
- [ ] Swagger accessible sur http://localhost:5000/swagger
- [ ] Login admin retourne un token JWT

### Test 2 : Flutter se connecte à l'API
- [ ] `flutter run` lance l'app
- [ ] Écran de login s'affiche
- [ ] Login avec admin@padel.com réussit
- [ ] Navigation vers AdminHomeScreen

### Test 3 : Gestion des erreurs
- [ ] Login avec mauvais mot de passe → Message d'erreur
- [ ] Backend arrêté → Message "Impossible de se connecter au serveur"

---

## 🔧 Dépannage

### Problème : "Connection refused"
**Solution** : Vérifier que le backend est lancé et accessible
```powershell
curl http://localhost:5000/api/auth/login
```

### Problème : "No .NET SDKs were found"
**Solution** : Réinstaller .NET SDK 8.0 et redémarrer PowerShell

### Problème : "Target of URI doesn't exist" dans Flutter
**Solution** : Vérifier que `flutter pub get` a été exécuté

### Problème : Erreur CORS dans le navigateur
**Solution** : Le backend est déjà configuré pour CORS, vérifier Program.cs

---

## 📦 Dépendances Flutter

Packages installés (via `pubspec.yaml`) :
- `http: ^1.2.0` - Client HTTP pour API
- `flutter_secure_storage: ^9.0.0` - Stockage sécurisé JWT
- `shared_preferences: ^2.2.2` - Préférences locales

---

## 🎯 Cahier des Charges - Progression

### ✅ Mois 1 - Analyse & Conception
- [x] Semaine 1 : Périmètre MVP validé
- [x] Semaine 2 : Cas d'utilisation définis
- [x] Semaine 3 : Schéma base de données conçu
- [x] Semaine 4 : Architecture validée

### ✅ Mois 2 - Backend
- [x] Semaine 5-6 : Auth JWT + CRUD Joueurs/Équipes/Clubs
- [x] Semaine 7 : API Matchs + règle 24h forfait
- [x] Semaine 8 : API Classement + Tournois + Tests

### 🔄 Mois 3 - Frontend & Finalisation (EN COURS)
- [x] **Semaine 9** : ✅ Architecture modulaire + Auth API
- [ ] **Semaine 10** : Intégrer Joueurs/Équipes/Matchs UI
- [ ] **Semaine 11** : Intégrer Classement/Récompenses/Tournois UI
- [ ] **Semaine 12** : Tests E2E + optimisation performance

---

## 📝 Prochaine Session de Travail

**Objectif Semaine 10** : Implémenter les onglets admin avec les services API

1. **Onglet Joueurs** :
   - Liste des joueurs (PlayersService.getAllPlayers)
   - Ajout joueur (formulaire + createPlayer)
   - Mise à jour niveau (updatePlayerLevel)
   - Blocage/déblocage (blockPlayer, unblockPlayer)

2. **Onglet Équipes** :
   - Liste des équipes (TeamsService.getAllTeams)
   - Création équipe (validation niveau)

3. **Onglet Matchs** :
   - Liste des matchs (MatchesService.getAllMatches)
   - Planification match
   - Saisie et validation scores

4. **Onglet Classement** :
   - Affichage classement (StandingsService.getStandings)
   - Top 3 mensuel

5. **Onglet Tournois** :
   - Gestion tournois (TournamentsService)
   - Bracket quart/demi/finale

---

## 🔑 Comptes de Test

**Admin** :
- Email: `admin@padel.com`
- Mot de passe: `Admin123!`

**Joueur** :
- Email: `ali@padel.com`
- Mot de passe: `Player123!`

---

## 💡 Notes Importantes

1. **Mode InMemory activé par défaut** : Les données sont perdues au redémarrage du backend (pas de MySQL requis pour l'instant)

2. **Seed data automatique** : Le backend crée automatiquement les comptes admin et ali au démarrage

3. **JWT valide 8 heures** : Token d'authentification expire après 8h

4. **Architecture prête pour production** : Pour basculer vers MySQL, modifier `appsettings.json` :
   ```json
   "UseInMemoryDatabase": false
   ```

---

**État actuel : Semaine 9 terminée - Prêt pour les tests !** ✅
