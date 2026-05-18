# PadelChampionship.Api (ASP.NET Core)

Backend REST pour l'application Flutter de gestion de championnat de padel.

## Prérequis

- .NET SDK 8.0+
- (Optionnel) MySQL 8+

## Lancement rapide (mode InMemory)

1. Installer .NET SDK: https://dotnet.microsoft.com/download
2. Depuis le dossier `backend/PadelChampionship.Api` :

```bash
dotnet restore
dotnet run
```

3. Swagger : `https://localhost:xxxx/swagger`

Par défaut `UseInMemoryDatabase=true` dans `appsettings.json`, donc MySQL n'est pas obligatoire pour démarrer.

## Passage à MySQL

Dans `appsettings.json` :

- `UseInMemoryDatabase`: `false`
- Configurer `ConnectionStrings:DefaultConnection`

Le profil `appsettings.Production.json` active déjà ce mode. Il suffit donc de lancer le backend avec `ASPNETCORE_ENVIRONMENT=Production` pour charger la configuration MySQL.

Sur cette machine, MariaDB est installé localement avec l’utilisateur `root` sans mot de passe.

Au démarrage, l'application appelle `Database.EnsureCreatedAsync()` pour créer automatiquement le schéma MySQL si la base est vide. Le seed de démonstration est ensuite appliqué une seule fois.

Si tu veux une stratégie 100% migrations EF Core plus tard, tu peux remplacer `EnsureCreatedAsync()` par `MigrateAsync()` après avoir généré une première migration.

## Configuration serveur déploiement

Pour une configuration reproductible en production:

1. Utiliser `appsettings.Production.Template.json` comme base (ne pas y laisser de secrets réels).
2. Injecter les secrets via variables d'environnement:
	- `ASPNETCORE_ENVIRONMENT=Production`
	- `ConnectionStrings__DefaultConnection=...`
	- `Jwt__Key=...`
3. Publier puis lancer le binaire de release (`dotnet publish -c Release`).

Guide détaillé Windows Server: `deploy/windows-server.md`.

## Comptes seed

- Admin: `admin@padel.com` / `Admin123!`
- Joueur: `ali@padel.com` / `Player123!`

## Endpoints principaux

### Auth
- `POST /api/auth/login`

### Joueurs (Admin)
- `GET /api/players`
- `POST /api/players`
- `PUT /api/players/{id}/level`
- `PUT /api/players/{id}/block`
- `PUT /api/players/{id}/unblock`
- `DELETE /api/players/{id}`

### Équipes
- `GET /api/teams` (auth)
- `POST /api/teams` (Admin)
- `DELETE /api/teams/{id}` (Admin)

### Matchs
- `GET /api/matches` (auth)
- `POST /api/matches/schedule` (Admin)
- `POST /api/matches/{id}/submit-score` (auth)
- `POST /api/matches/{id}/validate` (Admin)

### Classement / récompenses
- `GET /api/standings/players` (auth)
- `POST /api/standings/monthly-top3` (Admin)

### Tournois
- `GET /api/tournaments` (auth)
- `POST /api/tournaments` (Admin)
- `POST /api/tournaments/{id}/winner` (Admin)

### Clubs
- `GET /api/clubs` (auth)
- `POST /api/clubs` (Admin)

## Intégration Flutter

Configurer l'URL API dans Flutter selon l'émulateur:

- Android Emulator: `http://10.0.2.2:5000` (ou port Kestrel)
- iOS Simulator: `http://localhost:5000`
- Device physique: `http://<IP_PC>:5000`

Flow recommandé:
1. `POST /api/auth/login`
2. stocker le JWT
3. envoyer `Authorization: Bearer <token>` pour toutes les routes protégées
