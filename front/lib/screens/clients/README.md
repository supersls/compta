# Module de Gestion des Clients

## Vue d'ensemble

Le module de gestion des clients permet de gérer la base de données clients de votre entreprise. Il offre des fonctionnalités complètes de création, modification, consultation et suppression de clients.

## Fonctionnalités

### Liste des clients
- Affichage de tous les clients
- Recherche par nom, email, SIRET ou ville
- Filtrage par statut (actif/inactif)
- Vue d'ensemble avec avatar et informations principales

### Formulaire client
- Création de nouveaux clients
- Modification de clients existants
- Validation des données :
  - Nom obligatoire
  - Email valide (optionnel)
  - SIRET de 14 chiffres (optionnel)
  - Téléphone français (optionnel)

### Détail client
- Vue complète des informations du client
- Statistiques :
  - Nombre de factures
  - Total TTC facturé
  - Montant payé
  - Reste à payer
- Historique des factures
- Actions : modifier, activer/désactiver, supprimer

## Base de données

### Table `clients`

```sql
CREATE TABLE clients (
  id SERIAL PRIMARY KEY,
  nom VARCHAR(255) NOT NULL,
  siret VARCHAR(14),
  adresse TEXT,
  code_postal VARCHAR(10),
  ville VARCHAR(100),
  pays VARCHAR(100) DEFAULT 'France',
  email VARCHAR(255),
  telephone VARCHAR(20),
  contact_principal VARCHAR(255),
  tva_intracommunautaire VARCHAR(20),
  conditions_paiement VARCHAR(50),
  notes TEXT,
  actif BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## API Backend

### Endpoints disponibles

#### GET /api/clients
Récupère tous les clients
```json
[
  {
    "id": 1,
    "nom": "Société ABC",
    "email": "contact@abc.com",
    "actif": true,
    ...
  }
]
```

#### GET /api/clients/actifs
Récupère uniquement les clients actifs

#### GET /api/clients/:id
Récupère un client par son ID

#### GET /api/clients/:id/factures
Récupère toutes les factures d'un client

#### GET /api/clients/:id/stats
Récupère les statistiques d'un client
```json
{
  "nombre_factures": 5,
  "total_ttc": 12500.00,
  "total_paye": 10000.00,
  "reste_a_payer": 2500.00
}
```

#### POST /api/clients
Crée un nouveau client

#### PUT /api/clients/:id
Met à jour un client existant

#### PATCH /api/clients/:id/toggle-actif
Active ou désactive un client

#### DELETE /api/clients/:id
Supprime un client (seulement si aucune facture n'est associée)

## Frontend Flutter

### Structure des fichiers

```
front/lib/
├── models/
│   └── client.dart                 # Modèle de données Client
├── services/
│   └── client_service.dart         # Service API pour les clients
└── screens/
    └── clients/
        ├── clients_list_screen.dart     # Liste des clients
        ├── client_form_screen.dart      # Formulaire de création/édition
        └── client_detail_screen.dart    # Détails d'un client
```

### Modèle Client

```dart
class Client {
  final int? id;
  final String nom;
  final String? siret;
  final String? adresse;
  final String? email;
  final bool actif;
  // ... autres champs
}
```

### Service Client

```dart
class ClientService {
  Future<List<Client>> getAllClients();
  Future<Client?> getClientById(int id);
  Future<Client> createClient(Client client);
  Future<Client> updateClient(Client client);
  Future<void> deleteClient(int id);
  Future<Client> toggleActif(int id);
  Future<Map<String, dynamic>> getClientStats(int id);
}
```

## Navigation

Le module Clients est accessible depuis le menu principal de l'application, positionné entre "Tableau de bord" et "Factures".

## Validation des données

### Champs obligatoires
- Nom du client

### Champs optionnels avec validation
- Email : format email valide
- SIRET : exactement 14 chiffres
- Téléphone : format français (10 chiffres)

## Gestion des suppressions

Un client ne peut être supprimé que s'il n'a aucune facture associée. Si des factures existent, le système recommande de désactiver le client plutôt que de le supprimer.

## Statut actif/inactif

Les clients peuvent être marqués comme actifs ou inactifs. Les clients inactifs :
- Restent dans la base de données
- Apparaissent avec un badge "Inactif"
- Peuvent être filtrés dans la liste
- Conservent leur historique de factures

## Intégration avec les factures

Le module clients s'intègre avec le module factures :
- Affichage des factures par client
- Statistiques de facturation
- Calcul des montants payés et à payer
