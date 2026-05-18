# Diagramme de classe corrige (100% aligne au code)

Ce document est strictement base sur les classes existantes dans le projet.
Il ne contient pas de classes conceptuelles ajoutees.

## 1) Domaine backend exact

Source: backend/PadelChampionship.Api/Models/Entities.cs

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

  Club "1" --> "0..*" User : Joueurs
  Club "1" --> "0..*" Tournament : Tournois

  Team "1" --> "0..*" TeamPlayer
  User "1" --> "0..*" TeamPlayer

  ChampionshipMatch "*" --> "1" Team : Equipe1
  ChampionshipMatch "*" --> "1" Team : Equipe2

  User "1" --> "0..*" Participation
  ChampionshipMatch "1" --> "0..*" Participation

  User "1" --> "0..*" TechnicalTest
  User "1" --> "0..*" Reward

  Tournament "1" --> "0..*" TournamentMatch

  User --> UserRole
  User --> UserStatus
  ChampionshipMatch --> MatchStatus
  TournamentMatch --> TournamentRound
```

## 2) Mapping Flutter exact

Source: lib/domain/models/

```mermaid
classDiagram
  direction LR

  class AppUser {
    +int id
    +String nom
    +String email
    +String password
    +UserRole role
    +int niveau
    +UserStatus status
    +int? clubId
  }

  class Club {
    +int id
    +String nom
    +String localisation
  }

  class Team {
    +int id
    +String nom
    +List~int~ playerIds
  }

  class MatchEntry {
    +int id
    +DateTime date
    +String terrain
    +int equipe1Id
    +int equipe2Id
    +MatchStatus status
    +MatchScore? scoreEquipe1
    +MatchScore? scoreEquipe2
    +MatchScore? scoreValide
  }

  class MatchScore {
    +int setsEquipe1
    +int setsEquipe2
  }

  class Tournament {
    +int id
    +String nom
    +DateTime date
    +List~int~ playerIds
    +List~TournamentMatch~ matches
  }

  class TournamentMatch {
    +int id
    +TournamentRound round
    +int joueur1
    +int joueur2
    +int? vainqueur
  }

  class PlayerStanding
  class ClubStanding
  class PlayerStats
  class Reward
  class NiveauHistory

  MatchEntry --> MatchScore
  Tournament --> TournamentMatch

  AppUser ..> User : mapping
  Team ..> Team : mapping (+TeamPlayer)
  MatchEntry ..> ChampionshipMatch : mapping
  Tournament ..> Tournament : mapping
  TournamentMatch ..> TournamentMatch : mapping
  NiveauHistory ..> TechnicalTest : mapping
  Reward ..> Reward : mapping
  PlayerStanding ..> User : DTO
  ClubStanding ..> Club : DTO
  PlayerStats ..> User : DTO
```

## 3) Ce qui a ete retire car absent du code actuel

- InscriptionTournoi
- SaisieResultat
- ResultatValide
- AttributionPoints
- ClassementGeneral et LigneClassementGeneral
- ClassementMensuel et LigneClassementMensuel

Ces concepts existent dans la logique metier, mais ne sont pas modeles comme classes autonomes dans les fichiers actuels.
