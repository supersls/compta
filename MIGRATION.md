# 📦 Organisation du Projet - Migration Terminée

Le projet a été réorganisé pour une meilleure séparation des responsabilités :

## ✅ Nouvelle Structure

```
compta/
├── 🎨 front/              Frontend Flutter (web, mobile, desktop)
├── 🚀 backend/            Backend Node.js + Express REST API
├── 🐳 docker-compose.yml  Orchestration des services
├── 📊 init.sql            Schéma PostgreSQL
└── 📚 Documentation       README, QUICKSTART, ARCHITECTURE
```

## 🔄 Changements Effectués

### Frontend
- ✅ Code Flutter déplacé dans `/front`
- ✅ Configuration API pointant vers `http://localhost:3000`
- ✅ Utilisation de `package:http` au lieu de `sqflite`
- ✅ Service HTTP générique créé
- ✅ README spécifique au frontend

### Backend
- ✅ API REST complète avec Node.js + Express
- ✅ Routes pour : factures, TVA, banque, immobilisations, comptabilité
- ✅ Validation des données
- ✅ Connexion PostgreSQL via pg
- ✅ Dockerfile pour le backend
- ✅ Documentation API avec exemples

### Infrastructure
- ✅ Docker Compose mis à jour avec 3 services :
  - PostgreSQL (port 5432)
  - Backend API (port 3000)
  - pgAdmin (port 5050)
- ✅ Scripts de démarrage mis à jour (`start.sh` / `start.bat`)

## 🚀 Démarrage Rapide

### Option 1 : Script automatique
```bash
./start.sh        # Linux/Mac
start.bat         # Windows
```

### Option 2 : Manuel
```bash
# 1. Démarrer l'infrastructure
docker-compose up -d

# 2. Lancer le frontend
cd front
flutter pub get
flutter run -d chrome
```

## 📁 Fichiers Importants

| Fichier | Description |
|---------|-------------|
| `QUICKSTART.md` | Guide de démarrage rapide |
| `ARCHITECTURE.md` | Architecture détaillée du projet |
| `README.md` | Documentation principale |
| `front/README.md` | Documentation frontend Flutter |
| `backend/README.md` | Documentation backend Node.js |
| `backend/API_TESTS.md` | Tests et exemples d'API |
| `archi.md` | Spécifications fonctionnelles |

## 🌐 URLs des Services

| Service | URL | Credentials |
|---------|-----|-------------|
| Backend API | http://localhost:3000 | - |
| Health Check | http://localhost:3000/health | - |
| pgAdmin | http://localhost:5050 | admin@compta.fr / admin123 |
| PostgreSQL | localhost:5432 | postgres / postgres |

## 📝 Prochaines Étapes

1. **Démarrer les services** : `./start.sh` ou `start.bat`
2. **Vérifier le backend** : http://localhost:3000/health
3. **Tester l'API** : Voir `backend/API_TESTS.md`
4. **Développer** : Modifier le code dans `front/` ou `backend/`

## 🛠️ Développement

### Frontend Flutter
```bash
cd front
flutter run -d chrome      # Web
flutter run -d windows     # Windows
flutter test               # Tests
```

### Backend Node.js
```bash
cd backend
npm run dev                # Mode développement
npm start                  # Mode production
npm run init-db            # Vérifier la base de données
```

## 📚 Documentation

- **Architecture** : Lire `ARCHITECTURE.md`
- **API** : Consulter `backend/API_TESTS.md`
- **Frontend** : Voir `front/README.md`
- **Backend** : Voir `backend/README.md`
- **Démarrage** : Suivre `QUICKSTART.md`

## 🎯 État du Projet

✅ **Terminé** :
- Architecture frontend/backend séparée
- API REST complète
- Gestion des factures (CRUD)
- Interface admin Flutter
- Docker orchestration
- Documentation complète

🚧 **À implémenter** (voir `archi.md`) :
- Gestion TVA complète
- Gestion bancaire
- Immobilisations
- Documents comptables (PDF/Excel)
- Authentification
- Tests automatisés

## 💡 Conseils

1. **Premier lancement** : Utiliser `./start.sh` pour tout démarrer automatiquement
2. **Développement frontend** : Lancer uniquement `cd front && flutter run -d chrome`
3. **Développement backend** : Lancer uniquement `cd backend && npm run dev`
4. **Réinitialiser** : `docker-compose down -v` puis `docker-compose up -d`
5. **Logs** : `docker-compose logs -f` pour suivre tous les services

## 🆘 Aide

En cas de problème :
1. Vérifier que Docker est démarré
2. Vérifier les logs : `docker-compose logs`
3. Consulter `QUICKSTART.md` section "Dépannage"
4. Vérifier que les ports 3000, 5432, 5050 sont disponibles

Bon développement ! 🚀
