# ⚡ Quick Start - Firebase Setup en 5 Minutes

## 🎯 Objectif
Configurer Firebase et démarrer l'application avec les nouvelles fonctionnalités.

---

## 1️⃣ Installer FlutterFire CLI (1 min)

```bash
dart pub global activate flutterfire_cli
```

---

## 2️⃣ Créer un Projet Firebase (2 min)

1. Aller sur https://console.firebase.google.com
2. Cliquer sur **"Créer un projet"**
3. Nom: `PadelChampionship`
4. Cliquer sur **"Créer"**

---

## 3️⃣ Configurer FlutterFire (1 min)

```bash
cd "c:\Users\Dell\Desktop\projet pfe 1\flutter_application_1"
flutterfire configure
```

**Sélectionner:**
- Plateforme: `1. android`
- Projet: `PadelChampionship`

Cela générera automatiquement `firebase_options.dart` ✓

---

## 4️⃣ Activer les Services Firebase (1 min)

### Dans Firebase Console:

#### **Authentication**
1. Aller à **Authentication → Sign-in method**
2. Cliquer sur **Email/Password**
3. Activer et **Save**

#### **Firestore Database**
1. Aller à **Firestore Database**
2. Cliquer sur **Create database**
3. Mode: **Test mode** (pour développement)
4. Région: **europe-west1** (ou votre région)

#### **Storage**
1. Aller à **Storage**
2. Cliquer sur **Create bucket**
3. Région: **europe-west1**

---

## 5️⃣ Installer les Dépendances

```bash
flutter pub get
```

---

## ✅ C'est fini! Lancer l'app

```bash
flutter run -d windows
```

---

## 🧪 Tester les Nouvelles Fonctionnalités

### 1. **Créer un compte admin**

```bash
# Dans Firebase Console → Authentication → Add user
Email: admin@padel.com
Password: Admin123!
```

### 2. **Login**
- Email: `admin@padel.com`
- Password: `Admin123!`

### 3. **Créer un joueur**
- Dans l'interface admin
- Email: `joueur@padel.com`
- Nom: `Jean Dupont`
- Niveau: `5`

### 4. **Tester le profil joueur**
- Login avec: `joueur@padel.com` / `Player123!`
- Aller dans **Profil**
- Modifier le nom
- Télécharger une photo

### 5. **Tester la gestion d'équipes**
- Login admin
- Aller dans **Team Management**
- Créer une équipe
- Assigner un joueur

---

## 🎨 Vérifier le Thème

Les couleurs doivent être:
- ✅ Fond noir/très foncé: `#080B10`
- ✅ Boutons neon green: `#58D6B0`
- ✅ Texte blanc/gris clair

---

## 🚨 Dépannage Rapide

| Problème | Solution |
|----------|----------|
| Firebase not found | `flutter pub get` |
| permission-denied | Vérifier Firestore en test mode |
| Can't upload image | Vérifier Storage créé |
| White screen | Vérifier Firebase init |

---

## 📱 Les Écrans Principaux

### Admin View
- **Home** → Dashboard admin
- **Team Management** → Gérer équipes/joueurs

### Player View
- **Home** → Accueil joueur
- **Matchs** → Historique de matchs
- **Profil** → Modifier profil/mot de passe/photo

---

## 🔗 Ressources

- [Firebase Console](https://console.firebase.google.com)
- [Documentation Complète](FIREBASE_IMPLEMENTATION_GUIDE.md)
- [Résumé Implémentation](IMPLEMENTATION_SUMMARY.md)
- [FlutterFire Docs](https://firebase.flutter.dev/)

---

## ✨ Fonctionnalités Activées

✅ Authentication Firebase  
✅ Firestore Database  
✅ Firebase Storage  
✅ Profil Joueur modifiable  
✅ Gestion Équipes  
✅ Thème Dark avec Neon Green  
✅ Validation des inputs  
✅ Gestion des erreurs  
✅ Navigation par rôle  

---

**Durée totale: ~5 minutes ⚡**

**Questions? Consulter les guides détaillés!**
