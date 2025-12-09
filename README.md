# Application de Comptabilité EI (Entreprise Individuelle)

Application web et mobile développée avec Flutter pour la gestion de la comptabilité d'une Entreprise Individuelle au régime réel, conforme à la législation française.

## 🏗️ Architecture

```
compta/
├── front/           # Frontend Flutter (web, mobile, desktop)
├── backend/         # Backend Node.js + Express (API REST)
├── docker-compose.yml
└── init.sql         # Schéma PostgreSQL
```

- **Frontend** : Flutter (web, Android, iOS, Windows, macOS, Linux) → `/front`
- **Backend** : Node.js + Express (API REST) → `/backend`
- **Base de données** : PostgreSQL 16
- **Admin DB** : pgAdmin 4

## 🎯 Fonctionnalités

- ✅ Gestion des ventes et achats (factures clients/fournisseurs)
- ✅ Calcul automatique de la TVA et déclarations
- ✅ Gestion des comptes bancaires et rapprochement
- ✅ Gestion des immobilisations et calcul des amortissements
- ✅ Génération des documents comptables (Journal, Grand Livre, Bilan, Compte de Résultat)
- ✅ Tableau de bord avec KPIs et alertes
- ✅ Export PDF et Excel
- ✅ Conformité légale française (traçabilité, horodatage)

## 📋 Prérequis

- Flutter SDK 3.0 ou supérieur
- Dart 3.0 ou supérieur
- Node.js 18 ou supérieur
- Docker et Docker Compose
- Un IDE (VS Code, Android Studio, IntelliJ)

## 🚀 Installation

### 1. Cloner le projet
```bash
git clone <url-du-projet>
cd compta
```

### 2. Démarrer l'infrastructure avec Docker

```bash
docker-compose up -d
```

Cela démarre :
- **PostgreSQL** sur le port `5432`
  - Base de données : `compta_ei`
  - Utilisateur : `postgres`
  - Mot de passe : `postgres`
- **Backend API** sur le port `3000`
  - URL : http://localhost:3000
  - Health check : http://localhost:3000/health
- **pgAdmin** sur le port `5050`
  - URL : http://localhost:5050
  - Email : `admin@compta.fr`
  - Mot de passe : `admin123`

### 3. Installer les dépendances Flutter

```bash
cd front
flutter pub get
```

### 4. Lancer l'application Flutter

```bash
cd front

# Web
flutter run -d chrome

# Windows
flutter run -d windows

# Android/iOS
## 🔧 Développement sans Docker

### Backend local

```bash
cd backend
npm install
npm run dev
```

Le serveur démarre sur http://localhost:3000

### Frontend Flutter

```bash
cd front
flutter pub get
flutter run -d chrome
```
```bash
flutter run -d chrome
```

## 🗄️ Accès à la base de données

### Via pgAdmin

1. Ouvrir http://localhost:5050
2. Se connecter :
   - Email : `admin@compta.fr`
   - Mot de passe : `admin123`
3. Ajouter un serveur :
   - **Général** → Nom : `Compta EI`
   - **Connection** :
     - Host : `postgres` (depuis Docker) ou `localhost` (depuis l'hôte)
     - Port : `5432`
     - Database : `compta_ei`
     - Username : `postgres`
     - Password : `postgres`

### Via ligne de commande

```bash
docker exec -it compta_postgres psql -U postgres -d compta_ei
```

## 📡 API Endpoints

### Factures
- `GET /api/factures` - Liste toutes les factures
- `POST /api/factures` - Créer une facture
- `GET /api/factures/:id` - Détails d'une facture
- `PUT /api/factures/:id` - Mettre à jour une facture
- `DELETE /api/factures/:id` - Supprimer une facture
- `GET /api/factures/stats/overview` - Statistiques

### TVA
- `GET /api/tva/declarations` - Déclarations TVA
- `GET /api/tva/calcul/:debut/:fin` - Calcul TVA période

### Banque
- `GET /api/banque/comptes` - Comptes bancaires
- `GET /api/banque/transactions` - Transactions

### Immobilisations
- `GET /api/immobilisations` - Liste immobilisations
- `GET /api/immobilisations/amortissements` - Amortissements

### Comptabilité
- `GET /api/comptabilite/ecritures` - Écritures comptables
- `GET /api/comptabilite/plan-comptable` - Plan comptable
- `GET /api/comptabilite/balance/:debut/:fin` - Balance

Documentation complète : [backend/README.md](backend/README.md)

## 🐳 Commandes Docker utiles

```bash
# Démarrer tous les services
docker-compose up -d

# Arrêter tous les services
docker-compose down

# Voir les logs
docker-compose logs -f

# Voir les logs d'un service spécifique
docker-compose logs -f backend
docker-compose logs -f postgres

# Redémarrer un service
docker-compose restart backend

# Reconstruire les images
docker-compose build --no-cache

# Supprimer les volumes (⚠️ perte de données)
docker-compose down -v
```
docker-compose logs -f

# Redémarrer les conteneurs
docker-compose restart

# Supprimer les conteneurs et volumes (⚠️ supprime les données)
docker-compose down -v
```

## 📱 Plateformes supportées

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 📁 Structure du projet

Voir le fichier `archi.md` pour la documentation complète de l'architecture.

```
lib/
├── main.dart                 # Point d'entrée
├── models/                   # Modèles de données
├── services/                 # Logique métier
├── screens/                  # Interfaces utilisateur
├── widgets/                  # Composants réutilisables
└── utils/                    # Utilitaires
```

## 🔧 Configuration

### Base de données

L'application peut utiliser deux types de base de données :

#### Option 1 : SQLite (Local)
- Stockage local pour une utilisation hors ligne
- Base de données créée automatiquement au premier lancement
- Fichier : `compta_ei.db`

#### Option 2 : PostgreSQL (Recommandé)
- Base de données PostgreSQL via Docker
- Meilleure performance et évolutivité
- Accès via pgAdmin pour la gestion
- Configuration dans `docker-compose.yml`

Pour basculer entre SQLite et PostgreSQL, modifiez la configuration dans les services de l'application.

## 📖 Documentation

- [Architecture complète](archi.md) - Documentation technique et fonctionnelle
- [Plan d'implémentation](archi.md#-todo---plan-dimplémentation) - Feuille de route

## 🧪 Tests

```bash
# Tests unitaires
flutter test

# Tests d'intégration
flutter test integration_test/
```

## 📦 Build

```bash
# Android
flutter build apk

# iOS
flutter build ios

# Web
flutter build web

# Windows
flutter build windows
```

## 🤝 Contribution

Ce projet est en cours de développement. Consultez le fichier `archi.md` pour la liste des fonctionnalités à implémenter.

## 📄 Licence

Tous droits réservés.

## 👨‍💻 Auteur

Développé avec Flutter pour la gestion comptable des Entreprises Individuelles.
