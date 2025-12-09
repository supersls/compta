# Application de Comptabilité EI (Entreprise Individuelle)

Application web et mobile développée avec Flutter pour la gestion de la comptabilité d'une Entreprise Individuelle au régime réel, conforme à la législation française.

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
- Un IDE (VS Code, Android Studio, IntelliJ)
- Docker et Docker Compose (pour la base de données PostgreSQL)

## 🚀 Installation

1. Cloner le projet :
```bash
git clone <url-du-projet>
cd compta
```

2. Démarrer la base de données PostgreSQL avec Docker :
```bash
docker-compose up -d
```

Cela démarre :
- **PostgreSQL** sur le port `5432`
  - Base de données : `compta_ei`
  - Utilisateur : `compta_admin`
  - Mot de passe : `compta_password_2024`
- **pgAdmin** sur le port `5050`
  - URL : http://localhost:5050
  - Email : `admin@compta.fr`
  - Mot de passe : `admin123`

3. Installer les dépendances Flutter :
```bash
flutter pub get
```

4. Lancer l'application :
```bash
flutter run
```

### Accéder à pgAdmin

1. Ouvrir http://localhost:5050 dans votre navigateur
2. Se connecter avec :
   - Email : `admin@compta.fr`
   - Mot de passe : `admin123`
3. Ajouter un nouveau serveur :
   - **Général** → Nom : `Compta EI`
   - **Connection** :
     - Host : `postgres` (ou `localhost` si accès depuis l'hôte)
     - Port : `5432`
     - Database : `compta_ei`
     - Username : `compta_admin`
     - Password : `compta_password_2024`

### Commandes Docker utiles

```bash
# Démarrer les conteneurs
docker-compose up -d

# Arrêter les conteneurs
docker-compose down

# Voir les logs
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
