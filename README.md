# Application de Comptabilité EI (Entreprise Individuelle)

Application web et mobile développée avec Flutter pour la gestion de la comptabilité d'une Entreprise Individuelle au régime réel, conforme à la législation française.

---

## 📋 Table des Matières

- [Architecture](#-architecture)
- [Démarrage Rapide](#-démarrage-rapide)
- [Fonctionnalités](#-fonctionnalités)
- [Gestion des Justificatifs](#-gestion-des-justificatifs)
- [Configuration du Stockage](#-configuration-du-stockage)
- [Installation Complète](#-installation-complète)
- [API Documentation](#-api-endpoints)
- [Structure du Projet](#-structure-du-projet-détaillée)
- [Tests](#-tests)

---

## 🏗️ Architecture

```
compta/
├── front/           # Frontend Flutter (web, mobile, desktop)
├── backend/         # Backend Node.js + Express (API REST)
├── docker-compose.yml
└── schema.sql       # Schéma PostgreSQL complet
```

- **Frontend** : Flutter (web, Android, iOS, Windows, macOS, Linux) → `/front`
- **Backend** : Node.js + Express (API REST) → `/backend`
- **Base de données** : PostgreSQL 16
- **Admin DB** : pgAdmin 4

### Flux de Données

```
┌─────────────────┐      HTTP/REST      ┌──────────────────┐
│  Flutter App    │◄───────────────────►│  Backend Node.js │
│  (Multi-OS)     │     JSON/JWT        │   (Express)      │
└─────────────────┘                     └────────┬─────────┘
                                                 │
                                                 │ SQL
                                                 ▼
                                        ┌─────────────────┐
                                        │   PostgreSQL    │
                                        │   (Docker)      │
                                        └─────────────────┘
```

## 🚀 Démarrage Rapide

### Option 1 : Script automatique (Recommandé)

**Windows :**
```bash
start.bat
```

**Linux/Mac :**
```bash
chmod +x start.sh
./start.sh
```

### Option 2 : Manuel

```bash
# 1. Démarrer l'infrastructure
docker-compose up -d

# 2. Installer les dépendances Flutter
cd front && flutter pub get && cd ..

# 3. Lancer l'application
cd front && flutter run -d chrome
```

### Vérification

- Backend API: http://localhost:3000/health
- pgAdmin: http://localhost:5050
- Application: http://localhost:8080 (après `flutter run`)

## 🎯 Fonctionnalités

### 1. Gestion des Ventes et Achats
- ✅ Référencement des factures clients et fournisseurs
- ✅ Catégorisation comptable (automatique/manuelle)
- ✅ Suivi des paiements et encaissements
- ✅ Statuts : En attente, Payée, Partiellement payée, En retard
- ✅ **Attachement de justificatifs** (factures PDF, images)

### 2. Gestion de la TVA
- ✅ Calcul automatique de la TVA (20%, 10%, 5.5%, 2.1%)
- ✅ Génération de rapport de déclaration fiscale
- ✅ Suivi TVA collectée vs TVA déductible
- ✅ Export pour CA3 (déclaration mensuelle/trimestrielle)

### 3. Gestion des Comptes Bancaires
- ✅ Import/saisie des relevés bancaires (CSV, OFX)
- ✅ Rapprochement bancaire automatique/manuel
- ✅ Gestion multi-comptes
- ✅ Catégorisation des transactions
- ✅ **Attachement de relevés bancaires**

### 4. Gestion des Immobilisations
- ✅ Saisie des acquisitions d'actifs
- ✅ Calcul automatique des amortissements (linéaire, dégressif)
- ✅ Plan d'amortissement conforme au PCG
- ✅ Gestion de la durée de vie et valeur résiduelle

### 5. Documents Comptables
- ✅ **Journal Comptable** : Chronologique des écritures
- ✅ **Grand Livre** : Synthèse par compte
- ✅ **Bilan Comptable** : Actif/Passif
- ✅ **Compte de Résultat** : Charges/Produits
- ✅ Export PDF et Excel avec templates personnalisables

### 6. Tableau de Bord et Alertes
- ✅ KPIs : CA, Charges, Bénéfice, Trésorerie
- ✅ Graphiques d'évolution temporelle
- ✅ Alertes : Paiements en retard, échéances fiscales

### 7. Gestion des Justificatifs (Nouveau ✨)
- ✅ Upload de fichiers (PDF, images, Excel, Word)
- ✅ Stockage local ou cloud (S3-compatible)
- ✅ Association automatique aux factures/écritures/transactions
- ✅ Visualisation inline dans le navigateur
- ✅ Archivage et historique complet
- ✅ Vérification d'intégrité (checksum SHA-256)


---

## 📄 Gestion des Justificatifs

### Vue d'ensemble

Système modulaire pour gérer les pièces justificatives (factures, relevés bancaires, contrats, etc.) avec support du stockage local et cloud.

### Architecture du système

```
┌─────────────────────────────────────────────────────────┐
│                    API REST                              │
│              /api/justificatifs/*                        │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│              StorageService                              │
│         (Abstraction de stockage)                        │
└────────┬───────────────────────────┬────────────────────┘
         │                           │
┌────────▼────────────┐    ┌────────▼─────────────────────┐
│ LocalStorageProvider│    │  CloudStorageProvider (S3)   │
│  backend/storage/   │    │    AWS S3 / MinIO / Spaces   │
└─────────────────────┘    └──────────────────────────────┘
         │                           │
┌────────▼───────────────────────────▼────────────────────┐
│              PostgreSQL Database                         │
│           (Métadonnées + Historique)                     │
└──────────────────────────────────────────────────────────┘
```

### Fonctionnalités

- ✅ **Upload de fichiers** - PDF, images, Excel, Word (max 10 MB)
- ✅ **Stockage modulaire** - Local ou cloud (S3-compatible)
- ✅ **Métadonnées** - Description, type, date, associations
- ✅ **Visualisation** - Inline dans le navigateur
- ✅ **Téléchargement** - Avec tracking automatique
- ✅ **Archivage** - Déplacement vers dossier archives
- ✅ **Suppression** - Avec audit trail complet
- ✅ **Historique** - Toutes les actions tracées
- ✅ **Vérification d'intégrité** - Checksum SHA-256
- ✅ **Organisation automatique** - Par année/mois
- ✅ **Migration cloud** - Basculer du local au cloud

### Installation des justificatifs

#### 1. Dépendances Backend

```bash
cd backend
npm install multer @aws-sdk/client-s3 @aws-sdk/s3-request-presigner
```

#### 2. Dépendances Frontend

```bash
cd front
flutter pub get  # image_picker déjà dans pubspec.yaml
```

#### 3. Créer le dossier de stockage

```bash
mkdir -p backend/storage/justificatifs
```

### API des justificatifs

#### Upload

```http
POST /api/justificatifs/upload
Content-Type: multipart/form-data

file: [binary]
description: "Facture fournisseur"
type_document: "facture"
date_document: "2024-12-19"
facture_id: 123
```

#### Téléchargement

```http
GET /api/justificatifs/:id/download
```

#### Visualisation

```http
GET /api/justificatifs/:id/view
```

#### Liste

```http
GET /api/justificatifs?facture_id=123
GET /api/justificatifs?type_document=facture
GET /api/justificatifs?archive=false
```

#### Archivage

```http
POST /api/justificatifs/:id/archive
```

#### Suppression

```http
DELETE /api/justificatifs/:id
```

#### Statistiques

```http
GET /api/justificatifs/stats
```

### Utilisation dans les formulaires

#### Formulaire de Facture

Le widget `JustificatifsWidget` est intégré dans le formulaire de facture :

```dart
JustificatifsWidget(
  key: _justificatifsKey,
  typeDocument: 'facture',
  factureId: widget.facture?.id,
  readOnly: _isEditMode,
  dateDocument: _dateEmission,
)
```

**Workflow utilisateur :**
1. Remplir le formulaire de facture
2. Cliquer sur "Ajouter" dans la section Justificatifs
3. Choisir la source (📷 Caméra / 🖼️ Galerie / 📁 Fichier)
4. Sélectionner un ou plusieurs fichiers
5. Les fichiers apparaissent en attente d'upload
6. Sauvegarder la facture
7. Les fichiers sont automatiquement uploadés et liés

#### Formulaire d'Écriture Comptable

```dart
JustificatifsWidget(
  key: _justificatifsKey,
  typeDocument: 'ecriture',
  dateDocument: _dateEcriture,
)
```

#### Formulaire de Transaction Bancaire

```dart
JustificatifsWidget(
  key: _justificatifsKey,
  typeDocument: 'releve',
  dateDocument: _dateTransaction,
)
```

### Types de fichiers acceptés

- **PDF** : `.pdf`
- **Images** : `.jpg`, `.jpeg`, `.png`, `.gif`
- **Excel** : `.xlsx`, `.xls`
- **Word** : `.doc`, `.docx`

**Taille maximale :** 10 MB par fichier

---

## 🗄️ Configuration du Stockage

### Option 1 : Volume Docker (RECOMMANDÉ ✅)

**Configuration actuelle** - Les fichiers sont stockés dans un volume Docker persistant :

```yaml
backend:
  volumes:
    - justificatifs_storage:/app/storage/justificatifs
  environment:
    STORAGE_MODE: local
    LOCAL_STORAGE_PATH: /app/storage/justificatifs

volumes:
  justificatifs_storage:
    driver: local
```

**Avantages :**
- ✅ Données **persistantes** même si le conteneur est supprimé
- ✅ Géré automatiquement par Docker
- ✅ Isolation du système hôte
- ✅ Facile à sauvegarder avec `docker volume`

**Commandes utiles :**

```bash
# Voir le contenu du volume
docker run --rm -v compta_justificatifs_storage:/data alpine ls -la /data

# Sauvegarder le volume
docker run --rm -v compta_justificatifs_storage:/source -v $(pwd):/backup alpine tar czf /backup/justificatifs-backup.tar.gz -C /source .

# Restaurer le volume
docker run --rm -v compta_justificatifs_storage:/target -v $(pwd):/backup alpine tar xzf /backup/justificatifs-backup.tar.gz -C /target
```

### Option 2 : Dossier local du système (ALTERNATIF)

Pour un accès direct depuis l'explorateur Windows :

**Modifier `docker-compose.yml` :**

```yaml
backend:
  volumes:
    - ./backend/storage/justificatifs:/app/storage/justificatifs
  environment:
    STORAGE_MODE: local
    LOCAL_STORAGE_PATH: /app/storage/justificatifs
```

**Avantages :**
- ✅ Accès direct depuis l'explorateur Windows
- ✅ Facile à synchroniser avec un cloud (Dropbox, Google Drive)
- ✅ Sauvegarde simple (copier le dossier)

**Localisation :**
```
C:\Users\Supersls\Desktop\myProjects\compta\backend\storage\justificatifs\
├── 2024/
│   └── 12/
│       ├── fichier1.pdf
│       └── fichier2.jpg
└── archives/
```

### Option 3 : Stockage Cloud (S3)

Pour un stockage cloud (AWS S3, MinIO, DigitalOcean Spaces, Wasabi) :

**Configuration dans `.env` :**

```env
STORAGE_MODE=cloud
S3_ACCESS_KEY_ID=your_key
S3_SECRET_ACCESS_KEY=your_secret
S3_REGION=eu-west-1
S3_BUCKET=compta-justificatifs
S3_ENDPOINT=https://s3.amazonaws.com  # Optionnel pour MinIO/Spaces
```

### Migration entre modes de stockage

```bash
# Du volume Docker vers le dossier local
mkdir -p backend/storage/justificatifs
docker run --rm \
  -v compta_justificatifs_storage:/source \
  -v $(pwd)/backend/storage/justificatifs:/target \
  alpine sh -c "cp -r /source/* /target/"

# Du dossier local vers le volume Docker
docker volume create compta_justificatifs_storage
docker run --rm \
  -v $(pwd)/backend/storage/justificatifs:/source \
  -v compta_justificatifs_storage:/target \
  alpine sh -c "cp -r /source/* /target/"
```

---

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

## 📁 Structure du Projet Détaillée

```
compta/
│
├── front/                      # 🎨 Frontend Flutter
│   ├── lib/
│   │   ├── config/            # Configuration (API, constantes)
│   │   │   └── api_config.dart
│   │   ├── models/            # Modèles de données
│   │   │   ├── facture.dart
│   │   │   ├── client.dart
│   │   │   ├── banque.dart
│   │   │   ├── immobilisation.dart
│   │   │   └── ecriture_comptable.dart
│   │   ├── screens/           # Écrans de l'application
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── factures/
│   │   │   │   ├── factures_screen.dart
│   │   │   │   └── facture_form_screen.dart
│   │   │   ├── clients/
│   │   │   ├── banque/
│   │   │   │   ├── comptes_screen.dart
│   │   │   │   └── transaction_form_screen.dart
│   │   │   ├── immobilisations/
│   │   │   ├── tva/
│   │   │   ├── documents/
│   │   │   │   ├── journal_screen.dart
│   │   │   │   └── ecriture_form_screen.dart
│   │   │   └── administration/
│   │   ├── services/          # Services HTTP (API calls)
│   │   │   ├── api_service.dart
│   │   │   ├── facture_service_http.dart
│   │   │   ├── banque_service.dart
│   │   │   ├── immobilisation_service.dart
│   │   │   ├── tva_service.dart
│   │   │   └── justificatif_service.dart
│   │   ├── widgets/           # Composants réutilisables
│   │   │   └── justificatifs_widget.dart
│   │   ├── utils/             # Utilitaires
│   │   │   ├── formatters.dart
│   │   │   ├── validators.dart
│   │   │   └── constants.dart
│   │   └── main.dart          # Point d'entrée
│   ├── web/                   # Configuration Web
│   ├── test/                  # Tests unitaires
│   └── pubspec.yaml           # Dépendances Flutter
│
├── backend/                    # 🚀 Backend Node.js
│   ├── config/
│   │   └── database.js        # Configuration PostgreSQL
│   ├── routes/
│   │   ├── factures.js        # API Factures
│   │   ├── tva.js             # API TVA
│   │   ├── banque.js          # API Banque
│   │   ├── immobilisations.js # API Immobilisations
│   │   ├── comptabilite.js    # API Comptabilité
│   │   ├── entreprise.js      # API Entreprise
│   │   ├── justificatifs.js   # API Justificatifs ⭐
│   │   └── templates.js       # API Templates PDF
│   ├── services/
│   │   ├── pdfGenerator.js    # Génération PDF
│   │   ├── templateService.js # Gestion templates
│   │   ├── storageService.js  # Abstraction stockage ⭐
│   │   ├── localStorageProvider.js    # Stockage local
│   │   └── cloudStorageProvider.js    # Stockage S3
│   ├── templates/             # Templates PDF (JSON)
│   │   ├── facture.json
│   │   ├── compte_resultat.json
│   │   └── bilan.json
│   ├── scripts/
│   │   └── initDB.js          # Script d'initialisation DB
│   ├── storage/               # Stockage local fichiers
│   │   └── justificatifs/
│   ├── server.js              # Point d'entrée Express
│   ├── package.json           # Dépendances Node.js
│   ├── Dockerfile             # Image Docker backend
│   └── swagger.yaml           # Documentation API
│
├── docker-compose.yml          # 🐳 Orchestration Docker
├── schema.sql                  # 📊 Schéma PostgreSQL complet
├── seed.sql                    # 🌱 Données de test
├── README.md                   # 📖 Documentation (ce fichier)
├── start.sh                    # 🎬 Script démarrage (Linux/Mac)
└── start.bat                   # 🎬 Script démarrage (Windows)
```

## 🐳 Commandes Docker utiles

## 🔧 Configuration

### Variables d'environnement Backend

Créer un fichier `.env` dans le dossier `backend/` :

```env
# Base de données
DB_HOST=postgres
DB_PORT=5432
DB_NAME=compta_ei
DB_USER=postgres
DB_PASSWORD=postgres

# Serveur
PORT=3000
NODE_ENV=development

# Stockage des justificatifs
STORAGE_MODE=local              # local ou cloud
LOCAL_STORAGE_PATH=/app/storage/justificatifs

# Cloud S3 (optionnel)
# S3_ACCESS_KEY_ID=your_key
# S3_SECRET_ACCESS_KEY=your_secret
# S3_REGION=eu-west-1
# S3_BUCKET=compta-justificatifs
# S3_ENDPOINT=https://s3.amazonaws.com
```

### Configuration Frontend

Le fichier `lib/config/api_config.dart` contient l'URL de l'API :

```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:3000/api';
}
```

Pour le déploiement, modifier cette URL vers votre serveur de production.

### Base de données

L'application utilise **PostgreSQL** via Docker :

- **Accès direct** : 
  - Host: `localhost`
  - Port: `5432`
  - Database: `compta_ei`
  - User: `postgres`
  - Password: `postgres`

- **Accès via pgAdmin** :
  - URL: http://localhost:5050
  - Email: `admin@compta.fr`
  - Password: `admin123`

**Commandes utiles :**

```bash
# Se connecter à la base
docker exec -it compta_postgres psql -U postgres -d compta_ei

# Exécuter un script SQL
docker exec -i compta_postgres psql -U postgres -d compta_ei < schema.sql

# Backup de la base
docker exec compta_postgres pg_dump -U postgres compta_ei > backup.sql

# Restore de la base
docker exec -i compta_postgres psql -U postgres -d compta_ei < backup.sql
```

---

## 📖 Documentation Détaillée

### Architecture Technique

#### Frontend Flutter

**Packages principaux :**
- `http` : Appels API REST
- `provider` : Gestion d'état
- `intl` : Formatage dates et nombres
- `file_picker` : Sélection de fichiers
- `image_picker` : Capture photos/galerie
- `pdf` : Génération PDF côté client

**Patterns utilisés :**
- **MVVM** : Séparation vue/logique avec Provider
- **Repository Pattern** : Services API centralisés
- **Singleton** : ApiService partagé

#### Backend Node.js

**Dépendances principales :**
- `express` : Framework web
- `pg` : Driver PostgreSQL
- `pdfkit` : Génération PDF
- `multer` : Upload de fichiers
- `@aws-sdk/client-s3` : Stockage cloud S3
- `cors` : Cross-Origin Resource Sharing

**Architecture en couches :**
- **Routes** : Endpoints API
- **Services** : Logique métier
- **Config** : Configuration base de données

### Schéma de Base de Données

**Tables principales :**
- `entreprise` : Informations entreprise
- `clients` : Clients et fournisseurs
- `factures` : Factures ventes/achats
- `paiements` : Paiements des factures
- `comptes_bancaires` : Comptes bancaires
- `transactions_bancaires` : Mouvements bancaires
- `immobilisations` : Actifs immobilisés
- `amortissements` : Plan d'amortissement
- `ecritures_comptables` : Écritures comptables
- `declarations_tva` : Déclarations TVA
- `justificatifs` : Métadonnées des fichiers ⭐
- `justificatifs_historique` : Audit trail ⭐

**Relations clés :**
```
factures 1──N paiements
factures 1──N justificatifs
factures N──1 clients
comptes_bancaires 1──N transactions_bancaires
transactions_bancaires 1──N justificatifs
immobilisations 1──N amortissements
ecritures_comptables 1──N justificatifs
```

---

## 📡 API Endpoints (Complet)

### Factures
```http
GET    /api/factures              # Liste toutes les factures
POST   /api/factures              # Créer une facture
GET    /api/factures/:id          # Détails d'une facture
PUT    /api/factures/:id          # Mettre à jour une facture
DELETE /api/factures/:id          # Supprimer une facture
GET    /api/factures/stats/overview  # Statistiques
GET    /api/factures/numero/:numero  # Chercher par numéro
```

### Clients
```http
GET    /api/clients               # Liste tous les clients
POST   /api/clients               # Créer un client
GET    /api/clients/:id           # Détails d'un client
PUT    /api/clients/:id           # Mettre à jour un client
DELETE /api/clients/:id           # Supprimer un client
```

### TVA
```http
GET    /api/tva/declarations      # Déclarations TVA
POST   /api/tva/declarations      # Créer déclaration
GET    /api/tva/calcul/:debut/:fin  # Calcul TVA période
```

### Banque
```http
GET    /api/banque/comptes        # Comptes bancaires
POST   /api/banque/comptes        # Créer un compte
GET    /api/banque/comptes/:id    # Détails d'un compte
GET    /api/banque/transactions   # Transactions bancaires
POST   /api/banque/transactions   # Créer une transaction
POST   /api/banque/rapprochement  # Rapprocher transaction
```

### Immobilisations
```http
GET    /api/immobilisations       # Liste immobilisations
POST   /api/immobilisations       # Créer immobilisation
GET    /api/immobilisations/amortissements  # Amortissements
POST   /api/immobilisations/amortissements  # Calculer amortissement
```

### Comptabilité
```http
GET    /api/comptabilite/ecritures           # Écritures comptables
POST   /api/comptabilite/ecritures           # Créer écriture
GET    /api/comptabilite/plan-comptable      # Plan comptable (PCG)
GET    /api/comptabilite/balance/:debut/:fin # Balance comptable
GET    /api/comptabilite/grand-livre/:compte # Grand livre
GET    /api/comptabilite/journaux            # Liste des journaux
```

### Documents PDF
```http
GET    /api/comptabilite/journal/:debut/:fin      # Journal PDF
GET    /api/comptabilite/compte-resultat/:debut/:fin  # Compte de résultat PDF
GET    /api/comptabilite/bilan/:date                  # Bilan PDF
```

### Justificatifs ⭐
```http
POST   /api/justificatifs/upload          # Upload fichier
GET    /api/justificatifs                 # Liste justificatifs (avec filtres)
GET    /api/justificatifs/:id             # Détails justificatif
GET    /api/justificatifs/:id/download    # Télécharger fichier
GET    /api/justificatifs/:id/view        # Visualiser inline
POST   /api/justificatifs/:id/archive     # Archiver
DELETE /api/justificatifs/:id             # Supprimer
GET    /api/justificatifs/:id/historique  # Historique des actions
GET    /api/justificatifs/stats           # Statistiques globales
```

### Templates PDF
```http
GET    /api/templates                     # Liste templates disponibles
GET    /api/templates/:category/:name     # Charger un template
```

### Entreprise
```http
GET    /api/entreprise                    # Infos entreprise
POST   /api/entreprise                    # Créer entreprise
PUT    /api/entreprise/:id                # Mettre à jour
```

### Chiffre d'Affaires
```http
GET    /api/chiffre-affaire/:debut/:fin   # CA par période
GET    /api/chiffre-affaire/stats         # Statistiques CA
```

---

## 🧪 Tests

### Tests API Backend

Deux suites de tests pour valider tous les endpoints API:

#### Option 1: Bash Script (curl)
```bash
chmod +x backend/test.sh
./backend/test.sh
```

#### Option 2: Node.js
```bash
cd backend
node test.js
```

Les tests couvrent 30+ endpoints:
- ✅ Santé du backend (health check)
- ✅ Endpoints factures (7)
- ✅ Endpoints TVA (2)
- ✅ Endpoints banque (5+)
- ✅ Endpoints immobilisations (2)
- ✅ Documents comptables (4)
- ✅ Entreprise et comptabilité (2)

Les tests utilisent les données réelles de la base de données et valident les codes HTTP et structure des réponses.

Pour plus de détails: [backend/TEST_README.md](backend/TEST_README.md)

### Tests Frontend

```bash
# Tests unitaires
cd front
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

### Fonctionnalités à implémenter

Voir les issues GitHub ou les TODOs dans le code pour contribuer.

**Prochaines fonctionnalités prioritaires :**
- [ ] Export Excel avancé (tous les documents)
- [ ] Import CSV pour factures et écritures
- [ ] OCR pour extraction automatique de données des justificatifs
- [ ] Dashboard analytics avancé
- [ ] Multi-entreprises
- [ ] Synchronisation cloud temps réel
- [ ] Application mobile native (Android/iOS)
- [ ] Mode hors-ligne avec synchronisation
- [ ] Notifications push (échéances, alertes)
- [ ] API webhooks pour intégrations tierces

### Guidelines de contribution

1. Fork le projet
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

---

## 📊 Technologies Utilisées

### Frontend
- **Flutter** 3.0+ (Dart 3.0+)
- **Provider** - State management
- **HTTP** - API calls
- **File Picker** - Sélection fichiers
- **Image Picker** - Capture photos
- **Intl** - Internationalisation

### Backend
- **Node.js** 18+
- **Express** 4.x
- **PostgreSQL** 16
- **PDFKit** - Génération PDF
- **Multer** - Upload fichiers
- **AWS SDK v3** - Stockage S3

### DevOps
- **Docker** & **Docker Compose**
- **Git** - Version control
- **pgAdmin** 4 - DB management

---

## 🔐 Sécurité

### Recommandations

- ✅ Changer les mots de passe par défaut en production
- ✅ Utiliser HTTPS/TLS pour l'API
- ✅ Activer l'authentification JWT (à implémenter)
- ✅ Limiter les tailles de fichiers uploadés
- ✅ Valider tous les inputs côté backend
- ✅ Utiliser des variables d'environnement pour les secrets
- ✅ Backups réguliers de la base de données
- ✅ Checksum pour vérifier l'intégrité des fichiers

### Données sensibles

Ne **jamais** commit :
- Fichiers `.env` avec credentials
- Clés API et secrets
- Données clients réelles
- Certificats SSL privés

---

## 📱 Plateformes Supportées

- ✅ **Web** (Chrome, Firefox, Edge, Safari)
- ✅ **Windows** 10/11
- ✅ **macOS** 10.15+
- ✅ **Linux** (Ubuntu, Fedora, etc.)
- ✅ **Android** 6.0+ (API 23+)
- ✅ **iOS** 12.0+

---

## 📦 Build pour Production

### Web

```bash
cd front
flutter build web --release

# Déployer le dossier build/web sur un serveur
# Nginx, Apache, Firebase Hosting, Vercel, etc.
```

### Windows

```bash
flutter build windows --release
# Exécutable dans: build/windows/runner/Release/
```

### Android

```bash
flutter build apk --release
# APK dans: build/app/outputs/flutter-apk/app-release.apk

# ou AAB pour Google Play Store
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
# Nécessite un Mac avec Xcode
```

### Backend Docker

```bash
cd backend
docker build -t compta-backend:latest .
docker push your-registry/compta-backend:latest
```

---

## 🐛 Dépannage

### Le backend ne démarre pas

```bash
# Vérifier que PostgreSQL est démarré
docker ps | grep postgres

# Voir les logs du backend
docker-compose logs backend

# Redémarrer le backend
docker-compose restart backend
```

### Erreur de connexion à la base de données

```bash
# Vérifier que la base existe
docker exec -it compta_postgres psql -U postgres -l

# Créer la base si nécessaire
docker exec -it compta_postgres psql -U postgres -c "CREATE DATABASE compta_ei;"

# Exécuter le schéma
docker exec -i compta_postgres psql -U postgres -d compta_ei < schema.sql
```

### Les justificatifs ne s'uploadent pas

```bash
# Vérifier que le dossier existe
docker exec compta_backend ls -la /app/storage/justificatifs

# Vérifier les permissions
docker exec compta_backend chmod -R 777 /app/storage/justificatifs

# Voir les logs
docker-compose logs -f backend | grep justificatifs
```

### Flutter ne trouve pas l'API

1. Vérifier que le backend tourne : http://localhost:3000/health
2. Vérifier l'URL dans `lib/config/api_config.dart`
3. Désactiver le pare-feu temporairement
4. Vérifier les CORS dans `backend/server.js`

### pgAdmin ne se connecte pas

1. Vérifier que pgAdmin tourne : http://localhost:5050
2. Utiliser `postgres` comme hostname (dans Docker)
3. Utiliser `localhost` depuis l'hôte

---

## 📞 Support

Pour toute question ou problème :
1. Vérifier la documentation ci-dessus
2. Consulter les issues GitHub
3. Créer une nouvelle issue avec :
   - Description du problème
   - Steps to reproduce
   - Logs d'erreur
   - Environnement (OS, versions)

---

## 📄 Licence

Tous droits réservés © 2025

---

## 👨‍💻 Auteur

Développé avec ❤️ et Flutter pour simplifier la comptabilité des Entreprises Individuelles.

**Version actuelle :** 1.0.0  
**Dernière mise à jour :** 19 décembre 2024

---

## 🗺️ Roadmap

### v1.1 - Q1 2025
- [ ] Import automatique relevés bancaires (OFX/CSV)
- [ ] OCR pour justificatifs
- [ ] Notifications par email
- [ ] Dashboard analytics avancé

### v1.2 - Q2 2025
- [ ] Mode multi-entreprises
- [ ] Application mobile native
- [ ] API publique avec documentation Swagger
- [ ] Intégrations comptables (Sage, Cegid)

### v2.0 - Q3 2025
- [ ] Intelligence artificielle pour catégorisation
- [ ] Prédictions de trésorerie
- [ ] Synchronisation cloud temps réel
- [ ] Mode hors-ligne complet

---

## ⭐ Remerciements

Merci aux contributeurs et à la communauté Flutter pour leur excellent travail !


