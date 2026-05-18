# Deployment Backend (Windows Server)

Ce guide configure `PadelChampionship.Api` en mode Production sur Windows Server.

## 1. Prerequis

- .NET SDK 8.0+ (ou Runtime ASP.NET Core 8.0)
- MariaDB/MySQL accessible depuis le serveur
- Pare-feu ouvert sur le port API (ex: 5000)

## 2. Publication backend

Depuis `backend/PadelChampionship.Api`:

```powershell
 dotnet restore
 dotnet publish -c Release -o .\publish
```

## 3. Variables d'environnement Production

Configurer les variables systeme (recommande) ou utilisateur:

```powershell
[System.Environment]::SetEnvironmentVariable('ASPNETCORE_ENVIRONMENT', 'Production', 'Machine')
[System.Environment]::SetEnvironmentVariable('ConnectionStrings__DefaultConnection', 'server=YOUR_DB_HOST;port=3306;database=padel_championship;user=YOUR_DB_USER;password=YOUR_DB_PASSWORD', 'Machine')
[System.Environment]::SetEnvironmentVariable('Jwt__Key', 'REPLACE_WITH_STRONG_SECRET_AT_LEAST_32_CHARS', 'Machine')
[System.Environment]::SetEnvironmentVariable('Jwt__Issuer', 'PadelChampionship', 'Machine')
[System.Environment]::SetEnvironmentVariable('Jwt__Audience', 'PadelChampionship.Mobile', 'Machine')
```

Important: redemarrer la session/service apres modification des variables.

## 4. Execution manuelle (validation)

```powershell
cd .\publish
$env:ASPNETCORE_URLS = 'http://0.0.0.0:5000'
.\PadelChampionship.Api.exe
```

Verification rapide:

- `GET http://<server-ip>:5000/api/health` (si endpoint health existe)
- sinon tester `POST /api/auth/login`

## 5. Installation en service Windows (option)

Approche simple: utiliser `sc.exe` ou NSSM pour lancer `PadelChampionship.Api.exe` dans `publish`.

Parametres recommandes:

- Working directory: dossier `publish`
- Startup: Automatic
- Restart on failure: enabled

## 6. Flutter client en Production

Pointer `ApiConfig.baseUrl` vers l'URL publique du serveur (ex: `http://YOUR_SERVER_IP:5000`).

## 7. Checklist securite minimale

- Utiliser un vrai secret JWT fort (>= 32 caracteres)
- Utiliser un utilisateur DB dedie (pas `root`)
- Sauvegarder la base regulierement
- Restreindre l'acces au port DB au serveur API uniquement
