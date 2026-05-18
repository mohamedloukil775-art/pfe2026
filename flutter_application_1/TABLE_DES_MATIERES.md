# Table des matières - PadelChampionship

## Introduction Générale	1

## 1	Étude préalable	3
### 1.1	Introduction . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	4
### 1.2	Présentation de l'organisme d'accueil . . . . . . . . . . . . . . . . . . . .	4
### 1.3	Présentation du projet . . . . . . . . . . . . . . . . . . . . . . . . . . . .	5
#### 1.3.1	Cadre du projet . . . . . . . . . . . . . . . . . . . . . . . . . . .	5
#### 1.3.2	Problématique . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	5
#### 1.3.3	Étude de l'existant . . . . . . . . . . . . . . . . . . . . . . . . . .	6
##### 1.3.3.1	Solutions existantes	. . . . . . . . . . . . . . . . . . . .	6
##### 1.3.3.2	Critique de l'existant . . . . . . . . . . . . . . . . . . . .	8
#### 1.3.4	Solution proposée . . . . . . . . . . . . . . . . . . . . . . . . . . .	9
### 1.4	Conclusion . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	11

## 2	Analyse et conception	12
### 2.1	Introduction . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	14
### 2.2	Identification des acteurs . . . . . . . . . . . . . . . . . . . . . . . . . . .	14
### 2.3	Identification des besoins fonctionnels	. . . . . . . . . . . . . . . . . . .	15
### 2.4	Identification des besoins non fonctionnels . . . . . . . . . . . . . . . . .	17
### 2.5	Langage de modélisation . . . . . . . . . . . . . . . . . . . . . . . . . . .	18
### 2.6	Diagramme de cas d'utilisation	. . . . . . . . . . . . . . . . . . . . . . .	18
### 2.7	Description textuelles des cas d'utilisation	. . . . . . . . . . . . . . . . .	20
#### 2.7.1	Description textuelle du scénario "Consulter plateforme"	. . . . .	20
#### 2.7.2	Description textuelle du scénario "S'authentifier" . . . . . . . . . .	20
#### 2.7.3	Description textuelle du scénario "Créer un compte" . . . . . . . .	22
#### 2.7.4	Description textuelle du scénario "Gérer profil" . . . . . . . . . . .	22
#### 2.7.5	Description textuelle du scénario "Créer un tournoi"	. . . . . . .	23
#### 2.7.6	Description textuelle du scénario "Inscrire un joueur"	. . . . . . .	24
#### 2.7.7	Description textuelle du scénario "Créer un match" . . . . . . . . .	25
#### 2.7.8	Description textuelle du scénario "Enregistrer les résultats"	. . . .	25
#### 2.7.9	Description textuelle du scénario "Consulter classements"	. . . . .	26
#### 2.7.10	Description textuelle du scénario "Générer les appariements"	. . . .	27
#### 2.7.11	Description textuelle du scénario "Gérer les utilisateurs"	. . . . . .	28
#### 2.7.12	Description textuelle du scénario "Gérer les clubs"	. . . . . . . .	29
#### 2.7.13	Description textuelle du scénario "Modifier niveaux de joueurs" . . .	30
#### 2.7.14	Description textuelle du scénario "Approuver les modifications" . .	31
#### 2.7.15	Description textuelle du scénario "Générer des rapports" . . . . . .	32
#### 2.7.16	Description textuelle du scénario "Bloquer un joueur" . . . . . . .	32

### 2.8	Diagramme de classe . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	36
### 2.9	Diagramme de séquence	. . . . . . . . . . . . . . . . . . . . . . . . . . .	38
#### 2.9.1	Diagramme de séquence du cas d'utilisation "S'authentifier"	. . .	38
#### 2.9.2	Diagramme de séquence du cas d'utilisation "Créer un tournoi" .	39
#### 2.9.3	Diagramme de séquence du cas d'utilisation "Inscrire un joueur" 41
#### 2.9.4	Diagramme de séquence du cas d'utilisation "Enregistrer les résultats" 42
### 2.10	Conclusion . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	43

## 3	Réalisation	44
### 3.1	Introduction . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	46
### 3.2	Étude technique et architecture . . . . . . . . . . . . . . . . . . . . . . .	46
#### 3.2.1	Environnement logiciel . . . . . . . . . . . . . . . . . . . . . . . .	46
##### 3.2.1.1	Visual Studio Code . . . . . . . . . . . . . . . . . . . .	46
##### 3.2.1.2	Visual Studio Community . . . . . . . . . . . . . . . . . .	47
##### 3.2.1.3	Postman . . . . . . . . . . . . . . . . . . . . . . . . . . .	47
##### 3.2.1.4	Git . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	47
##### 3.2.1.5	Visual Paradigm UML . . . . . . . . . . . . . . . . . . .	48
##### 3.2.1.6	Flutter DevTools . . . . . . . . . . . . . . . . . . . . . . .	48

#### 3.2.2	Services utilisés . . . . . . . . . . . . . . . . . . . . . . . . . . . .	49
##### 3.2.2.1	MySQL . . . . . . . . . . . . . . . . . . . . . . . . . . .	49
##### 3.2.2.2	Bcrypt . . . . . . . . . . . . . . . . . . . . . . . . . . . .	49
##### 3.2.2.3	JWT . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	49
##### 3.2.2.4	Entity Framework Core . . . . . . . . . . . . . . . . . . .	50
##### 3.2.2.5	HTTP Client . . . . . . . . . . . . . . . . . . . . . . . . .	50

#### 3.2.3	Langages et technologies . . . . . . . . . . . . . . . . . . . . . . .	51
##### 3.2.3.1	C# et .NET 8 . . . . . . . . . . . . . . . . . . . . . .	51
##### 3.2.3.2	Flutter et Dart . . . . . . . . . . . . . . . . . . . . . . .	51
##### 3.2.3.3	REST API . . . . . . . . . . . . . . . . . . . . . . . . . .	52
##### 3.2.3.4	Async/Await . . . . . . . . . . . . . . . . . . . . . . . . .	52
##### 3.2.3.5	Material Design . . . . . . . . . . . . . . . . . . . . . . .	52
##### 3.2.3.6	Provider Pattern . . . . . . . . . . . . . . . . . . . . . . .	53
##### 3.2.3.7	Dependency Injection . . . . . . . . . . . . . . . . . . . .	53

### 3.3	Architecture logicielle . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	53
#### 3.3.1	Architecture Backend . . . . . . . . . . . . . . . . . . . . . . . . .	54
#### 3.3.2	Architecture Frontend	. . . . . . . . . . . . . . . . . . . . . . . .	54
#### 3.3.3	Communication entre le Backend et le Frontend . . . . . . . . .	55

### 3.4	Description du travail réalisé . . . . . . . . . . . . . . . . . . . . . . . . .	56

#### 3.4.1	Interfaces administrateur . . . . . . . . . . . . . . . . . . . . . . .	56
##### 3.4.1.1	Page d'accueil . . . . . . . . . . . . . . . . . . . . . . . .	56
##### 3.4.1.2	Interface d'authentification	. . . . . . . . . . . . . . .	56
##### 3.4.1.3	Tableau de bord	. . . . . . . . . . . . . . . . . . . . . .	57
##### 3.4.1.4	Interface de gestion des joueurs . . . . . . . . . . . . . .	58
##### 3.4.1.5	Interface d'ajout d'un joueur . . . . . . . . . . . . . . .	59
##### 3.4.1.6	Interface de gestion des tournois . . . . . . . . . . . . .	59
##### 3.4.1.7	Interface de gestion des clubs	. . . . . . . . . . . . . .	60

#### 3.4.2	Interfaces joueur . . . . . . . . . . . . . . . . . . . . . . . . . . .	61
##### 3.4.2.1	Page d'accueil du joueur	. . . . . . . . . . . . . . . . .	61
##### 3.4.2.2	Interface de consulter les tournois disponibles	. . . . .	61
##### 3.4.2.3	Interface de vue détaillée d'un tournoi	. . . . . . . . .	62
##### 3.4.2.4	Interface de consulter mes matchs . . . . . . . . . . . . .	63
##### 3.4.2.5	Interface de consulter mon profil . . . . . . . . . . . . .	63

#### 3.4.3	Interface de gestion des matchs . . . . . . . . . . . . . . . . . . . .	64
##### 3.4.3.1	Interface de programmation des matchs . . . . . . . . . . .	64
##### 3.4.3.2	Interface de saisie des résultats	. . . . . . . . . . . . .	65

#### 3.4.4	Interface de classement et statistiques . . . . . . . . . . . . . . .	65
##### 3.4.4.1	Tableau de classement par tournoi . . . . . . . . . . . .	65
##### 3.4.4.2	Interface des statistiques individuelles du joueur . . . . .	66
##### 3.4.4.3	Interface de l'historique des matchs	. . . . . . . . . . .	67

### 3.5	Conclusion . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	68

## Conclusion générale	69

## Webographie	71

---

## Liste des figures

### Frontend (Flutter)
- 3.1 Logo de Flutter . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	46
- 3.2 Logo de Visual Studio Code . . . . . . . . . . . . . . . . . . . . . . . . .	46
- 3.3 Logo de Postman . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	47
- 3.4 Logo de Git . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	47
- 3.5 Logo de Visual Paradigm UML	. . . . . . . . . . . . . . . . . . . . . . .	48
- 3.6 Logo de Flutter DevTools . . . . . . . . . . . . . . . . . . . . . . . . . .	48

### Backend (.NET)
- 3.7 Logo de MySQL . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	49
- 3.8 Logo de Bcrypt . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	49
- 3.9 Logo de JWT . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	50
- 3.10 Logo de Entity Framework Core . . . . . . . . . . . . . . . . . . . . . . .	50
- 3.11 Logo de .NET 8	. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	50
- 3.12 Logo de C# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	51

### Interfaces
- 3.13 Page d'accueil . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	56
- 3.14 Interface d'authentification . . . . . . . . . . . . . . . . . . . . . . . . .	56
- 3.15 Tableau de bord de l'administrateur . . . . . . . . . . . . . . . . . . . .	57
- 3.16 Interface de gestion de tous les joueurs . . . . . . . . . . . . . . . . . .	58
- 3.17 Interface d'ajout d'un nouveau joueur	. . . . . . . . . . . . . . . . . . .	59
- 3.18 Interface de gestion de tous les tournois . . . . . . . . . . . . . . . . . .	59
- 3.19 Interface de gestion des clubs	. . . . . . . . . . . . . . . . . . . . . . .	60
- 3.20 Page d'accueil d'un joueur authentifié . . . . . . . . . . . . . . . . . . .	61
- 3.21 Interface de tous les tournois disponibles sur la plateforme . . . . . . . .	61
- 3.22 Interface des détails d'un tournoi sélectionné . . . . . . . . . . . . . . . .	62
- 3.23 Interface de consultation des matchs du joueur . . . . . . . . . . . . . . .	63
- 3.24 Interface de profil du joueur . . . . . . . . . . . . . . . . . . . . . . . . .	63
- 3.25 Interface de programmation des matchs	. . . . . . . . . . . . . . . . . . .	64
- 3.26 Interface de saisie des résultats . . . . . . . . . . . . . . . . . . . . . . .	65
- 3.27 Tableau de classement par tournoi	. . . . . . . . . . . . . . . . . . . . .	65
- 3.28 Interface des statistiques individuelles du joueur . . . . . . . . . . . . .	66
- 3.29 Interface de l'historique des matchs associés au joueur	. . . . . . . . . .	67

### Diagrammes UML
- 2.1 Diagramme de cas d'utilisation	. . . . . . . . . . . . . . . . . . . . . . .	19
- 2.2 Diagramme de classe . . . . . . . . . . . . . . . . . . . . . . . . . . . . .	37
- 2.3 Diagramme de séquence du cas d'utilisation "S'authentifier" . . . . . . . .	38
- 2.4 Diagramme de séquence du cas d'utilisation "Créer un tournoi" . . . . .	39
- 2.5 Diagramme de séquence du cas d'utilisation "Inscrire un joueur" . . . . .	40
- 2.6 Diagramme de séquence du cas d'utilisation "Enregistrer les résultats" . .	41

---

## Liste des tableaux

### Étude préalable
- 1.1	Comparaison des plateformes de gestion de tournois existantes . . . . . .	7
- 1.2	Comparaison des points forts et limites des solutions existantes . . . . .	8
- 1.3	Comparaison synthétique des solutions existantes . . . . . . . . . . . . .	9

### Analyse et conception
- 2.1	Tableau de description du cas d'utilisation "Consulter plateforme" . . . .	20
- 2.2	Tableau de description du cas d'utilisation "S'authentifier"	. . . . . . .	21
- 2.3	Tableau de description du cas d'utilisation "Créer un compte"	. . . . . .	22
- 2.4	Tableau de description du cas d'utilisation "Gérer profil" . . . . . . . .	23
- 2.5	Tableau de description du cas d'utilisation "Créer un tournoi"	. . . . . .	23
- 2.6	Tableau de description du cas d'utilisation "Inscrire un joueur" . . . . .	24
- 2.7	Tableau de description du cas d'utilisation "Créer un match"	. . . . . .	24
- 2.8	Tableau de description du cas d'utilisation "Enregistrer les résultats"	. . . . .	25
- 2.9	Tableau de description du cas d'utilisation "Consulter classements"	. . . . .	26
- 2.10 Tableau de description du cas d'utilisation "Générer les appariements" . . . .	27
- 2.11 Tableau de description du cas d'utilisation "Gérer les utilisateurs" . . . . .	28
- 2.12 Tableau de description du cas d'utilisation "Gérer les clubs" . . . . . . . . . .	29
- 2.13 Tableau de description du cas d'utilisation "Modifier niveaux de joueurs" . . . . .	30
- 2.14 Tableau de description du cas d'utilisation "Approuver les modifications"	. . . . .	31
- 2.15 Tableau de description du cas d'utilisation "Générer des rapports" . . . . .	32
- 2.16 Tableau de description du cas d'utilisation "Bloquer un joueur" . . . . .	33

---

**Note:** Cette table des matières est adaptée au projet PadelChampionship. Les numéros de pages sont à titre indicatif et doivent être mis à jour selon le document final.
