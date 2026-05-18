# 🏗️ Architecture Diagram & Data Flow

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     FLUTTER APP (Presentation Layer)             │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐   │
│  │  Admin Interface │  │ Player Interface │  │  Auth Screen │   │
│  ├──────────────────┤  ├──────────────────┤  ├──────────────┤   │
│  │ • Team Mgmt      │  │ • Home Tab       │  │ • Login      │   │
│  │ • Create Player  │  │ • Matchs Tab     │  │ • Register   │   │
│  │ • Manage Assign  │  │ • Profile Tab    │  │              │   │
│  └──────────────────┘  └──────────────────┘  └──────────────┘   │
│                                                                   │
│         ↓                    ↓                      ↓             │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              Role-Based Navigation                        │   │
│  │         (Decides which screens to show)                  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                           ↓                                      │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │           Validation Layer (Input Validation)            │   │
│  ├──────────────────────────────────────────────────────────┤   │
│  │ • Email validation     • Level validation                │   │
│  │ • Password validation  • Team name validation            │   │
│  │ • Name validation      • File size validation            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│                           ↓                                      │
└───────────────────────────┼───────────────────────────────────────┘
                            │
                            │
┌───────────────────────────┼───────────────────────────────────────┐
│              SERVICE LAYER (Business Logic)                        │
├───────────────────────────┼───────────────────────────────────────┤
│                           │                                        │
│  ┌────────────────────────┴────────────────┐                      │
│  │                                         │                      │
│  ↓                                         ↓                      │
│  ┌─────────────────────────────┐  ┌──────────────────────────┐   │
│  │  Firebase Auth Service      │  │ Firestore Service        │   │
│  ├─────────────────────────────┤  ├──────────────────────────┤   │
│  │ • login()                   │  │ • createUser()           │   │
│  │ • registerUser()            │  │ • getUserByEmail()       │   │
│  │ • changePassword()          │  │ • updateUserProfile()    │   │
│  │ • updateDisplayName()       │  │ • createTeam()           │   │
│  │ • updateProfilePhoto()      │  │ • assignPlayerToTeam()   │   │
│  │ • logout()                  │  │ • getPlayersInTeam()     │   │
│  │ • authStateChanges stream   │  │ • canPlayerJoinTeam()    │   │
│  └─────────────────────────────┘  └──────────────────────────┘   │
│                                                                    │
│              ┌────────────────────────────────┐                   │
│              │ Firebase Storage Service       │                   │
│              ├────────────────────────────────┤                   │
│              │ • uploadProfileImage()         │                   │
│              │ • deleteProfileImage()         │                   │
│              │ • uploadMultipleImages()       │                   │
│              └────────────────────────────────┘                   │
│                                                                    │
│              ↓                    ↓                      ↓         │
└──────────────┼────────────────────┼──────────────────────┼────────┘
               │                    │                      │
               │                    │                      │
┌──────────────┴────────────────────┴──────────────────────┴────────┐
│                    FIREBASE BACKEND                               │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐   │
│  │  Firebase Auth   │  │  Cloud Firestore │  │ Cloud Storage│   │
│  ├──────────────────┤  ├──────────────────┤  ├──────────────┤   │
│  │                  │  │                  │  │              │   │
│  │ Users:           │  │ Collections:     │  │ Buckets:     │   │
│  │ • auth tokens    │  │ • users          │  │ • images     │   │
│  │ • sessions       │  │ • teams          │  │   • profile/ │   │
│  │ • credentials    │  │ • playersTeams   │  │             │   │
│  │                  │  │                  │  │ Features:    │   │
│  │ Features:        │  │ Features:        │  │ • Upload     │   │
│  │ • Sign in        │  │ • Read/Write     │  │ • Download   │   │
│  │ • Sign up        │  │ • Real-time sync │  │ • Delete     │   │
│  │ • Sessions       │  │ • Validation     │  │ • Access     │   │
│  │ • Password mgmt  │  │ • Queries        │  │   control    │   │
│  └──────────────────┘  └──────────────────┘  └──────────────┘   │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagrams

### 1. LOGIN FLOW

```
User Input: email, password
      ↓
Validate Input (ValidationUtils)
      ↓
FirebaseAuthService.loginUser()
      ↓
Firebase Auth Verify Credentials
      ↓
Create Session Token
      ↓
FirestoreService.getUserByEmail()
      ↓
Firestore: Get user document
      ↓
Return AppUser with role
      ↓
RoleBasedNavigation: Check role
      ↓
     Admin? → AdminHomeScreen
     Player? → PlayerHomeScreen
      ↓
User Logged In ✓
```

### 2. CREATE/UPDATE PROFILE FLOW

```
Player Edit Name
      ↓
Validate Name (ValidationUtils)
      ↓
FirebaseAuthService.updateDisplayName()
      ↓
Update Firebase Auth Profile
      ↓
FirestoreService.updateUserProfile()
      ↓
Update Firestore user document
      ↓
Success Message ✓
UI Refresh
```

### 3. UPLOAD PROFILE IMAGE FLOW

```
Player Select Image
      ↓
Validate File Size (ValidationUtils)
      ↓
FirebaseStorageService.uploadProfileImage()
      ↓
Upload to Firebase Storage
      ↓
Get Download URL
      ↓
FirebaseAuthService.updateProfilePhoto()
      ↓
Update Auth profile URL
      ↓
FirestoreService.updateUserProfile()
      ↓
Update Firestore photoPath
      ↓
Success + Refresh UI ✓
```

### 4. TEAM ASSIGNMENT FLOW

```
Admin Select Player & Team
      ↓
Validate Selection (not null)
      ↓
FirestoreService.canPlayerJoinTeam()
      ↓
      ├─ Get Team Info
      └─ Check Level Compatibility (±2 levels)
      ↓
      Level OK? → Continue
      Level Bad? → Error ✗
      ↓
FirestoreService.assignPlayerToTeam()
      ↓
Check if Player Already in Team
      ↓
      Already Assigned? → Error ✗
      Not Assigned? → Continue
      ↓
Update Firestore: users/{email}.teamId = teamId
      ↓
Success Message ✓
Refresh Team List
```

### 5. PASSWORD CHANGE FLOW

```
Player Enter Current + New Password
      ↓
Validate Passwords (ValidationUtils)
      ├─ Current: not empty
      ├─ New: min 6 chars, uppercase, lowercase, digit
      └─ Match: new == confirm
      ↓
FirebaseAuthService.changePassword()
      ↓
Re-authenticate with current password
      ↓
Update Firebase Auth password
      ↓
Success Message ✓
Clear Fields
```

---

## Service Interaction Diagram

```
┌────────────────────────┐
│   UI Components        │
│  (Screens/Widgets)     │
└────────────┬───────────┘
             │
             ├─────────────────────────────────┬─────────────────────────┐
             │                                 │                         │
             ↓                                 ↓                         ↓
    ┌─────────────────┐           ┌──────────────────┐      ┌─────────────────┐
    │ FirebaseAuth    │           │ Firestore        │      │ Storage         │
    │ Service         │           │ Service          │      │ Service         │
    ├─────────────────┤           ├──────────────────┤      ├─────────────────┤
    │ • Auth ops      │           │ • Data ops       │      │ • File ops      │
    │ • User mgmt     │           │ • Queries        │      │ • Access ctrl   │
    │ • Sessions      │           │ • Validation     │      │ • URL mgmt      │
    └────────┬────────┘           └────────┬─────────┘      └────────┬────────┘
             │                            │                         │
             └────────────────┬───────────┴─────────────────────────┘
                              │
                              ↓
                    ┌──────────────────┐
                    │  Firebase SDK    │
                    │  (Client Library)│
                    └────────┬─────────┘
                             │
                             ↓
                    ┌──────────────────┐
                    │  Internet        │
                    │  (HTTPS/TLS)     │
                    └────────┬─────────┘
                             │
                             ↓
                    ┌──────────────────┐
                    │  Google Servers  │
                    │  (Firebase)      │
                    └──────────────────┘
```

---

## Database Schema

### Firestore Collections

```
USERS COLLECTION
├── Document: admin@padel.com
│   ├── id: 123456
│   ├── nom: "Admin User"
│   ├── email: "admin@padel.com"
│   ├── role: "admin"
│   ├── niveau: 10
│   ├── status: "actif"
│   ├── clubId: 1
│   ├── teamId: null
│   ├── photoPath: null
│   ├── createdAt: Timestamp
│   ├── updatedAt: Timestamp
│   └── teamAssignedAt: null
│
└── Document: joueur@padel.com
    ├── id: 654321
    ├── nom: "Jean Dupont"
    ├── email: "joueur@padel.com"
    ├── role: "joueur"
    ├── niveau: 5
    ├── status: "actif"
    ├── clubId: 1
    ├── teamId: 1 ← Links to Teams collection
    ├── photoPath: "https://storage.googleapis.com/..."
    ├── createdAt: Timestamp
    ├── updatedAt: Timestamp
    └── teamAssignedAt: Timestamp


TEAMS COLLECTION
├── Document: "1"
│   ├── id: 1
│   ├── nom: "Team Alpha"
│   ├── niveau: 5 ← Level 5 team
│   └── createdAt: Timestamp
│
└── Document: "2"
    ├── id: 2
    ├── nom: "Team Beta"
    ├── niveau: 8 ← Level 8 team
    └── createdAt: Timestamp


PLAYERSTEAMS COLLECTION (Optional - for analytics)
├── Document: joueur@padel.com_1
│   ├── playerEmail: "joueur@padel.com"
│   ├── teamId: 1
│   ├── assignedAt: Timestamp
│   └── removedAt: null
│
└── Document: autre@padel.com_2
    ├── playerEmail: "autre@padel.com"
    ├── teamId: 2
    ├── assignedAt: Timestamp
    └── removedAt: Timestamp
```

---

## Storage Structure

```
Firebase Storage Bucket
│
└── profile_images/
    ├── admin@padel.com_1715951234567.jpg
    ├── admin@padel.com_1715951235678.jpg (newer)
    ├── joueur@padel.com_1715951240123.jpg
    └── autre@padel.com_1715951245456.jpg

Folder structure:
- profile_images/{userEmail}_{timestamp}.{ext}
```

---

## State Management

```
App State
│
├── Authentication State
│   ├── User logged in? (bool)
│   ├── Current User (AppUser)
│   └── Auth Token (string)
│
├── User Data State
│   ├── Profile (AppUser)
│   ├── Teams (List<Team>)
│   └── Photo URL (string)
│
└── UI State
    ├── Loading (bool)
    ├── Error Message (string)
    ├── Selected Team (int?)
    └── Selected Player (string?)
```

---

## Error Handling Flow

```
User Action
    ↓
Try Block
    ├─ Validate Input
    └─ Call Service
        ↓
    Catch Firebase Exception
        ├─ Map Error Code
        ├─ Get User-Friendly Message
        └─ Show SnackBar
    ↓
Catch Generic Exception
    ├─ Log Error
    └─ Show Generic Message
    ↓
Finally Block
    ├─ Stop Loading Indicator
    └─ Update UI
```

---

## Authentication Flow

```
START: App Launch
    ↓
Check AuthStateChanges Stream
    ↓
    ├─ User Authenticated? YES
    │   ├─ Get Current User UID
    │   ├─ Fetch User Data from Firestore
    │   ├─ Create AppUser object
    │   └─ Navigate to RoleBasedNavigation
    │
    └─ User NOT Authenticated? NO
        └─ Navigate to Login Screen
            ↓
        User Enters Credentials
            ↓
        FirebaseAuthService.loginUser()
            ↓
        Firebase Auth Validation
            ├─ Success: Create Session
            └─ Failed: Show Error
```

---

## Security Architecture

```
┌─────────────────────────────────────────────────────┐
│              Client-Side Security                   │
├─────────────────────────────────────────────────────┤
│ • Input Validation (ValidationUtils)                │
│ • Password requirements enforcement                 │
│ • Secure credential handling                        │
│ • No sensitive data in logs                         │
└─────────────────────────────────────────────────────┘
                      ↓ HTTPS/TLS ↓
┌─────────────────────────────────────────────────────┐
│           Firebase Security Rules                   │
├─────────────────────────────────────────────────────┤
│                                                     │
│ Authentication:                                     │
│ • Email/Password verified                          │
│ • JWT tokens issued                                │
│ • Session management                               │
│                                                     │
│ Firestore Authorization:                           │
│ • Users can read/write only own docs               │
│ • Admins can manage users and teams                │
│ • Role-based access control                        │
│                                                     │
│ Storage Authorization:                             │
│ • Users can upload own images                      │
│ • File size validation (5MB limit)                 │
│ • Authenticated access required                    │
│                                                     │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│           Data Encryption                          │
├─────────────────────────────────────────────────────┤
│ • In Transit: TLS 1.2+                             │
│ • At Rest: Google-managed encryption               │
│ • Passwords: Hashed by Firebase                    │
└─────────────────────────────────────────────────────┘
```

---

## Dependency Injection Pattern

```
Services (Singletons)
    ↓
FirebaseAuthService instance
FirestoreService instance
FirebaseStorageService instance
ValidationUtils (static methods)
    ↓
Screens
    ├─ player_profile_screen.dart
    ├─ admin_team_management_screen.dart
    └─ role_based_navigation.dart
    ↓
Widgets use services directly
(No complex DI framework needed)
```

---

## Component Relationships

```
main.dart
├── Initializes Firebase
└── Creates MaterialApp
    └── PadelChampionshipApp
        ├── Theme (Dark + Neon Green)
        └── Home: _AppEntryPoint
            └── FutureBuilder (Check Auth)
                ├── Loading: CircularProgressIndicator
                ├── Authenticated: RoleBasedNavigation
                │   ├── Admin: AdminHomeScreen
                │   │   └── AdminTeamManagementScreen
                │   └── Player: NavigationBar
                │       ├── PlayerHomeScreen
                │       ├── MesMatchsScreen
                │       └── PlayerProfileScreen
                │           └── Image Upload Dialog
                └── Not Authenticated: AuthGateway
                    ├── LoginScreen
                    └── RegisterScreen
```

---

## Performance Considerations

```
Optimization Strategy:

1. Lazy Loading
   - Screens loaded on demand
   - Images cached via image_picker

2. Query Optimization
   - Specific field queries
   - Indexed fields (email, teamId)

3. Network Efficiency
   - Single document reads when possible
   - Collection queries only when needed

4. UI Responsiveness
   - Loading states prevent double-tap
   - Errors don't freeze UI
   - Async operations don't block

5. Storage
   - Images compressed before upload
   - Automatic cleanup on delete
```

---

## Future Extensibility

```
Current Architecture supports adding:
├── Push Notifications (Firebase Cloud Messaging)
├── Analytics (Firebase Analytics)
├── Crash Reporting (Firebase Crashlytics)
├── Performance Monitoring (Firebase Performance)
├── Remote Config (Firebase Remote Config)
└── A/B Testing (Firebase A/B Testing)

New Screens can easily be added:
├── Match History
├── Team Statistics
├── Player Rankings
├── Notifications
└── Settings

Without changing core architecture
```

---

**This architecture is:**
- ✅ Scalable
- ✅ Maintainable
- ✅ Secure
- ✅ Extensible
- ✅ Production-Ready
