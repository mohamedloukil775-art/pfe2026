# Diagramme de Classe - Championnat Padel

Ce document contient une version de travail du diagramme de classe, derivee directement des classes du projet.

## 1) Domaine Backend (source de verite metier)

```mermaid
classDiagram
  direction LR

  class User {
    +int Id
    +string Nom
    +string Email
    +string MotDePasseHash
    +UserRole Role
    +int Niveau
    +UserStatus Statut
    +int? ClubId
  }

  class Club {
    +int Id
    +string Nom
    +string Localisation
  }

  class Team {
    +int Id
    +string NomEquipe
    +int PointsTotal
  }

  class TeamPlayer {
    +int TeamId
    +int UserId
  }

  class ChampionshipMatch {
    +int Id
    +DateTime Date
    +string Terrain
    +int Equipe1Id
    +int Equipe2Id
    +int? ScoreEquipe1
    +int? ScoreEquipe2
    +MatchStatus Statut
  }

  class Participation {
    +int Id
    +int JoueurId
    +int MatchId
    +int PointsObtenus
  }

  class TechnicalTest {
    +int Id
    +int JoueurId
    +DateTime DateTest
    +int ScoreTest
    +int NiveauAttribue
  }

  class Reward {
    +int Id
    +string Mois
    +int JoueurId
    +string TypeCadeau
  }

  class Tournament {
    +int Id
    +string Nom
    +int ClubId
  }

  class TournamentMatch {
    +int Id
    +TournamentRound Round
    +int Joueur1Id
    +int Joueur2Id
    +int? VainqueurId
    +int TournamentId
  }

  class UserRole {
    <<enumeration>>
    Admin
    Joueur
  }

  class UserStatus {
    <<enumeration>>
    Actif
    Bloque
  }

  class MatchStatus {
    <<enumeration>>
    Programme
    ResultatSaisi
    Valide
    Forfait
  }

  class TournamentRound {
    <<enumeration>>
    Quart
    Demi
    Finale
  }

  Club "1" --> "0..*" User : joueurs
  Club "1" --> "0..*" Tournament : organise

  Team "1" --> "0..*" TeamPlayer
  User "1" --> "0..*" TeamPlayer

  TeamPlayer "*" --> "1" Team
  TeamPlayer "*" --> "1" User

  ChampionshipMatch "*" --> "1" Team : equipe1
  ChampionshipMatch "*" --> "1" Team : equipe2

  User "1" --> "0..*" Participation
  ChampionshipMatch "1" --> "0..*" Participation

  User "1" --> "0..*" TechnicalTest
  User "1" --> "0..*" Reward

  Tournament "1" --> "0..*" TournamentMatch
  TournamentMatch "*" --> "1" Tournament

  User --> UserRole
  User --> UserStatus
  ChampionshipMatch --> MatchStatus
  TournamentMatch --> TournamentRound
```

## 2) Mapping Flutter <-> Backend

Ce schema montre comment les modeles Flutter representent les entites backend.

```mermaid
classDiagram
  direction LR

  class AppUser
  class Club
  class Team
  class MatchEntry
  class MatchScore
  class Tournament
  class TournamentMatch
  class PlayerStanding
  class ClubStanding
  class PlayerStats
  class Reward
  class NiveauHistory

  class User
  class ChampionshipMatch
  class TechnicalTest

  AppUser ..> User : mapping
  Club ..> Club : mapping direct
  Team ..> Team : mapping (+ TeamPlayer)
  MatchEntry ..> ChampionshipMatch : mapping
  MatchScore ..> ChampionshipMatch : score logique
  Tournament ..> Tournament : mapping
  TournamentMatch ..> TournamentMatch : mapping
  Reward ..> Reward : mapping
  NiveauHistory ..> TechnicalTest : mapping

  PlayerStanding ..> User : DTO calcule
  ClubStanding ..> Club : DTO calcule
  PlayerStats ..> User : DTO calcule
```

## 3) Fichiers de reference

- Backend entites: backend/PadelChampionship.Api/Models/Entities.cs
- Backend enums: backend/PadelChampionship.Api/Models/Enums.cs
- Relations EF Core: backend/PadelChampionship.Api/Data/ApplicationDbContext.cs
- Modeles Flutter: lib/domain/models/

## 4) Pistes d'amelioration

- Ajouter les DTOs (CreatePlayerDto, ScoreDto, etc.) si vous voulez un diagramme technique API.
- Ajouter les services (AuthService, PlayersService, ...) si vous voulez un diagramme d'architecture objet.
- Transformer TeamPlayer en relation n-n explicite au niveau frontend (pas seulement List<int> playerIds).
