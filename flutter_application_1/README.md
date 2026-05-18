# Application Mobile de Gestion de Championnat de Padel

Ce dépôt contient une base Flutter fonctionnelle (MVP) conforme à ton cahier des charges, prête à être connectée à un backend REST.

## État actuel (implémenté)

Fonctionnalités Flutter déjà livrées dans `lib/main.dart` :

- Authentification (admin / joueur)
- Gestion joueurs (ajout, blocage, suppression, mise à jour niveau)
- Gestion équipes (création avec vérification de compatibilité des niveaux)
- Gestion matchs (planification, saisie score, validation admin, correction manuelle)
- Règle délai 24h (sinon forfait)
- Calcul classement individuel automatique (points, victoires, défaites, diff sets)
- Top 3 mensuel + récompenses
- Gestion tournois (quart, demi, finale, vainqueur)
- Gestion clubs (structure de données intégrée)

## Accès de démonstration

- Admin : `admin@padel.com` / `Admin123!`
- Joueur : `ali@padel.com` / `Player123!`

## Lancer l’application

```bash
flutter pub get
flutter run
```

## Architecture cible recommandée

### Frontend
- Flutter (Android + iOS)
- Architecture en couches :
	- Présentation (UI)
	- Métier (use cases, règles de points, classement)
	- Données (API REST, stockage local)

### Backend
Stack choisie : **ASP.NET Core + MySQL**.

Le backend est initialisé dans :
- `backend/PadelChampionship.Api`

Le mode par défaut est `InMemory` pour démarrage rapide, avec bascule possible vers MySQL via `appsettings.json`.

### Base de données
- MySQL
- Tables principales : Utilisateur, Équipe, Match, Participation, TestTechnique, Récompense, Club, Tournoi

## Plan de travail professionnel (3 mois)

## Mois 1 — Analyse & Conception

### Semaine 1
- Finaliser périmètre (MVP V1)
- Valider les règles métier (points, tie-break, forfait, validation score)
- Backend validé : ASP.NET Core

### Semaine 2
- Rédiger cas d’utilisation (Admin / Joueur)
- Produire diagrammes UML (Use Case + Séquence)
- Définir contrats API (Swagger / OpenAPI)

### Semaine 3
- Concevoir schéma MySQL (avec contraintes et index)
- Définir stratégie sécurité (hash mot de passe, JWT, rôles)

### Semaine 4
- Valider maquettes UI principales
- Préparer backlog sprint Mois 2

## Mois 2 — Backend

### Semaine 5-6
- Développer Auth (`/auth/login`, JWT, rôles)
- CRUD Joueurs, Équipes, Clubs

### Semaine 7
- API Matchs (planification, saisie, validation, correction admin)
- Implémenter règle 24h et forfait

### Semaine 8
- API Classement et Récompenses mensuelles
- API Tournois (bracket quart/demi/finale)
- Tests unitaires backend

## Mois 3 — Frontend & Finalisation

### Semaine 9
- Refactor Flutter en dossiers (`features/`, `core/`, `data/`, `domain/`)
- Brancher authentification réelle (API)

### Semaine 10
- Intégrer modules Joueurs / Équipes / Matchs
- États de chargement, erreurs, validation formulaires

### Semaine 11
- Intégrer Classement / Récompenses / Tournois / Clubs
- Historique et statistiques équipe/joueur

### Semaine 12
- Tests fonctionnels E2E
- Optimisation performance (<3s)
- Préparation démo + documentation finale

## Backlog MVP V1 (priorité)

1. Auth sécurisée + rôles
2. Joueurs + niveaux + historique test
3. Équipes + compatibilité niveau
4. Matchs + validation admin + forfait
5. Classement individuel automatique
6. Top 3 mensuel + récompenses
7. Tournoi simple (8 joueurs)

## Sécurité minimale attendue

- Hash mot de passe côté backend (BCrypt/Argon2)
- JWT avec expiration + refresh
- Contrôle d’accès par rôle sur chaque endpoint
- Validation stricte des entrées
- Journalisation des actions admin

## Prochaine étape recommandée

1. Extraire le code Flutter actuel en architecture modulaire (`lib/features/...`).
2. Créer le backend REST (stack unique choisie).
3. Connecter Flutter aux API réelles (remplacer service en mémoire).

Si tu veux, je peux maintenant te générer directement la **version modulaire propre de Flutter** (dossiers `features/auth`, `features/matchs`, etc.) et te préparer les interfaces API prêtes pour ton backend.
