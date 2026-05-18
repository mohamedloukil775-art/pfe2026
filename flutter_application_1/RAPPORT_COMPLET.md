# Rapport complet - PadelChampionship

> Version rassemblée automatiquement à partir des fichiers du projet.

## Table des matières

Voir [TABLE_DES_MATIERES.md](TABLE_DES_MATIERES.md) pour la table des matières et la numérotation indicative.

---

# Introduction Générale

(PAGE 1)

Le projet "PadelChampionship" vise à fournir une plate-forme numérique complète pour la gestion des compétitions de padel. Il combine une application mobile multiplateforme développée en Flutter et un backend RESTful en ASP.NET Core. L'objectif est d'offrir aux administrateurs des outils de gestion (joueurs, équipes, matchs, tournois, classements) et aux joueurs une interface simple pour consulter leur calendrier, saisir des résultats et suivre leur progression.

Le présent rapport documente le contexte, l'analyse des besoins, la conception logicielle, l'implémentation technique, ainsi que les guides d'installation et d'utilisation.

---

# 1. Étude préalable

(PAGE 3)

## 1.1 Introduction

Cette section présente le contexte sportif et technique ayant motivé le développement de la plate-forme. Le secteur des clubs amateurs et semi-professionnels manque d'outils accessibles pour gérer tournois, calendriers et classements. Le projet répond à ce besoin en proposant un système simple, sécurisé et multi-plateforme.

## 1.2 Présentation de l'organisme d'accueil

Le projet a été réalisé pour un club local de padel souhaitant numériser la gestion des compétitions internes et des tournois ouverts. L'organisme fournit les données de test (joueurs, clubs, calendriers) et accompagne la validation fonctionnelle.

## 1.3 Présentation du projet

Le projet consiste en une application mobile Flutter et un backend ASP.NET Core. Le périmètre couvre : gestion des utilisateurs (admin/joueur), création et gestion des tournois, planification et saisie des résultats, calcul automatique des classements, et génération du top 3 mensuel.

### 1.3.1 Cadre du projet

Livrables : code source frontend et backend, documentation technique, guides d'installation et d'utilisation, maquettes et diagrammes UML.

### 1.3.2 Problématique

Permettre aux administrateurs de gérer efficacement des compétitions tout en offrant aux joueurs une expérience fluide pour consulter et saisir les résultats, avec une exigence de sécurité (authentification JWT, hash des mots de passe) et de portabilité multi-plateformes.

### 1.3.3 Étude de l'existant

Les solutions existantes sont souvent orientées vers de grands opérateurs ou nécessitent des abonnements. Une solution locale, légère et personnalisée est préférable pour les clubs.

#### 1.3.3.1 Solutions existantes

Analyse rapide des plateformes grand public (systèmes de gestion de tournois, feuilles de calcul partagées, applications propriétaires) : coût, complexité et limitations d'intégration.

#### 1.3.3.2 Critique de l'existant

Limitations : manque de personnalisation, coût, incompatibilités mobiles, et absence d'API ouvertes pour intégration continue.

### 1.3.4 Solution proposée

Proposition : une application mobile Flutter connectée à une API REST en ASP.NET Core, avec stockage en InMemory pour prototypage et MySQL pour production. Fonctionnalités modulaires et extensibles.

## 1.4 Conclusion

L'étude préalable confirme la pertinence d'une solution personnalisée et guide le choix technologique (Flutter pour la portabilité, .NET pour la robustesse backend). Le projet se focalise sur un MVP opérationnel couvrant les principales fonctions de gestion de compétitions.

---

# 2. Analyse et conception

(PAGE 12)

## 2.1 Introduction

La phase d'analyse formalise les besoins fonctionnels et non fonctionnels, identifie les acteurs et définit les cas d'utilisation qui serviront de base à la conception technique et aux tests.

## 2.2 Identification des acteurs

- Administrateur : gestion complète des ressources (joueurs, équipes, matchs, tournois).
- Joueur : consultation de son espace, saisie de résultats, consultation du classement.
- Système : services backend, calculs automatiques (classements, top 3).

## 2.3 Identification des besoins fonctionnels

- Authentification et gestion des sessions (JWT).
- CRUD joueurs, équipes, clubs.
- Planification et gestion des matchs.
- Saisie et validation des résultats.
- Calcul automatique des classements et génération du top 3 mensuel.
- Création et gestion de tournois (bracket 8 joueurs).

## 2.4 Identification des besoins non fonctionnels

- Sécurité : hachage des mots de passe (BCrypt), tokens JWT avec expiration.
- Performance : réponses API < 1s en conditions normales.
- Disponibilité multi-plateforme (Android, iOS, Web, Desktop).
- Maintenabilité : architecture modulaire, tests unitaires et intégration.

## 2.5 Langage de modélisation

UML est utilisé pour documenter les cas d'utilisation, les classes et les séquences d'interaction.

## 2.6 Diagramme de cas d'utilisation

Les cas d'utilisation principaux sont : consulter plateforme, s'authentifier, créer un compte, gérer profil, créer un tournoi, inscrire un joueur, créer un match, enregistrer des résultats, consulter les classements.

## 2.7 Descriptions textuelles des cas d'utilisation

Chaque scénario est décrit par son acteur principal, les pré-conditions, le flux principal et les flux alternatifs (voir `TABLE_DES_MATIERES.md`). Ces descriptions alimentent la conception des API et des écrans.

## 2.8 Diagramme de classe

Le diagramme de classe formalise les entités : User, Team, Match, Tournament, Club, Reward, TechnicalTest, et leurs relations. Le modèle est implémenté côté backend (EF Core) et côté frontend (Dart models).

## 2.9 Diagrammes de séquence

Les séquences documentent l'échange entre client et serveur pour les scénarios critiques : authentification (login → token), création de match (client → API → base), saisie et validation de scores (double-saisie puis validation admin).

## 2.10 Conclusion

La conception garantit une séparation claire des responsabilités et facilite l'évolution : le frontend consomme des API stables tandis que la logique métier (classements, règles de forfait) réside côté backend.

---

# 3. Réalisation

(PAGE 44)

## 3.1 Introduction

Cette partie décrit le travail d'implémentation effectué : refactoring du frontend, création des services API, développement des contrôleurs backend et rédaction des guides d'installation et d'utilisation.

## 3.2 Étude technique et architecture

Le choix technologique a été guidé par la portabilité et la robustesse : Flutter permet d'atteindre plusieurs plateformes à partir d'un seul codebase, tandis que .NET Core offre un backend structuré et performant. L'architecture suit une séparation en couches (presentation/domain/data/core) en frontend et controllers/services/data/models en backend.

### Environnements logiciels et outils utilisés

- Visual Studio Code, Visual Studio Community
- Postman pour tests API
- Git pour gestion de versions
- Visual Paradigm UML pour diagrammes
- Flutter DevTools pour débogage

### Services utilisés

- MySQL (production) / InMemory (développement)
- BCrypt pour hachage des mots de passe
- JWT pour authentification
- Entity Framework Core pour accès aux données

### Langages et technologies

- C# / .NET 8 pour le backend
- Dart / Flutter pour le frontend
- REST API pour communication

## 3.3 Architecture logicielle

L'architecture frontend est modulaire : `core`, `domain`, `data`, `features`. Le backend sépare contrôleurs, services métier, context EF et DTOs. Les API sont documentées via Swagger.

## 3.4 Description du travail réalisé

Au niveau frontend : refactorisation en modules, services HTTP pour chaque ressource (Auth, Players, Teams, Matches, Standings, Tournaments, Clubs), écrans de base (login, admin home, player home).

Au niveau backend : implémentation de 7 contrôleurs REST, configuration JWT, seed data pour comptes de test, et DTOs pour échanges sécurisés.

### Interfaces administrateur

Fonctionnalités implémentées : gestion complète des joueurs, équipes, matchs et tournois; tableau de bord; actions de validation et correction des scores.

### Interfaces joueur

Fonctionnalités implémentées : consultation des matchs, saisie des résultats, visualisation du classement et historique.

### Interface gestion des matchs

Planification des matchs, double saisie des résultats, règles de validation (admin) et règle de forfait après 24h sans score.

### Classement et statistiques

Calcul automatisé des points, génération du top 3 mensuel et export sommaire des statistiques individuelles.

## 3.5 Conclusion

La réalisation aboutit à un MVP fonctionnel et modulaire, prêt à être testé en environnement réel et à être étendu (tests E2E, passage MySQL, interface avancée pour tournois).

---

# Guides et annexes

## Guide de démarrage

Contenu extrait et résumé de `GUIDE_DEMARRAGE.md` : installation du SDK .NET, instructions pour lancer le backend, configuration des URL API dans Flutter et comptes tests.

## Guide utilisateur admin

Extrait de `GUIDE_UTILISATEUR_ADMIN.md` avec procédures : ajout/modification/bloquage de joueurs, gestion équipes, planification matchs, validation des scores.

## Guide utilisateur joueur

Extrait de `GUIDE_UTILISATEUR_JOUEUR.md` décrivant connexion, consultation des matchs, saisie des scores et bonnes pratiques.

## Changelog

Résumé des modifications et du refactoring (voir `CHANGELOG.md`).

---

# Liste des figures

Consulter la section correspondante dans `TABLE_DES_MATIERES.md` pour la liste complète et la numérotation indicative.

---

# Annexes techniques

- `backend/PadelChampionship.Api/README.md` (documentation endpoints backend)
- `DIAGRAMME_CLASSE.md`, `DIAGRAMME_CLASSE_CORRIGE.md`, `DIAGRAMME_CLASSE_SOUTENANCE.md` (diagrammes UML)
- `STRUCTURE.md` (structure du projet)

---

# Notes

- Le fichier rassemble automatiquement le contenu existant. Certaines sections peuvent encore être enrichies par des captures d'écran, des tables détaillées et des numéros de page finaux.

- Les numéros de pages dans `TABLE_DES_MATIERES.md` restent indicatifs et devront être ajustés lors de la mise en page finale (PDF/Word).

---

_Fin du rapport rassemblé automatiquement._
