# 📂 Structure du Projet - Championnat Padel

## Vue d'ensemble

```
flutter_application_1/
├── 📱 lib/                              # Code source Flutter
├── 🔧 backend/                          # Backend ASP.NET Core
├── 📝 Documentation/                    # Fichiers créés cette session
├── 🧪 test/                             # Tests Flutter
├── 🤖 android/                          # Configuration Android
├── 🍎 ios/                              # Configuration iOS
├── 🪟 windows/                          # Configuration Windows
├── 🐧 linux/                            # Configuration Linux
├── 🍎 macos/                            # Configuration macOS
└── 🌐 web/                              # Configuration Web
```

---

## 📱 lib/ (Code Flutter - Architecture Modulaire)

```
lib/
├── main.dart                            # Point d'entrée (17 lignes)
├── main.dart.backup                     # Ancien monolithique (1746 lignes)
│
├── 🎯 core/                             # Configuration & Utilitaires
│   ├── config/
│   │   └── api_config.dart             # URL API + endpoints
│   ├── storage/
│   │   └── token_storage.dart          # Stockage JWT sécurisé
│   └── exceptions/
│       └── api_exceptions.dart         # Exceptions personnalisées
│
├── 📦 domain/                           # Modèles Métier (Domain Layer)
│   ├── enums/
│   │   ├── user_role.dart              # Admin / Joueur
│   │   ├── user_status.dart            # Actif / Bloqué
│   │   ├── match_status.dart           # Programme / Saisi / Validé / Forfait
│   │   ├── tournament_round.dart       # Quart / Demi / Finale
│   │   └── enums.dart                  # Barrel file
│   ├── models/
│   │   ├── app_user.dart               # Utilisateur + JSON serialization
│   │   ├── team.dart                   # Équipe (2 joueurs)
│   │   ├── club.dart                   # Club de padel
│   │   ├── match_entry.dart            # Match championnat
│   │   ├── match_score.dart            # Score match
│   │   ├── tournament.dart             # Tournoi (8 joueurs)
│   │   ├── tournament_match.dart       # Match de tournoi
│   │   ├── player_standing.dart        # Classement joueur
│   │   ├── reward.dart                 # Récompense top 3
│   │   ├── niveau_history.dart         # Historique niveau
│   │   └── models.dart                 # Barrel file
│   └── domain.dart                      # Barrel file global
│
├── 🔄 data/                             # Couche Données (Data Layer)
│   ├── services/
│   │   ├── auth_service.dart           # Auth JWT (login, logout)
│   │   ├── players_service.dart        # CRUD joueurs (6 méthodes)
│   │   ├── teams_service.dart          # CRUD équipes (3 méthodes)
│   │   ├── matches_service.dart        # Gestion matchs (5 méthodes)
│   │   ├── standings_service.dart      # Classement + top 3 (2 méthodes)
│   │   ├── tournaments_service.dart    # Tournois (4 méthodes)
│   │   ├── clubs_service.dart          # Clubs (2 méthodes)
│   │   └── services.dart               # Barrel file
│   └── (repositories/)                  # Future: Abstraction services
│
└── 🎨 features/                         # Fonctionnalités UI (Presentation Layer)
    ├── auth/
    │   └── login_screen.dart           # Écran connexion + validation
    ├── admin/
    │   ├── admin_home_screen.dart      # Accueil admin (5 onglets)
    │   ├── joueurs/                    # ⏳ Semaine 10
    │   │   └── joueurs_tab.dart        # [À CRÉER] CRUD joueurs UI
    │   ├── equipes/                    # ⏳ Semaine 10
    │   │   └── equipes_tab.dart        # [À CRÉER] CRUD équipes UI
    │   ├── matchs/                     # ⏳ Semaine 10
    │   │   └── matchs_tab.dart         # [À CRÉER] Gestion matchs UI
    │   ├── classement/                 # ⏳ Semaine 11
    │   │   └── classement_tab.dart     # [À CRÉER] Classement + top 3 UI
    │   └── tournois/                   # ⏳ Semaine 11
    │       └── tournois_tab.dart       # [À CRÉER] Tournois + bracket UI
    └── player/
        ├── player_home_screen.dart     # Accueil joueur (placeholder)
        └── mes_matchs/                 # ⏳ Semaine 11
            └── mes_matchs_screen.dart  # [À CRÉER] Matchs du joueur
```

**Statistiques lib/** :
- **30 fichiers** actuels
- **~3500 lignes** de code
- **7 services API** (22 méthodes)
- **10 modèles** + **4 enums**

---

## 🔧 backend/ (Backend ASP.NET Core)

```
backend/
└── PadelChampionship.Api/
    ├── Program.cs                       # Startup + configuration middleware
    ├── appsettings.json                 # Configuration (JWT, DB, InMemory flag)
    ├── PadelChampionship.Api.csproj     # Fichier projet .NET
    │
    ├── Controllers/                     # 7 contrôleurs REST API
    │   ├── AuthController.cs            # POST /api/auth/login
    │   ├── PlayersController.cs         # CRUD joueurs (6 endpoints)
    │   ├── TeamsController.cs           # CRUD équipes (3 endpoints)
    │   ├── MatchesController.cs         # Gestion matchs (5 endpoints)
    │   ├── StandingsController.cs       # GET classement + top3
    │   ├── TournamentsController.cs     # Tournois (4 endpoints)
    │   └── ClubsController.cs           # GET/POST clubs
    │
    ├── Models/
    │   ├── Enums.cs                     # UserRole, UserStatus, MatchStatus, TournamentRound
    │   └── Entities.cs                  # 10 entités EF Core (User, Team, Match, etc.)
    │
    ├── Data/
    │   └── ApplicationDbContext.cs      # EF Core DbContext + relations
    │
    ├── Services/
    │   └── JwtTokenService.cs           # Génération tokens JWT
    │
    ├── Dtos/                            # Data Transfer Objects
    │   ├── AuthDtos.cs                  # LoginRequest, LoginResponse
    │   ├── PlayerDtos.cs                # CreatePlayerDto, UpdateLevelDto
    │   ├── TeamDtos.cs                  # CreateTeamDto
    │   ├── MatchDtos.cs                 # ScheduleMatchDto, ScoreDto
    │   └── TournamentDtos.cs            # CreateTournamentDto, SetWinnerDto
    │
    └── README.md                        # Documentation backend (endpoints, setup)
```

**Architecture Backend** :
- **7 contrôleurs** → **22 endpoints** REST
- **10 entités** EF Core
- **JWT** authentication (8h expiration)
- **BCrypt** password hashing
- **InMemory** database (basculable MySQL)

---

## 📝 Documentation/ (Créée Semaine 9)

```
flutter_application_1/
├── README.md                            # README principal projet
├── GUIDE_DEMARRAGE.md                   # 🆕 Guide étape par étape complet
├── ARCHITECTURE.md                      # 🆕 Documentation architecture technique
├── CHANGELOG.md                         # 🆕 Historique modifications
├── QUICK_START.md                       # 🆕 Démarrage rapide session suivante
└── CHECKLIST.md                         # 🆕 Checklist progression 12 semaines
```

**6 fichiers** de documentation créés cette session

---

## 🧪 test/ (Tests Flutter)

```
test/
└── widget_test.dart                     # Test widget LoginScreen
```

**⏳ À ajouter Semaine 12** :
- `services/` - Tests unitaires services API
- `features/` - Tests widgets screens
- `integration_test/` - Tests E2E

---

## 🔑 Fichiers de Configuration

```
flutter_application_1/
├── pubspec.yaml                         # Dépendances Flutter
├── analysis_options.yaml                # Règles lint Dart
├── .gitignore                           # Fichiers ignorés Git
└── flutter_application_1.iml            # Configuration IntelliJ
```

**Packages installés (pubspec.yaml)** :
```yaml
dependencies:
  flutter:
  cupertino_icons: ^1.0.8
  http: ^1.2.0                           # 🆕 Client HTTP
  flutter_secure_storage: ^9.0.0        # 🆕 Stockage JWT
  shared_preferences: ^2.2.2             # 🆕 Préférences
```

---

## 📱 Plateformes Configurées

- ✅ **Android** (`android/`)
- ✅ **iOS** (`ios/`)
- ✅ **Windows** (`windows/`)
- ✅ **Linux** (`linux/`)
- ✅ **macOS** (`macos/`)
- ✅ **Web** (`web/`)

---

## 📊 Métriques Projet

### Code Source
- **Frontend** : ~3500 lignes Dart (30 fichiers modulaires)
- **Backend** : ~2500 lignes C# (20 fichiers)
- **Total** : ~6000 lignes code

### Services & Endpoints
- **7 services** Flutter API
- **22 méthodes** API au total
- **7 contrôleurs** Backend
- **22 endpoints** REST

### Modèles
- **10 modèles** métier
- **4 enums**
- **10 entités** EF Core

### Documentation
- **6 fichiers** markdown
- **~2000 lignes** documentation

---

## 🎯 Prochains Dossiers à Créer

**Semaine 10** :
```
lib/features/admin/
├── joueurs/
│   ├── joueurs_tab.dart
│   ├── add_player_dialog.dart
│   └── edit_level_dialog.dart
├── equipes/
│   ├── equipes_tab.dart
│   └── create_team_dialog.dart
└── matchs/
    ├── matchs_tab.dart
    ├── schedule_match_dialog.dart
    └── validate_score_dialog.dart
```

**Semaine 11** :
```
lib/features/
├── admin/
│   ├── classement/
│   │   └── classement_tab.dart
│   └── tournois/
│       ├── tournois_tab.dart
│       ├── create_tournament_dialog.dart
│       └── bracket_widget.dart
└── player/
    └── mes_matchs/
        ├── mes_matchs_screen.dart
        └── submit_score_dialog.dart
```

---

## 🔍 Recherche Rapide

**Trouver un fichier** :
```powershell
# Modèle AppUser
lib/domain/models/app_user.dart

# Service authentification
lib/data/services/auth_service.dart

# Écran login
lib/features/auth/login_screen.dart

# Config API
lib/core/config/api_config.dart

# Backend - Login controller
backend/PadelChampionship.Api/Controllers/AuthController.cs

# Documentation architecture
ARCHITECTURE.md
```

**Importer dans un fichier Dart** :
```dart
// Importer tous les modèles
import 'package:flutter_application_1/domain/domain.dart';

// Importer tous les services
import 'package:flutter_application_1/data/services/services.dart';

// Importer config API
import 'package:flutter_application_1/core/config/api_config.dart';
```

---

**Structure maintenue à jour - Semaine 9**
