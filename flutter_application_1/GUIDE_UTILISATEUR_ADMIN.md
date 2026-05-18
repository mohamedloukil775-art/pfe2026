# Guide Utilisateur Admin

Ce guide explique les actions quotidiennes de l administrateur dans l application Padel Championship.

## 1. Connexion

1. Ouvrir l application.
2. Saisir les identifiants admin.
3. Cliquer sur Se connecter.

Compte de test:

- Email: admin@padel.com
- Mot de passe: Admin123!

## 2. Tableau de bord admin

Apres connexion, l administrateur accede aux onglets suivants:

- Joueurs
- Equipes
- Matchs
- Classement
- Tournois

## 3. Gestion des joueurs

Depuis l onglet Joueurs:

- Ajouter un joueur:
  - Cliquer Ajouter joueur
  - Renseigner nom, email, mot de passe, niveau
  - Valider
- Modifier le niveau:
  - Cliquer Niveau sur la ligne du joueur
  - Choisir le nouveau niveau
  - Confirmer
- Bloquer / Debloquer:
  - Cliquer Bloquer ou Debloquer
  - Confirmer l action
- Supprimer:
  - Cliquer Supprimer
  - Confirmer l action

Bonnes pratiques:

- Verifier l email avant creation.
- Eviter de supprimer un joueur actif en cours de competition.

## 4. Gestion des equipes

Depuis l onglet Equipes:

- Creer une equipe:
  - Cliquer Creer equipe
  - Selectionner 2 joueurs
  - Donner un nom a l equipe
  - Valider
- Modifier une equipe:
  - Cliquer Modifier
  - Adapter le nom et/ou les joueurs
  - Valider
- Supprimer une equipe:
  - Cliquer Supprimer
  - Confirmer

## 5. Gestion des matchs

Depuis l onglet Matchs:

- Planifier un match:
  - Cliquer Planifier match
  - Choisir Equipe 1, Equipe 2, terrain et date
  - Valider
- Filtrer les matchs:
  - Utiliser Filtrer par statut (Programme, Resultat saisi, Valide, Forfait)
- Valider un score:
  - Sur un match en Resultat saisi, cliquer Valider score
  - Confirmer les sets
- Supprimer un match:
  - Cliquer Supprimer puis confirmer

## 6. Classement et recompenses

Depuis l onglet Classement:

- Consulter le classement global (points, victoires, defaites, diff sets)
- Consulter le Top 3 mensuel et les recompenses associees

## 7. Gestion des tournois

Depuis l onglet Tournois:

- Creer un tournoi:
  - Cliquer Creer tournoi
  - Renseigner nom + date
  - Selectionner exactement 8 joueurs actifs
  - Valider
- Definir les vainqueurs:
  - Pour chaque match du bracket, cliquer Definir vainqueur
  - Choisir le joueur gagnant
  - Confirmer

## 8. Messages et erreurs

- Les confirmations s affichent en bas de l ecran (SnackBar)
- En cas d erreur API:
  - Verifier la connexion reseau
  - Verifier que le backend est actif
  - Reessayer via le bouton Reessayer ou le pull to refresh

## 9. Deconnexion

- Utiliser le bouton de deconnexion depuis l interface principale.
- La session JWT est supprimee et l application revient a l ecran de connexion.
