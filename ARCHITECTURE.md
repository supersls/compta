# Architecture du Projet - Compta EI

## 📁 Structure des Dossiers

```
compta/
│
├── front/                      # 🎨 Frontend Flutter
│   ├── lib/
│   │   ├── config/            # Configuration (API, constantes)
│   │   ├── models/            # Modèles de données (Facture, etc.)
│   │   ├── screens/           # Écrans de l'application
│   │   │   └── factures/      # Gestion des factures
│   │   ├── services/          # Services HTTP (API calls)
│   │   ├── utils/             # Utilitaires (formatters, validators)
│   │   └── main.dart          # Point d'entrée
│   ├── web/                   # Configuration Web
│   ├── test/                  # Tests unitaires
│   ├── pubspec.yaml           # Dépendances Flutter
│   └── README.md              # Documentation Frontend
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
│   │   └── entreprise.js      # API Entreprise
│   ├── scripts/
│   │   └── initDB.js          # Script d'initialisation DB
│   ├── server.js              # Point d'entrée Express
│   ├── package.json           # Dépendances Node.js
│   ├── Dockerfile             # Image Docker backend
│   ├── API_TESTS.md           # Tests API (curl/PowerShell)
│   └── README.md              # Documentation Backend
│
├── docker-compose.yml          # 🐳 Orchestration Docker
├── init.sql                    # 📊 Schéma PostgreSQL initial
├── archi.md                    # 📐 Spécifications techniques
├── README.md                   # 📖 Documentation principale
├── QUICKSTART.md               # 🚀 Guide démarrage rapide
├── start.sh                    # 🎬 Script démarrage (Linux/Mac)
└── start.bat                   # 🎬 Script démarrage (Windows)
```

## 🔄 Flux de Données

```
┌──────────────┐         HTTP REST API        ┌──────────────┐
│              │◄───────────────────────────►│              │
│   Flutter    │      localhost:3000/api      │   Node.js    │
│   Frontend   │                              │   Express    │
│              │                              │              │
└──────────────┘                              └──────┬───────┘
                                                     │
                                                     │ SQL
                                                     ▼
                                              ┌──────────────┐
                                              │  PostgreSQL  │
                                              │  Database    │
                                              │  :5432       │
                                              └──────────────┘
```

## 🎯 Technologies Utilisées

### Frontend
- **Framework**: Flutter 3.x
- **Langage**: Dart 3.0+
- **UI**: Material Design 3
- **State Management**: Provider
- **HTTP Client**: package:http
- **Plateformes**: Web, Android, iOS, Windows, macOS, Linux

### Backend
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Validation**: express-validator
- **CORS**: cors middleware
- **ORM**: pg (PostgreSQL native driver)

### Database
- **SGBD**: PostgreSQL 16
- **Admin**: pgAdmin 4
- **Schema**: 12 tables (PCG, factures, TVA, etc.)

### DevOps
- **Containerisation**: Docker + Docker Compose
- **Services**:
  - PostgreSQL: port 5432
  - Backend API: port 3000
  - pgAdmin: port 5050

## 🌐 Endpoints API

### Base URL
```
http://localhost:3000/api
```

### Routes Principales
- `/factures` - CRUD factures + stats
- `/tva` - Déclarations et calculs TVA
- `/banque` - Comptes et transactions
- `/immobilisations` - Immobilisations et amortissements
- `/comptabilite` - Écritures, plan comptable, balance
- `/entreprise` - Informations entreprise

Voir [backend/API_TESTS.md](backend/API_TESTS.md) pour la documentation complète.

## 📦 Déploiement

### Développement
```bash
./start.sh   # ou start.bat sur Windows
```

### Production

#### Backend
```bash
cd backend
npm ci --only=production
NODE_ENV=production node server.js
```

#### Frontend Web
```bash
cd front
flutter build web
# Déployer le contenu de front/build/web
```

#### Frontend Mobile
```bash
cd front
flutter build apk          # Android
flutter build ios          # iOS
flutter build windows      # Windows
```

## 🔐 Sécurité

### Développement
- Credentials par défaut dans `.env`
- CORS ouvert pour développement local
- Pas d'authentification (à implémenter)

### Production (TODO)
- [ ] Authentification JWT
- [ ] CORS restreint aux domaines autorisés
- [ ] Rate limiting
- [ ] Variables d'environnement sécurisées
- [ ] HTTPS obligatoire
- [ ] Logs centralisés
- [ ] Backup automatique base de données

## 📈 Performance

### Backend
- Connection pooling PostgreSQL
- Réponses JSON compressées
- Cache Redis (TODO)

### Frontend
- Lazy loading des routes
- Images optimisées
- Code splitting automatique (Flutter Web)
- Service Worker (PWA ready)

## 🧪 Tests

### Backend
```bash
cd backend
npm test  # TODO: Ajouter tests
```

### Frontend
```bash
cd front
flutter test
```

## 📝 Standards de Code

### Backend
- ESLint configuration (TODO)
- Prettier formatting
- Commentaires JSDoc

### Frontend
- Dart analyzer (analysis_options.yaml)
- Formatage automatique (`flutter format`)
- Conventions de nommage Flutter

## 🔗 Liens Utiles

- [Documentation Flutter](https://flutter.dev/docs)
- [Documentation Express](https://expressjs.com/)
- [Documentation PostgreSQL](https://www.postgresql.org/docs/)
- [Docker Documentation](https://docs.docker.com/)

## 📞 Support

Pour toute question :
1. Consulter [README.md](README.md)
2. Consulter [QUICKSTART.md](QUICKSTART.md)
3. Vérifier [archi.md](archi.md) pour les specs
4. Tester l'API avec [backend/API_TESTS.md](backend/API_TESTS.md)
