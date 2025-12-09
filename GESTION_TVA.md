# Gestion de la TVA - Documentation

## Vue d'ensemble

Le module de gestion de la TVA est maintenant complètement implémenté avec les fonctionnalités suivantes:

### ✅ Fonctionnalités implémentées

#### 1. **Modèle de données** (`declaration_tva.dart`)
- Déclaration TVA avec tous les champs nécessaires
- 4 statuts: `en_cours`, `validee`, `transmise`, `payee`
- Propriétés calculées: `estValidee`, `estTransmise`, `estPayee`, `libellePeriode`
- Méthodes: `toMap`, `fromMap`, `copyWith`

#### 2. **Service HTTP** (`tva_service.dart`)
- **CRUD complet**:
  - `getAllDeclarations()` - Liste toutes les déclarations
  - `createDeclaration()` - Créer une nouvelle déclaration
  - `updateDeclaration()` - Modifier une déclaration
  - `deleteDeclaration()` - Supprimer une déclaration

- **Workflow**:
  - `validerDeclaration(id)` - Valider une déclaration
  - `marquerTransmise(id)` - Marquer comme transmise
  - `marquerPayee(id)` - Marquer comme payée

- **Calculs et statistiques**:
  - `calculerTVA(debut, fin)` - Calculer TVA pour une période
  - `getDetailParTaux(debut, fin)` - Détail par taux de TVA
  - `getStatistiquesTVA()` - Statistiques annuelles

#### 3. **Écrans Flutter**

##### **Liste des déclarations** (`tva_list_screen.dart`)
- Affichage des déclarations avec badges de statut colorés
- Filtrage par statut (Toutes, En cours, Validée, Transmise, Payée)
- Statistiques en haut:
  - TVA collectée (vert)
  - TVA déductible (bleu)
  - TVA à décaisser (orange/rouge)
- Navigation vers:
  - Formulaire de création/modification
  - Détail d'une déclaration
  - Calculateur de TVA
- État vide avec bouton d'action

##### **Formulaire** (`declaration_tva_form_screen.dart`)
- Sélection de période avec calendrier
- Raccourcis de période:
  - Mois en cours / dernier
  - Trimestre en cours / dernier
- Saisie des montants:
  - TVA collectée (ventes)
  - TVA déductible (achats)
- Calcul automatique du TVA à décaisser
- Notes optionnelles
- Validation des données

##### **Détail** (`declaration_tva_detail_screen.dart`)
- Affichage complet de la déclaration
- Badge de statut visuel
- Période et montants détaillés
- Historique des dates (création, validation, transmission, paiement)
- Actions contextuelles selon le statut:
  - `Valider` (si en_cours)
  - `Marquer transmise` (si validee)
  - `Marquer payée` (si transmise)
- Modification (sauf si payée)
- Suppression (sauf si validée)

##### **Calculateur** (`calculateur_tva_screen.dart`)
- Sélection de période avec calendrier
- Raccourcis: mois, trimestre, année
- Calcul automatique depuis les factures
- Résultats détaillés:
  - TVA collectée
  - TVA déductible
  - TVA à décaisser
- Détail par taux de TVA (20%, 10%, 5.5%, 2.1%)
- Création de déclaration depuis le calcul
- Indication de crédit de TVA si négatif

#### 4. **API Backend** (`backend/routes/tva.js`)

Toutes les routes sont implémentées:

```
GET    /api/tva/declarations           - Liste des déclarations
GET    /api/tva/calcul/:debut/:fin     - Calculer TVA pour période
POST   /api/tva/declarations           - Créer déclaration
PUT    /api/tva/declarations/:id       - Modifier déclaration
DELETE /api/tva/declarations/:id       - Supprimer déclaration
PATCH  /api/tva/declarations/:id/valider      - Valider
PATCH  /api/tva/declarations/:id/transmettre  - Transmettre
PATCH  /api/tva/declarations/:id/payer        - Payer
GET    /api/tva/statistiques           - Statistiques annuelles
GET    /api/tva/detail-taux/:debut/:fin - Détail par taux
```

## Workflow de déclaration TVA

```
1. [En cours] 
   ↓ Utilisateur valide
2. [Validée]
   ↓ Transmission aux impôts
3. [Transmise]
   ↓ Paiement effectué
4. [Payée]
```

## Utilisation

### Créer une déclaration manuellement
1. Aller dans "TVA"
2. Cliquer sur "+" (nouvelle déclaration)
3. Sélectionner la période
4. Saisir les montants
5. Enregistrer

### Créer depuis le calculateur
1. Aller dans "TVA"
2. Cliquer sur "Calculer la TVA"
3. Sélectionner la période
4. Cliquer sur "Calculer"
5. Vérifier les résultats
6. Cliquer sur "Créer une déclaration depuis ce calcul"

### Workflow complet
1. Créer la déclaration
2. Vérifier et **Valider**
3. Transmettre aux impôts et **Marquer transmise**
4. Effectuer le paiement et **Marquer payée**

## Taux de TVA supportés

- **20%** - Taux normal
- **10%** - Taux intermédiaire
- **5.5%** - Taux réduit
- **2.1%** - Taux super-réduit

## Sécurité et validations

### Restrictions de modification
- ❌ Impossible de modifier une déclaration **payée**
- ❌ Impossible de supprimer une déclaration **validée**
- ✅ Modification autorisée si **en_cours**

### Validations
- Les dates doivent être cohérentes (début < fin)
- Les montants doivent être positifs
- Le statut suit un workflow linéaire

## Intégration

Le module TVA est intégré dans le dashboard principal (`main.dart`):
- Accessible depuis le menu latéral
- Icône: 💰 (money)
- Position: 3ème élément du menu

## Base de données

### Table `declarations_tva`

```sql
CREATE TABLE declarations_tva (
  id SERIAL PRIMARY KEY,
  periode_debut DATE NOT NULL,
  periode_fin DATE NOT NULL,
  tva_collectee DECIMAL(10, 2) NOT NULL,
  tva_deductible DECIMAL(10, 2) NOT NULL,
  tva_a_decaisser DECIMAL(10, 2) NOT NULL,
  statut VARCHAR(20) DEFAULT 'en_cours',
  notes TEXT,
  date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  date_validation TIMESTAMP,
  date_transmission TIMESTAMP,
  date_paiement TIMESTAMP
);
```

## Prochaines étapes

Pour améliorer le module TVA:

1. **Export PDF** - Générer la déclaration CA3 en PDF
2. **Télétransmission** - Intégration EDI avec les impôts
3. **Alertes** - Notifications de dates limites
4. **Historique** - Graphiques d'évolution de la TVA
5. **Régime TVA** - Support franchise en base / réel simplifié / réel normal

## Notes techniques

- Les calculs de TVA sont basés sur les factures existantes
- Le détail par taux utilise le champ `taux_tva` des factures
- Les dates de workflow sont enregistrées automatiquement
- Le crédit de TVA (négatif) est visuellement mis en évidence
