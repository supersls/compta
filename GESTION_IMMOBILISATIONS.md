# Gestion des Immobilisations - Documentation

## Vue d'ensemble

Le module de gestion des immobilisations est maintenant complètement implémenté avec les fonctionnalités suivantes:

### ✅ Fonctionnalités implémentées

#### 1. **Modèle de données** (`immobilisation.dart`)
- Immobilisation avec tous les champs nécessaires
- Types: `materiel`, `vehicule`, `logiciel`, `immobilier`
- Méthodes d'amortissement: `lineaire`, `degressif`
- Propriétés calculées:
  - `tauxAmortissementCalcule` - Taux selon la méthode et la durée
  - `totalAmorti` - Montant total amorti
  - `pourcentageAmorti` - Pourcentage d'amortissement
  - `anneesRestantes` - Années restantes d'amortissement
  - `estCedee` - Indicateur de cession

#### 2. **Service HTTP** (`immobilisation_service.dart`)
- **CRUD complet**:
  - `getAllImmobilisations()` - Liste toutes les immobilisations
  - `createImmobilisation()` - Créer une nouvelle immobilisation
  - `updateImmobilisation()` - Modifier une immobilisation
  - `deleteImmobilisation()` - Supprimer une immobilisation

- **Gestion des amortissements**:
  - `getAllAmortissements()` - Tous les amortissements
  - `getAmortissementsByImmobilisation()` - Amortissements d'une immobilisation
  - `createAmortissement()` - Enregistrer un amortissement
  - `calculerAmortissement()` - Calculer amortissement pour une année

- **Cession**:
  - `cederImmobilisation()` - Enregistrer la cession

- **Statistiques et analyses**:
  - `getStatistiques()` - Statistiques globales
  - `getParCategorie()` - Répartition par catégorie
  - `calculerPlanAmortissement()` - Plan d'amortissement complet (client-side)

#### 3. **Écrans Flutter**

##### **Liste des immobilisations** (`immobilisations_list_screen.dart`)
- Affichage des immobilisations avec icônes par type
- Statistiques en haut:
  - Valeur d'acquisition totale
  - Valeur nette comptable (VNC)
  - Total amorti
- Filtrage par:
  - Toutes
  - Actives (non cédées)
  - Cédées
  - Par type (matériel, véhicule, logiciel, immobilier)
- Barre de progression d'amortissement par immobilisation
- Badge "Cédée" pour les immobilisations cédées
- Navigation vers formulaire et détail
- État vide avec CTA

##### **Formulaire** (`immobilisation_form_screen.dart`)
- Informations générales:
  - Désignation
  - Type (dropdown)
  - Date d'acquisition (date picker)
  - Valeur d'acquisition
- Paramètres d'amortissement:
  - Méthode (linéaire/dégressif)
  - Durée en années
  - Taux personnalisé (optionnel)
  - Calcul automatique du taux
- Notes optionnelles
- **Aperçu du plan d'amortissement** (nouveau):
  - Tableau avec année, dotation, VNC
  - Mise à jour en temps réel
  - Affichage uniquement en création
- Validation des données

##### **Détail** (`immobilisation_detail_screen.dart`)
- Informations complètes avec icône par type
- Badge "CÉDÉE" si applicable
- État d'amortissement:
  - Total amorti
  - Progression (pourcentage + barre)
  - Années restantes
- **Plan d'amortissement complet**:
  - Tableau DataTable avec:
    - Année
    - Dotation
    - Cumul
    - VNC
    - Statut (✓ comptabilisé ou ⏳ en attente)
- Actions disponibles (si non cédée):
  - Enregistrer un amortissement
  - Céder l'immobilisation
- Modification et suppression

#### 4. **API Backend** (`backend/routes/immobilisations.js`)

Toutes les routes sont implémentées:

```
GET    /api/immobilisations                          - Liste des immobilisations
POST   /api/immobilisations                          - Créer immobilisation
PUT    /api/immobilisations/:id                      - Modifier immobilisation
DELETE /api/immobilisations/:id                      - Supprimer immobilisation
POST   /api/immobilisations/:id/cession              - Céder immobilisation

GET    /api/immobilisations/amortissements           - Tous les amortissements
GET    /api/immobilisations/:id/amortissements       - Amortissements d'une immo
POST   /api/immobilisations/amortissements           - Créer amortissement
GET    /api/immobilisations/:id/amortissement/:annee - Calculer amortissement année

GET    /api/immobilisations/statistiques             - Statistiques globales
GET    /api/immobilisations/par-categorie            - Répartition par catégorie
```

## Méthodes d'amortissement

### Amortissement Linéaire

**Formule**: `Dotation annuelle = Valeur d'acquisition / Durée`

**Taux**: `100% / Durée (années)`

**Exemple**: 
- Ordinateur 1 200€, 3 ans
- Dotation = 1 200 / 3 = 400€/an
- Taux = 100 / 3 = 33,33%

**Prorata temporis**: Si acquisition en cours d'année, la première dotation est calculée au prorata des mois restants.

### Amortissement Dégressif

**Coefficient**:
- Durée ≤ 3 ans: `1.25`
- Durée 4-5 ans: `1.75`
- Durée > 5 ans: `2.25`

**Taux dégressif**: `Taux linéaire × Coefficient`

**Formule**: `Dotation = VNC début année × Taux dégressif`

**Passage au linéaire**: Lorsque la dotation linéaire devient supérieure à la dotation dégressive.

**Exemple**:
- Machine 10 000€, 5 ans
- Taux linéaire = 20%
- Taux dégressif = 20% × 1.75 = 35%
- Année 1: 10 000 × 35% = 3 500€ (VNC = 6 500€)
- Année 2: 6 500 × 35% = 2 275€ (VNC = 4 225€)
- Année 3: Passage au linéaire si plus avantageux

## Types d'immobilisations

### 🖥️ Matériel informatique (`materiel`)
- Ordinateurs, serveurs
- Périphériques
- Durée typique: 3-5 ans

### 🚗 Véhicules (`vehicule`)
- Voitures de fonction/service
- Utilitaires
- Durée typique: 4-5 ans

### 💻 Logiciels (`logiciel`)
- Licences perpétuelles
- Développements spécifiques
- Durée typique: 1-3 ans

### 🏢 Immobilier (`immobilier`)
- Constructions
- Aménagements
- Durée typique: 10-40 ans

## Workflow d'une immobilisation

```
1. Acquisition
   ↓ Création dans le système
2. En service
   ↓ Amortissement annuel
3. Amortissements comptabilisés
   ↓ Suivi du plan
4. Fin d'amortissement OU Cession
   ↓
5. Sortie du bilan
```

## Utilisation

### Créer une immobilisation
1. Aller dans "Immobilisations"
2. Cliquer sur "+" (nouvelle immobilisation)
3. Remplir le formulaire:
   - Désignation et type
   - Date et valeur d'acquisition
   - Méthode et durée d'amortissement
4. Vérifier l'aperçu du plan
5. Enregistrer

### Enregistrer un amortissement
1. Ouvrir le détail de l'immobilisation
2. Cliquer sur "Enregistrer un amortissement"
3. Saisir l'année
4. Valider (calcul automatique)

### Céder une immobilisation
1. Ouvrir le détail
2. Cliquer sur "Céder l'immobilisation"
3. Sélectionner la date de cession
4. Optionnel: saisir le prix de cession
5. Valider

## Calculs automatiques

### Plan d'amortissement
Le système calcule automatiquement:
- Les dotations annuelles
- Le cumul des amortissements
- La VNC (Valeur Nette Comptable)
- Le prorata temporis première année

### Taux d'amortissement
Si non spécifié manuellement:
- **Linéaire**: 100 / durée
- **Dégressif**: (100 / durée) × coefficient

### VNC mise à jour
À chaque enregistrement d'amortissement, la VNC de l'immobilisation est automatiquement mise à jour.

## Statistiques

Le dashboard affiche:
- **Total acquisition**: Somme des valeurs d'acquisition
- **Total VNC**: Somme des valeurs nettes comptables
- **Total amorti**: Différence entre acquisition et VNC
- Nombre d'immobilisations actives/cédées

## Sécurité et validations

### Restrictions
- ❌ Impossible de supprimer une immobilisation avec amortissements enregistrés
- ❌ Impossible de modifier une immobilisation cédée
- ✅ Suppression cascade des amortissements lors de la suppression d'une immobilisation sans amortissements

### Validations
- Durée d'amortissement > 0
- Valeur d'acquisition > 0
- Date d'acquisition ≤ aujourd'hui
- Année d'amortissement dans la période de la durée

## Intégration

Le module Immobilisations est intégré dans le dashboard principal (`main.dart`):
- Accessible depuis le menu latéral
- Icône: 💼 (business_center)
- Position: 5ème élément du menu

## Base de données

### Table `immobilisations`

```sql
CREATE TABLE immobilisations (
  id SERIAL PRIMARY KEY,
  designation VARCHAR(255) NOT NULL,
  categorie VARCHAR(50) NOT NULL,
  date_acquisition DATE NOT NULL,
  valeur_acquisition DECIMAL(10, 2) NOT NULL,
  duree_amortissement INTEGER NOT NULL,
  methode_amortissement VARCHAR(20) DEFAULT 'lineaire',
  taux_amortissement DECIMAL(5, 2),
  valeur_nette_comptable DECIMAL(10, 2) NOT NULL,
  date_cession DATE,
  prix_cession DECIMAL(10, 2),
  notes TEXT,
  date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Table `amortissements`

```sql
CREATE TABLE amortissements (
  id SERIAL PRIMARY KEY,
  immobilisation_id INTEGER REFERENCES immobilisations(id),
  annee INTEGER NOT NULL,
  montant DECIMAL(10, 2) NOT NULL,
  valeur_nette_comptable DECIMAL(10, 2) NOT NULL,
  date_comptabilisation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Prochaines étapes

Pour améliorer le module Immobilisations:

1. **Export PDF** - Générer le plan d'amortissement en PDF
2. **Graphiques** - Visualisation de l'évolution des amortissements
3. **Alertes** - Notifications de fin d'amortissement
4. **Import** - Import CSV d'immobilisations
5. **Maintenance** - Suivi des maintenances et réparations
6. **Photos** - Ajout de photos des immobilisations
7. **QR Codes** - Génération de codes pour inventaire
8. **Rapports** - Rapports d'analyse par catégorie/année

## Conformité comptable

Le module respecte:
- Le Plan Comptable Général (PCG) français
- Les règles d'amortissement linéaire et dégressif
- Le prorata temporis première année
- La comptabilisation des cessions
- Le suivi de la VNC

## Notes techniques

- Les calculs d'amortissement sont effectués côté serveur pour l'enregistrement
- Le plan d'amortissement est calculé côté client pour l'aperçu (performance)
- La VNC est mise à jour automatiquement lors de l'enregistrement d'un amortissement
- Les taux dégressifs suivent les coefficients légaux français
- Le passage au linéaire en dégressif est automatique
