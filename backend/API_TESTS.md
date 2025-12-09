# Tests API - Compta EI

Collection de tests pour l'API REST.

## Health Check

```bash
curl http://localhost:3000/health
```

## Factures

### Lister toutes les factures
```bash
curl http://localhost:3000/api/factures
```

### Générer un numéro de facture
```bash
curl -X POST http://localhost:3000/api/factures/generer-numero \
  -H "Content-Type: application/json" \
  -d '{"type": "vente"}'
```

### Créer une facture de vente
```bash
curl -X POST http://localhost:3000/api/factures \
  -H "Content-Type: application/json" \
  -d '{
    "numero": "FAC-2024-0001",
    "type": "vente",
    "date_emission": "2024-12-09",
    "date_echeance": "2025-01-09",
    "client_fournisseur": "SARL Dupont",
    "siret_client": "12345678901234",
    "montant_ht": 1000.00,
    "montant_tva": 200.00,
    "montant_ttc": 1200.00,
    "statut": "en_attente",
    "categorie": "prestations_services",
    "notes": "Prestation de conseil"
  }'
```

### Créer une facture d'achat
```bash
curl -X POST http://localhost:3000/api/factures \
  -H "Content-Type: application/json" \
  -d '{
    "numero": "ACH-2024-0001",
    "type": "achat",
    "date_emission": "2024-12-01",
    "client_fournisseur": "Fournisseur Martin",
    "montant_ht": 500.00,
    "montant_tva": 100.00,
    "montant_ttc": 600.00,
    "statut": "en_attente"
  }'
```

### Obtenir les statistiques
```bash
curl http://localhost:3000/api/factures/stats/overview
```

### Rechercher des factures
```bash
curl -X POST http://localhost:3000/api/factures/search \
  -H "Content-Type: application/json" \
  -d '{"query": "Dupont"}'
```

### Factures en retard
```bash
curl http://localhost:3000/api/factures/filter/retard
```

### Mettre à jour une facture
```bash
curl -X PUT http://localhost:3000/api/factures/1 \
  -H "Content-Type: application/json" \
  -d '{
    "numero": "FAC-2024-0001",
    "type": "vente",
    "date_emission": "2024-12-09",
    "client_fournisseur": "SARL Dupont (Modifié)",
    "montant_ht": 1500.00,
    "montant_tva": 300.00,
    "montant_ttc": 1800.00,
    "statut": "en_attente"
  }'
```

### Mettre à jour le statut (paiement)
```bash
curl -X PATCH http://localhost:3000/api/factures/1/statut \
  -H "Content-Type: application/json" \
  -d '{"montant_paye": 1200.00}'
```

### Supprimer une facture
```bash
curl -X DELETE http://localhost:3000/api/factures/1
```

## TVA

### Calcul TVA pour une période
```bash
curl http://localhost:3000/api/tva/calcul/2024-01-01/2024-12-31
```

### Liste des déclarations TVA
```bash
curl http://localhost:3000/api/tva/declarations
```

### Créer une déclaration TVA
```bash
curl -X POST http://localhost:3000/api/tva/declarations \
  -H "Content-Type: application/json" \
  -d '{
    "periode_debut": "2024-01-01",
    "periode_fin": "2024-03-31",
    "tva_collectee": 5000.00,
    "tva_deductible": 2000.00,
    "statut": "en_cours"
  }'
```

## Plan Comptable

### Liste du plan comptable
```bash
curl http://localhost:3000/api/comptabilite/plan-comptable
```

### Grand livre pour une période
```bash
curl http://localhost:3000/api/comptabilite/grand-livre/2024-01-01/2024-12-31
```

### Balance comptable
```bash
curl http://localhost:3000/api/comptabilite/balance/2024-01-01/2024-12-31
```

## Entreprise

### Informations entreprise
```bash
curl http://localhost:3000/api/entreprise
```

### Créer/Mettre à jour entreprise
```bash
curl -X POST http://localhost:3000/api/entreprise \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "Mon Entreprise",
    "forme_juridique": "EI",
    "siret": "12345678901234",
    "adresse": "123 Rue Example",
    "code_postal": "75001",
    "ville": "Paris",
    "telephone": "0123456789",
    "email": "contact@monentreprise.fr",
    "regime_tva": "reel_normal",
    "debut_exercice": "2024-01-01",
    "fin_exercice": "2024-12-31"
  }'
```

## Tests avec jq (pretty print JSON)

Si vous avez `jq` installé :

```bash
curl http://localhost:3000/api/factures | jq '.'
curl http://localhost:3000/api/factures/stats/overview | jq '.'
```

## Tests depuis PowerShell (Windows)

### Health Check
```powershell
Invoke-RestMethod -Uri "http://localhost:3000/health" -Method Get
```

### Lister les factures
```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/factures" -Method Get
```

### Créer une facture
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
