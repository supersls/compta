# Backend REST API - Compta EI

API REST pour l'application de comptabilité d'Entreprise Individuelle.

## 🚀 Démarrage rapide

### Installation

```bash
cd backend
npm install
```

### Configuration

Créer un fichier `.env` (déjà fourni) avec :
```
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=compta_ei
DB_USER=postgres
DB_PASSWORD=postgres
```

### Lancement

```bash
# Démarrer PostgreSQL via Docker
cd ..
docker-compose up -d

# Vérifier la base de données
npm run init-db

# Démarrer le serveur
npm start

# Ou en mode développement (auto-reload)
npm run dev
```

Le serveur démarre sur `http://localhost:3000`

## 📚 API Endpoints

### Factures (`/api/factures`)

- `GET /` - Liste toutes les factures
- `GET /:id` - Facture par ID
- `GET /type/:type` - Factures par type (vente/achat)
- `GET /statut/:statut` - Factures par statut
- `GET /filter/retard` - Factures en retard
- `GET /stats/overview` - Statistiques globales
- `GET /periode/:debut/:fin` - Factures par période
- `POST /search` - Recherche factures
- `POST /generer-numero` - Génère un numéro de facture
- `POST /` - Créer une facture
- `PUT /:id` - Mettre à jour une facture
- `PATCH /:id/statut` - Mettre à jour le statut
- `DELETE /:id` - Supprimer une facture

### TVA (`/api/tva`)

- `GET /declarations` - Liste des déclarations TVA
- `GET /calcul/:debut/:fin` - Calcul TVA pour une période
- `POST /declarations` - Créer une déclaration TVA

### Banque (`/api/banque`)

- `GET /comptes` - Liste des comptes bancaires
- `GET /transactions` - Liste des transactions
- `GET /comptes/:id/transactions` - Transactions d'un compte
- `POST /comptes` - Créer un compte bancaire
- `POST /transactions` - Créer une transaction

### Immobilisations (`/api/immobilisations`)

- `GET /` - Liste des immobilisations
- `GET /amortissements` - Liste des amortissements
- `POST /` - Créer une immobilisation
- `POST /amortissements` - Créer un amortissement

### Comptabilité (`/api/comptabilite`)

- `GET /ecritures` - Liste des écritures comptables
- `GET /plan-comptable` - Plan comptable général
- `GET /grand-livre/:debut/:fin` - Grand livre
- `GET /balance/:debut/:fin` - Balance comptable
- `POST /ecritures` - Créer une écriture comptable

### Entreprise (`/api/entreprise`)

- `GET /` - Informations entreprise
- `POST /` - Créer/Mettre à jour entreprise

### Justificatifs (`/api/justificatifs`)

- `GET /` - Liste des justificatifs (filtrable)
- `GET /:id` - Récupérer un justificatif
- `GET /:id/download` - Télécharger le fichier
- `GET /:id/view` - Visualiser le fichier inline
- `GET /:id/history` - Historique des actions
- `GET /stats/summary` - Statistiques de stockage
- `POST /upload` - Upload un justificatif (multipart/form-data)
- `POST /:id/archive` - Archiver un justificatif
- `PUT /:id` - Mettre à jour les métadonnées
- `DELETE /:id` - Supprimer un justificatif

📖 **Documentation complète** : [JUSTIFICATIFS.md](./JUSTIFICATIFS.md)

### Templates (`/api/templates`)

- `GET /` - Liste des templates disponibles
- `GET /:name` - Récupérer un template
- `POST /` - Créer un nouveau template
- `PUT /:name` - Mettre à jour un template
- `DELETE /:name` - Supprimer un template
- `POST /:name/reload` - Recharger un template

📖 **Documentation complète** : [templates/README.md](./templates/README.md)

## 🧪 Tests

```bash
# Test de santé
curl http://localhost:3000/health

# Lister les factures
curl http://localhost:3000/api/factures

# Créer une facture
curl -X POST http://localhost:3000/api/factures \
  -H "Content-Type: application/json" \
  -d '{
    "numero": "FAC-2024-0001",
    "type": "vente",
    "date_emission": "2024-01-15",
    "client_fournisseur": "Client Test",
    "montant_ht": 1000,
    "montant_tva": 200,
    "montant_ttc": 1200
  }'
```

## 🏗️ Structure

```
backend/
├── config/
│   └── database.js         # Configuration PostgreSQL
├── routes/
│   ├── factures.js         # Routes factures
│   ├── tva.js              # Routes TVA
│   ├── banque.js           # Routes bancaires
│   ├── immobilisations.js  # Routes immobilisations
│   ├── comptabilite.js     # Routes comptables
│   ├── entreprise.js       # Routes entreprise
│   ├── justificatifs.js    # Routes justificatifs (NEW)
│   ├── templates.js        # Routes templates (NEW)
│   └── documents.js        # Routes documents PDF
├── services/
│   ├── pdfGenerator.js     # Génération de PDF
│   ├── storageService.js   # Stockage abstrait (NEW)
│   ├── localStorageProvider.js   # Stockage local (NEW)
│   ├── cloudStorageProvider.js   # Stockage S3 (NEW)
│   └── templateService.js  # Gestion templates (NEW)
├── templates/              # Templates JSON pour PDF (NEW)
│   ├── compte_resultat.json
│   ├── bilan.json
│   └── facture.json
├── storage/                # Stockage local des fichiers (NEW)
│   └── justificatifs/
│       └── archives/
├── migrations/             # Migrations SQL
│   ├── 001_create_tables.sql
│   ├── 002_seed_data.sql
│   └── 003_create_justificatifs.sql (NEW)
├── scripts/
│   └── initDB.js           # Script init DB
├── .env                    # Variables d'environnement
├── .env.storage.example    # Config stockage (NEW)
├── server.js               # Point d'entrée
└── package.json
```

## 🔒 Sécurité

- Validation des données avec `express-validator`
- CORS activé pour le développement
- Gestion des erreurs centralisée
- Protection contre les injections SQL (requêtes paramétrées)

## 📝 TODO

- [ ] Authentification JWT
- [ ] Rate limiting
- [ ] Logs structurés
- [ ] Tests unitaires
- [ ] Documentation OpenAPI/Swagger
- [ ] Cache Redis
