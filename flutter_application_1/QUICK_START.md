# ⚡ Démarrage Rapide - Session Suivante

## 🎯 Où nous en sommes

✅ **Semaine 9 TERMINÉE** - Architecture modulaire Flutter + Services API

## 🔥 Actions Immédiates (5 min)

### 1. Installer .NET SDK
```
https://dotnet.microsoft.com/download
→ Télécharger .NET 8.0 SDK (Windows x64)
→ Installer
→ Redémarrer PowerShell
```

### 2. Lancer le Backend
```powershell
cd backend\PadelChampionship.Api
dotnet restore
dotnet run
```
✅ Serveur démarre sur `http://localhost:5000`  
✅ Swagger UI : `http://localhost:5000/swagger`

### 3. Tester l'API
Ouvrir http://localhost:5000/swagger  
Tester `POST /api/auth/login` :
```json
{
  "email": "admin@padel.com",
  "motDePasse": "Admin123!"
}
```
✅ Doit retourner un JWT token

### 4. Configurer Flutter
**Modifier** `lib/core/config/api_config.dart` ligne 7 :

- **Émulateur Android** : `http://10.0.2.2:5000/api`
- **iOS Simulator** : `http://localhost:5000/api`  
- **Appareil physique** : `http://192.168.X.X:5000/api` (votre IP locale)

### 5. Lancer Flutter
```powershell
cd ..\..  # Retour racine projet
flutter run
```

### 6. Tester la Connexion
- Email : `admin@padel.com`
- Mot de passe : `Admin123!`
- Cliquer "Se connecter"

✅ **Succès** : Navigation vers écran admin avec 5 onglets

---

## 🛠️ Prochaine Session de Travail

### Objectif : Implémenter les onglets admin (Semaine 10)

**Commencez par l'onglet Joueurs** :

1. Créer `lib/features/admin/joueurs/joueurs_tab.dart`
2. Utiliser `PlayersService().getAllPlayers()` pour charger la liste
3. Afficher dans un `ListView.builder`
4. Ajouter boutons : "Ajouter", "Modifier niveau", "Bloquer", "Supprimer"

**Code de base** :
```dart
import 'package:flutter/material.dart';
import '../../../data/services/services.dart';
import '../../../domain/domain.dart';

class JoueursTab extends StatefulWidget {
  const JoueursTab({super.key});

  @override
  State<JoueursTab> createState() => _JoueursTabState();
}

class _JoueursTabState extends State<JoueursTab> {
  final _playersService = PlayersService();
  List<AppUser>? _players;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final players = await _playersService.getAllPlayers();
      setState(() {
        _players = players;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(child: Text('Erreur: $_error'));
    }
    
    return ListView.builder(
      itemCount: _players!.length,
      itemBuilder: (context, index) {
        final player = _players![index];
        return ListTile(
          title: Text(player.nom),
          subtitle: Text('${player.email} - Niveau ${player.niveau}'),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Modifier joueur
            },
          ),
        );
      },
    );
  }
}
```

**Ensuite** : Remplacer `const Center(child: Text('Onglet Joueurs - À implémenter'))` par `const JoueursTab()` dans `admin_home_screen.dart`

---

## 📁 Fichiers Importants

| Fichier | Description |
|---------|-------------|
| `GUIDE_DEMARRAGE.md` | Guide complet étape par étape |
| `ARCHITECTURE.md` | Documentation technique complète |
| `CHANGELOG.md` | Historique des modifications |
| `lib/main.dart.backup` | Ancienne version monolithique (backup) |

---

## 🆘 Dépannage Rapide

**Backend ne démarre pas** :
```powershell
dotnet --version   # Vérifier installation
```

**Flutter : "Connection refused"** :
- Vérifier que backend tourne (`dotnet run`)
- Vérifier URL dans `api_config.dart`

**Login échoue** :
- Backend tourne ? Oui ✅
- Comptes de test : admin@padel.com / Admin123!
- Vérifier réponse backend dans Swagger

---

## 📞 Commandes Utiles

```powershell
# Backend
cd backend\PadelChampionship.Api
dotnet run                  # Lancer serveur
dotnet watch run            # Lancer avec auto-reload

# Flutter
flutter pub get             # Installer dépendances
flutter run                 # Lancer app
flutter clean               # Nettoyer cache
flutter pub upgrade         # Mettre à jour packages

# Logs backend
# Les logs s'affichent directement dans le terminal où dotnet run est lancé

# Logs Flutter
# Les logs s'affichent dans le terminal où flutter run est lancé
```

---

**Bonne continuation ! 🚀**
