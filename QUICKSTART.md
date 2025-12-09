# 🚀 Guide de Démarrage Rapide

Ce guide vous permet de démarrer l'application en moins de 5 minutes.

## Prérequis

✅ [Docker Desktop](https://www.docker.com/products/docker-desktop/) installé et démarré  
✅ [Flutter SDK](https://flutter.dev/docs/get-started/install) installé  
✅ [Node.js](https://nodejs.org/) 18+ (optionnel pour développement backend)

## Démarrage en 3 étapes

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

#### 1. Démarrer l'infrastructure
```bash
docker-compose up -d
```
Attend 10 secondes que PostgreSQL démarre.

#### 2. Installer les dépendances Flutter
```bash
cd front
flutter pub get
cd ..
```

#### 3. Lancer l'application
```bash
cd front
flutter run -d chrome
```

## Vérification

### Backend API
Ouvrir http://localhost:3000/health

Vous devriez voir :
```json
{
  "status": "OK",
  "timestamp": "2024-12-09T..."
}
```

### pgAdmin
Ouvrir http://localhost:5050
- Email : `admin@compta.fr`
- Mot de passe : `admin123`

### Application Flutter
L'application devrait s'ouvrir dans Chrome avec le tableau de bord.

## Test rapide

### Créer une facture via l'API

**Windows PowerShell :**
```powershell
$body = @{
    numero = "FAC-2024-0001"
    type = "vente"
    date_emission = "2024-12-09"
    client_fournisseur = "Client Test"
    montant_ht = 1000
    montant_tva = 200
    montant_ttc = 1200
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3000/api/factures" `
  -Method Post `
  -ContentType "application/json" `
  -Body $body
```

**Linux/Mac (curl) :**
```bash
curl -X POST http://localhost:3000/api/factures \
  -H "Content-Type: application/json" \
  -d '{
    "numero": "FAC-2024-0001",
    "type": "vente",
    "date_emission": "2024-12-09",
    "client_fournisseur": "Client Test",
    "montant_ht": 1000,
    "montant_tva": 200,
    "montant_ttc": 1200
  }'
```

### Vérifier dans l'application
Rafraîchir la page "Factures" dans Flutter. La facture devrait apparaître.

## 📁 Structure du projet

```
compta/
├── front/              # Frontend Flutter
│   ├── lib/
│   ├── web/
│   └── pubspec.yaml
├── backend/            # Backend Node.js
│   ├── routes/
│   ├── config/
│   ├── server.js
│   └── package.json
├── docker-compose.yml
├── init.sql
└── README.md
```

## Dépannage

### Le backend ne démarre pas
```bash
# Voir les logs
### L'application Flutter ne se connecte pas
1. Vérifier que le backend fonctionne : http://localhost:3000/health
2. Vérifier la configuration dans `front/lib/config/api_config.dart`
3. Sur mobile/émulateur, remplacer `localhost` par l'IP de votre machine
```

### PostgreSQL ne répond pas
```bash
# Vérifier que PostgreSQL est lancé
docker-compose ps

# Voir les logs
docker-compose logs postgres

# Redémarrer
docker-compose restart postgres
```

### L'application Flutter ne se connecte pas
1. Vérifier que le backend fonctionne : http://localhost:3000/health
2. Vérifier la configuration dans `lib/config/api_config.dart`
3. Sur mobile/émulateur, remplacer `localhost` par l'IP de votre machine

### Port déjà utilisé
Si le port 3000, 5432 ou 5050 est déjà utilisé :
```bash
# Arrêter les conteneurs
docker-compose down

# Modifier les ports dans docker-compose.yml
# Puis relancer
docker-compose up -d
```

## Arrêter l'application

```bash
# Arrêter les conteneurs
docker-compose down

# Arrêter et supprimer les données (⚠️)
docker-compose down -v
```

## Étapes suivantes

✅ Lire la [documentation complète](README.md)  
✅ Explorer l'[architecture du projet](archi.md)  
✅ Tester l'[API REST](backend/API_TESTS.md)  
✅ Consulter le [plan de développement](archi.md#todo)

## Support

En cas de problème :
1. Vérifier les logs : `docker-compose logs -f`
2. Consulter la section dépannage ci-dessus
3. Vérifier que Docker Desktop est bien démarré
4. Redémarrer Docker Desktop si nécessaire

Bon développement ! 🎉
