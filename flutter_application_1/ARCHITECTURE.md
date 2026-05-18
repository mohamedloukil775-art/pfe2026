# 📐 Architecture Technique - Championnat Padel

## Vue d'ensemble

```
Flutter App (Mobile)  <--HTTP/JWT-->  ASP.NET Core API  <--EF Core-->  MySQL/InMemory
     (Dart)                                  (C#)                        (Database)
```

---

## Architecture Flutter (Clean Architecture)

### Couches

```
┌─────────────────────────────────────────────────┐
│                  PRESENTATION                    │
│  (features/auth, features/admin, features/player)│
│              UI Components + Screens             │
└─────────────────────────────┬───────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────┐
│                    DOMAIN                        │
│  (domain/models, domain/enums)                  │
│        Business Models + Enums                   │
└─────────────────────────────┬───────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────┐
│                     DATA                         │
│  (data/services)                                │
│   API Services + API Calls                       │
└─────────────────────────────┬───────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────┐
│                     CORE                         │
│  (core/config, core/storage, core/exceptions)   │
│   Configuration + Utilitaires                    │
└─────────────────────────────────────────────────┘
```

### Flux de données

**Login Example:**
```
LoginScreen (UI)
    ↓ appel
AuthService.login(email, password)
    ↓ HTTP POST
Backend /api/auth/login
    ↓ JWT token
TokenStorage.saveToken()
    ↓ navigation
AdminHomeScreen / PlayerHomeScreen
```

---

## Architecture Backend (ASP.NET Core)

### Couches

```
┌─────────────────────────────────────────────────┐
│                  CONTROLLERS                     │
│     (AuthController, PlayersController, etc.)   │
│           Endpoints REST API + Routing           │
└─────────────────────────────┬───────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────┐
│                    SERVICES                      │
│              (JwtTokenService)                   │
│            Business Logic Layer                  │
└─────────────────────────────┬───────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────┐
│                     DATA                         │
│           (ApplicationDbContext)                 │
│              EF Core DbContext                   │
└─────────────────────────────┬───────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────┐
│                    MODELS                        │
│  (Entities.cs: User, Team, Match, Tournament)   │
│              Domain Entities + DTOs              │
└─────────────────────────────────────────────────┘
```

### Middleware Pipeline

```
HTTP Request
    ↓
CORS Policy (AllowAnyOrigin)
    ↓
Authentication (JWT Bearer)
    ↓
Authorization ([Authorize] attribute)
    ↓
Controller Action
    ↓
Service Layer
    ↓
Database (EF Core)
    ↓
Response (JSON)
```

---

## Modèles de Données

### Modèles principaux Flutter↔Backend

| Flutter Model      | Backend Entity       | Description                    |
|--------------------|----------------------|--------------------------------|
| AppUser            | User                 | Utilisateur (admin/joueur)     |
| Team               | Team + TeamPlayer    | Équipe (2 joueurs)             |
| Club               | Club                 | Club de padel                  |
| MatchEntry         | ChampionshipMatch    | Match championnat              |
| MatchScore         | (embedded in Match)  | Score par équipe               |
| Tournament         | Tournament           | Tournoi 8 joueurs              |
| TournamentMatch    | TournamentMatch      | Match de tournoi               |
| PlayerStanding     | (DTO calculated)     | Classement joueur              |
| Reward             | Reward               | Récompense top 3               |
| NiveauHistory      | TechnicalTest        | Historique niveau joueur       |

### Relations clés (Backend)

```
User (1) ────┬───── (N) TeamPlayer ────── (1) Team
             │
             ├───── (N) TechnicalTest
             │
             └───── (N) Participation ────── (1) ChampionshipMatch

Team (1) ────┼───── (N) ChampionshipMatch (equipe1)
             └───── (N) ChampionshipMatch (equipe2)

Tournament (1) ────── (N) TournamentMatch
```

---

## API Endpoints

### Authentification
```http
POST   /api/auth/login             # Login (retourne JWT token)
```

### Joueurs (Admin uniquement)
```http
GET    /api/players                # Liste tous les joueurs
POST   /api/players                # Créer un joueur
PUT    /api/players/{id}/niveau    # Mettre à jour niveau
PUT    /api/players/{id}/bloquer   # Bloquer un joueur
PUT    /api/players/{id}/debloquer # Débloquer un joueur
DELETE /api/players/{id}           # Supprimer un joueur
```

### Équipes (Admin uniquement)
```http
GET    /api/teams                  # Liste toutes les équipes
POST   /api/teams                  # Créer une équipe
DELETE /api/teams/{id}             # Supprimer une équipe
```

### Matchs
```http
GET    /api/matches                             # Liste tous les matchs
POST   /api/matches                             # Planifier un match (Admin)
POST   /api/matches/{id}/saisir-score          # Saisir score (Any authenticated)
POST   /api/matches/{id}/valider               # Valider score (Admin)
DELETE /api/matches/{id}                        # Supprimer match (Admin)
```

### Classement
```http
GET    /api/standings              # Classement complet
GET    /api/standings/top3         # Top 3 du mois
```

### Tournois (Admin uniquement)
```http
GET    /api/tournaments                              # Liste tournois
POST   /api/tournaments                              # Créer tournoi
GET    /api/tournaments/{id}/matchs                  # Matchs du tournoi
PUT    /api/tournaments/{id}/matchs/{mid}/vainqueur # Définir vainqueur
```

### Clubs
```http
GET    /api/clubs                  # Liste clubs
POST   /api/clubs                  # Créer club (Admin)
```

---

## Sécurité

### Authentification JWT

**Flow:**
```
1. Client → POST /api/auth/login {email, password}
2. Backend → Vérification BCrypt du hash
3. Backend → Génération JWT (8h expiration)
4. Backend → Response {token, utilisateur}
5. Client → Sauvegarde token (flutter_secure_storage)
6. Client → Toutes requêtes suivantes: Header "Authorization: Bearer {token}"
7. Backend → Validation JWT + extraction claims (userId, role)
8. Backend → Exécution action si autorisé
```

**JWT Claims:**
```json
{
  "sub": "userId",
  "email": "user@example.com",
  "role": "Admin|Joueur",
  "exp": 1234567890
}
```

### Autorisation par rôle

```csharp
[Authorize(Roles = "Admin")]     // Admin uniquement
[Authorize]                       // Tout utilisateur authentifié
[AllowAnonymous]                  // Accès public
```

### Hachage des mots de passe

```csharp
// Création utilisateur
string passwordHash = BCrypt.Net.BCrypt.HashPassword(plainPassword);

// Vérification
bool isValid = BCrypt.Net.BCrypt.Verify(plainPassword, storedHash);
```

---

## Configuration

### Flutter - ApiConfig

```dart
// lib/core/config/api_config.dart
static const String baseUrl = 'http://localhost:5000/api';  // À adapter
```

**Environnements:**
- Android Emulator: `http://10.0.2.2:5000/api`
- iOS Simulator: `http://localhost:5000/api`
- Appareil physique: `http://192.168.x.x:5000/api`

### Backend - appsettings.json

```json
{
  "UseInMemoryDatabase": true,  // false pour MySQL
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=PadelChampionship;..."
  },
  "JwtSettings": {
    "SecretKey": "VotreCleSecrete...",
    "Issuer": "PadelChampionshipApi",
    "Audience": "PadelChampionshipClient",
    "ExpirationHours": 8
  }
}
```

---

## Règles Métier Implémentées

### 1. Gestion des niveaux
- Niveau joueur: 1-10
- Catégories: Débutant (1-3), Intermédiaire (4-6), Avancé (7-8), Expert (9-10)
- Équipe: max 2 niveaux d'écart entre joueurs

### 2. Matchs
- Règle forfait: Si >24h après date match et aucun score → statut "Forfait"
- Double saisie: Les 2 équipes saisissent le score
- Validation admin: Admin valide le score final
- Correction: Admin peut corriger manuellement

### 3. Points et classement
- Victoire: +3 points
- Défaite: 0 points
- Tri: 1) Points, 2) Victoires, 3) Différence de sets

### 4. Top 3 mensuel
- Génère automatiquement les 3 meilleurs joueurs du mois
- Crée des entités Reward (position 1, 2, 3)

### 5. Tournois
- Exactement 8 joueurs
- Bracket: Quart (4 matchs) → Demi (2 matchs) → Finale (1 match)
- Avancement automatique du vainqueur au tour suivant

---

## Technologies

### Frontend
- **Framework**: Flutter 3.9+
- **Language**: Dart
- **UI**: Material Design 3
- **HTTP**: package:http 1.2.0
- **Storage**: flutter_secure_storage 9.0.0
- **State**: Stateful widgets (futur: Provider/Riverpod)

### Backend
- **Framework**: ASP.NET Core 8.0
- **Language**: C# 12
- **ORM**: Entity Framework Core 8.0.8
- **Database**: MySQL 8+ / InMemory
- **Auth**: JWT Bearer
- **Password**: BCrypt.Net-Next 4.0.3
- **API Doc**: Swagger/OpenAPI

---

## Prochaines Améliorations (Semaines 10-12)

### Semaine 10
- [ ] Implémenter onglets admin avec services API
- [ ] Gestion d'état centralisée (Provider/Riverpod)
- [ ] Formulaires de création/modification

### Semaine 11
- [ ] Interface joueur complète
- [ ] Historique et statistiques
- [ ] Notifications push (Firebase)

### Semaine 12
- [ ] Tests E2E (integration_test)
- [ ] Optimisation performance (<3s chargement)
- [ ] Migration MySQL production
- [ ] CI/CD pipeline

---

**Document mis à jour : Semaine 9 terminée**
