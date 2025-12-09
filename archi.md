# Architecture - Application de Comptabilité EI (Flutter)

## 📋 Résumé du Projet

Application web et mobile de comptabilité pour Entreprise Individuelle (EI) au régime réel, développée avec Flutter. Permet à un entrepreneur de gérer sa comptabilité de manière autonome et conforme à la législation française.

---

## 🎯 Fonctionnalités Principales

### 1. **Gestion des Ventes et Achats**
- Référencement des factures clients et fournisseurs
- Catégorisation comptable (automatique/manuelle)
- Suivi des paiements et encaissements
- Statuts : En attente, Payée, Partiellement payée, En retard

### 2. **Gestion de la TVA**
- Calcul automatique de la TVA (20%, 10%, 5.5%, 2.1%)
- Génération de rapport de déclaration fiscale
- Suivi TVA collectée vs TVA déductible
- Export pour CA3 (déclaration mensuelle/trimestrielle)

### 3. **Gestion des Comptes Bancaires**
- Import/saisie des relevés bancaires (CSV, OFX)
- Rapprochement bancaire automatique/manuel
- Gestion multi-comptes
- Catégorisation des transactions

### 4. **Gestion des Immobilisations et Amortissements**
- Saisie des acquisitions d'actifs
- Calcul automatique des amortissements (linéaire, dégressif)
- Plan d'amortissement conforme au PCG (Plan Comptable Général)
- Gestion de la durée de vie et valeur résiduelle

### 5. **Documents Comptables**
- **Journal Comptable** : Chronologique des écritures
- **Grand Livre** : Synthèse par compte
- **Bilan Comptable** : Actif/Passif
- **Compte de Résultat** : Charges/Produits
- Export PDF et Excel

### 6. **Tableau de Bord et Alertes**
- KPIs : CA, Charges, Bénéfice, Trésorerie
- Graphiques d'évolution temporelle
- Alertes : Paiements en retard, échéances fiscales, seuils TVA

### 7. **Stockage des Données**
- Base de données locale : **SQLite**
- Option cloud : **Firebase** / **Supabase**
- Synchronisation multi-appareils
- Sauvegarde automatique et exportation

### 8. **Interface Utilisateur**
- Design Material Design 3
- Responsive (mobile, tablette, web)
- Navigation intuitive avec drawer et bottom navigation
- Thèmes clair/sombre
- Formulaires avec validation

### 9. **Conformité Légale**
- Traçabilité complète (horodatage, utilisateur)
- Pas de suppression d'écritures (uniquement rectifications)
- Numérotation séquentielle des écritures
- Préparation à la loi anti-fraude TVA (art. 88 LF 2018)
- Archivage 10 ans

---

## 🏗️ Architecture Technique

### Stack Technologique

```
Frontend:
├── Flutter 3.x (Dart)
├── Material Design 3
└── Responsive UI (mobile, tablet, web)

Backend/Data:
├── SQLite (stockage local)
├── Firebase / Supabase (optionnel cloud)
└── Shared Preferences (config utilisateur)

Packages Clés:
├── sqflite: Base de données locale
├── provider / riverpod: State management
├── pdf: Génération de documents PDF
├── excel: Export Excel
├── intl: Formatage dates/nombres français
├── fl_chart: Graphiques du dashboard
├── file_picker: Import fichiers bancaires
└── path_provider: Gestion des fichiers
```

### Structure du Projet

```
compta/
├── lib/
│   ├── main.dart                    # Point d'entrée
│   ├── app.dart                     # Configuration de l'app
│   │
│   ├── models/                      # Modèles de données
│   │   ├── facture.dart
│   │   ├── tva.dart
│   │   ├── compte_bancaire.dart
│   │   ├── transaction_bancaire.dart
│   │   ├── immobilisation.dart
│   │   ├── amortissement.dart
│   │   ├── ecriture_comptable.dart
│   │   ├── compte.dart
│   │   └── exercice_comptable.dart
│   │
│   ├── services/                    # Logique métier
│   │   ├── database_helper.dart     # SQLite
│   │   ├── facture_service.dart
│   │   ├── tva_service.dart
│   │   ├── banque_service.dart
│   │   ├── immobilisation_service.dart
│   │   ├── comptabilite_service.dart
│   │   ├── export_service.dart      # PDF/Excel
│   │   ├── rapprochement_service.dart
│   │   └── calcul_service.dart      # Calculs comptables
│   │
│   ├── screens/                     # Écrans de l'app
│   │   ├── home/
│   │   │   └── dashboard_screen.dart
│   │   ├── factures/
│   │   │   ├── factures_list_screen.dart
│   │   │   ├── facture_detail_screen.dart
│   │   │   └── facture_form_screen.dart
│   │   ├── tva/
│   │   │   ├── tva_dashboard_screen.dart
│   │   │   └── tva_declaration_screen.dart
│   │   ├── banque/
│   │   │   ├── comptes_bancaires_screen.dart
│   │   │   ├── transactions_screen.dart
│   │   │   └── rapprochement_screen.dart
│   │   ├── immobilisations/
│   │   │   ├── immobilisations_list_screen.dart
│   │   │   ├── immobilisation_form_screen.dart
│   │   │   └── plan_amortissement_screen.dart
│   │   └── documents/
│   │       ├── journal_screen.dart
│   │       ├── grand_livre_screen.dart
│   │       ├── bilan_screen.dart
│   │       └── compte_resultat_screen.dart
│   │
│   ├── widgets/                     # Composants réutilisables
│   │   ├── common/
│   │   │   ├── custom_app_bar.dart
│   │   │   ├── custom_drawer.dart
│   │   │   ├── loading_indicator.dart
│   │   │   └── error_widget.dart
│   │   ├── charts/
│   │   │   ├── revenue_chart.dart
│   │   │   ├── expense_chart.dart
│   │   │   └── tresorerie_chart.dart
│   │   ├── cards/
│   │   │   ├── kpi_card.dart
│   │   │   ├── facture_card.dart
│   │   │   └── alert_card.dart
│   │   └── forms/
│   │       ├── facture_form_widget.dart
│   │       ├── immobilisation_form_widget.dart
│   │       └── custom_text_field.dart
│   │
│   └── utils/                       # Utilitaires
│       ├── constants.dart           # Constantes (taux TVA, comptes)
│       ├── formatters.dart          # Formatage dates/montants
│       ├── validators.dart          # Validation formulaires
│       ├── date_utils.dart
│       └── pdf_templates.dart       # Templates PDF
│
├── pubspec.yaml                     # Dépendances
├── README.md
└── archi.md                         # Ce fichier
```

---

## 💾 Structure de la Base de Données

### Schéma SQLite

#### Table: **entreprise**
```sql
CREATE TABLE entreprise (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nom TEXT NOT NULL,
  siret TEXT UNIQUE,
  adresse TEXT,
  code_postal TEXT,
  ville TEXT,
  email TEXT,
  telephone TEXT,
  regime_tva TEXT DEFAULT 'reel_normal', -- reel_normal, reel_simplifie
  date_cloture_exercice TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

#### Table: **factures**
```sql
CREATE TABLE factures (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  numero TEXT UNIQUE NOT NULL,
  type TEXT NOT NULL, -- 'vente' ou 'achat'
  date_emission TEXT NOT NULL,
  date_echeance TEXT,
  client_fournisseur TEXT NOT NULL,
  siret_client TEXT,
  montant_ht REAL NOT NULL,
  montant_tva REAL NOT NULL,
  montant_ttc REAL NOT NULL,
  statut TEXT DEFAULT 'en_attente', -- en_attente, payee, partiellement_payee, en_retard
  montant_paye REAL DEFAULT 0,
  categorie TEXT, -- ventes_marchandises, prestations_services, achats, charges, etc.
  notes TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

#### Table: **paiements**
```sql
CREATE TABLE paiements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  facture_id INTEGER NOT NULL,
  date_paiement TEXT NOT NULL,
  montant REAL NOT NULL,
  mode_paiement TEXT, -- virement, cheque, especes, carte
  reference TEXT,
  compte_bancaire_id INTEGER,
  notes TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (facture_id) REFERENCES factures(id) ON DELETE CASCADE,
  FOREIGN KEY (compte_bancaire_id) REFERENCES comptes_bancaires(id)
);
```

#### Table: **comptes_bancaires**
```sql
CREATE TABLE comptes_bancaires (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nom TEXT NOT NULL,
  banque TEXT,
  numero_compte TEXT,
  iban TEXT,
  solde_initial REAL DEFAULT 0,
  solde_actuel REAL DEFAULT 0,
  date_ouverture TEXT,
  actif INTEGER DEFAULT 1,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

#### Table: **transactions_bancaires**
```sql
CREATE TABLE transactions_bancaires (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  compte_bancaire_id INTEGER NOT NULL,
  date_transaction TEXT NOT NULL,
  date_valeur TEXT,
  libelle TEXT NOT NULL,
  debit REAL DEFAULT 0,
  credit REAL DEFAULT 0,
  solde REAL,
  categorie TEXT,
  rapproche INTEGER DEFAULT 0, -- 0: non, 1: oui
  facture_id INTEGER, -- Lien vers facture si rapproché
  ecriture_id INTEGER, -- Lien vers écriture comptable
  notes TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (compte_bancaire_id) REFERENCES comptes_bancaires(id) ON DELETE CASCADE,
  FOREIGN KEY (facture_id) REFERENCES factures(id),
  FOREIGN KEY (ecriture_id) REFERENCES ecritures_comptables(id)
);
```

#### Table: **immobilisations**
```sql
CREATE TABLE immobilisations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  libelle TEXT NOT NULL,
  type TEXT NOT NULL, -- materiel, vehicule, logiciel, immobilier
  date_acquisition TEXT NOT NULL,
  valeur_acquisition REAL NOT NULL,
  duree_amortissement INTEGER NOT NULL, -- en années
  methode_amortissement TEXT DEFAULT 'lineaire', -- lineaire, degressif
  taux_amortissement REAL,
  valeur_residuelle REAL DEFAULT 0,
  compte_immobilisation TEXT, -- Ex: 2154, 2183
  compte_amortissement TEXT, -- Ex: 28154, 28183
  en_service INTEGER DEFAULT 1,
  date_cession TEXT,
  notes TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

#### Table: **amortissements**
```sql
CREATE TABLE amortissements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  immobilisation_id INTEGER NOT NULL,
  exercice INTEGER NOT NULL, -- Année
  annee INTEGER NOT NULL,
  montant_amortissement REAL NOT NULL,
  cumul_amortissements REAL NOT NULL,
  valeur_nette_comptable REAL NOT NULL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (immobilisation_id) REFERENCES immobilisations(id) ON DELETE CASCADE
);
```

#### Table: **ecritures_comptables**
```sql
CREATE TABLE ecritures_comptables (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  numero_piece TEXT NOT NULL,
  date_ecriture TEXT NOT NULL,
  journal TEXT NOT NULL, -- ventes, achats, banque, od (operations_diverses)
  compte TEXT NOT NULL, -- Numéro de compte PCG
  libelle TEXT NOT NULL,
  debit REAL DEFAULT 0,
  credit REAL DEFAULT 0,
  reference_externe TEXT, -- ID de facture, transaction, etc.
  type_reference TEXT, -- 'facture', 'transaction', 'immobilisation'
  lettrage TEXT, -- Pour rapprochement
  validee INTEGER DEFAULT 1,
  rectification_de INTEGER, -- ID de l'écriture rectifiée si applicable
  created_by TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (rectification_de) REFERENCES ecritures_comptables(id)
);
```

#### Table: **comptes_pcg**
```sql
CREATE TABLE comptes_pcg (
  numero TEXT PRIMARY KEY,
  libelle TEXT NOT NULL,
  classe INTEGER NOT NULL, -- 1-7
  type TEXT NOT NULL -- actif, passif, charge, produit
);
```

#### Table: **exercices_comptables**
```sql
CREATE TABLE exercices_comptables (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  annee INTEGER NOT NULL UNIQUE,
  date_debut TEXT NOT NULL,
  date_fin TEXT NOT NULL,
  cloture INTEGER DEFAULT 0,
  date_cloture TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

#### Table: **declarations_tva**
```sql
CREATE TABLE declarations_tva (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  periode_debut TEXT NOT NULL,
  periode_fin TEXT NOT NULL,
  tva_collectee REAL NOT NULL,
  tva_deductible REAL NOT NULL,
  tva_a_payer REAL NOT NULL,
  statut TEXT DEFAULT 'brouillon', -- brouillon, declaree, payee
  date_declaration TEXT,
  date_paiement TEXT,
  fichier_export TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

#### Table: **alertes**
```sql
CREATE TABLE alertes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL, -- paiement, tva, echeance
  titre TEXT NOT NULL,
  message TEXT,
  date_alerte TEXT NOT NULL,
  lue INTEGER DEFAULT 0,
  reference_id INTEGER,
  reference_type TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

---

## 🔧 Fonctions de Calcul Principales

### Calcul TVA
```dart
// Calcul TVA sur un montant HT
double calculerTVA(double montantHT, double tauxTVA) {
  return (montantHT * tauxTVA / 100).roundToDouble() / 100;
}

// Récupération du montant HT depuis TTC
double montantHTDepuisTTC(double montantTTC, double tauxTVA) {
  return (montantTTC / (1 + tauxTVA / 100)).roundToDouble() / 100;
}
```

### Calcul Amortissement Linéaire
```dart
double calculerAmortissementLineaire(
  double valeurAcquisition,
  int dureeAnnees,
  int anneeEnCours,
  DateTime dateAcquisition
) {
  double tauxAmortissement = 100 / dureeAnnees;
  
  // Prorata première année si acquisition en cours d'année
  if (anneeEnCours == dateAcquisition.year) {
    int joursRestants = DateTime(dateAcquisition.year, 12, 31)
        .difference(dateAcquisition).inDays + 1;
    return (valeurAcquisition * tauxAmortissement / 100) * (joursRestants / 365);
  }
  
  return valeurAcquisition * tauxAmortissement / 100;
}
```

### Calcul Amortissement Dégressif
```dart
double calculerAmortissementDegressif(
  double valeurAcquisition,
  int dureeAnnees,
  double vncDebut, // Valeur Nette Comptable début d'exercice
  int anneeEnCours
) {
  // Coefficient dégressif selon durée
  double coefficient = dureeAnnees >= 5 ? 2.25 : (dureeAnnees >= 3 ? 1.75 : 1.25);
  double tauxDegressif = (100 / dureeAnnees) * coefficient;
  
  double amortissementDegressif = vncDebut * tauxDegressif / 100;
  
  // Basculement vers linéaire si plus avantageux
  int anneesRestantes = dureeAnnees - anneeEnCours + 1;
  double amortissementLineaire = vncDebut / anneesRestantes;
  
  return amortissementDegressif > amortissementLineaire 
      ? amortissementDegressif 
      : amortissementLineaire;
}
```

---

## 📄 Export de Documents

### Génération Journal Comptable (PDF)
```dart
Future<File> genererJournalPDF(DateTime debut, DateTime fin, String journal) async {
  final pdf = pw.Document();
  final ecritures = await getEcrituresJournal(debut, fin, journal);
  
  pdf.addPage(
    pw.Page(
      build: (context) => pw.Column(
        children: [
          pw.Header(level: 0, child: pw.Text('Journal $journal')),
          pw.Text('Période: ${formatDate(debut)} - ${formatDate(fin)}'),
          pw.Table(
            headers: ['Date', 'Pièce', 'Compte', 'Libellé', 'Débit', 'Crédit'],
            data: ecritures.map((e) => [
              formatDate(e.date),
              e.numeroPiece,
              e.compte,
              e.libelle,
              formatMontant(e.debit),
              formatMontant(e.credit),
            ]).toList(),
          ),
        ],
      ),
    ),
  );
  
  return savePDF(pdf, 'journal_${journal}_${DateTime.now().millisecondsSinceEpoch}.pdf');
}
```

### Génération Bilan (PDF)
```dart
Future<File> genererBilanPDF(int exercice) async {
  final actifs = await getActifs(exercice);
  final passifs = await getPassifs(exercice);
  
  // Structure: Actif (immobilisations, stocks, créances, trésorerie)
  //           Passif (capitaux propres, dettes)
  
  // Génération similaire avec tables pour actif et passif
  // Total Actif = Total Passif (principe comptable)
}
```

### Export Excel
```dart
Future<File> exporterGrandLivreExcel(int exercice) async {
  var excel = Excel.createExcel();
  Sheet sheet = excel['Grand Livre'];
  
  sheet.appendRow(['Compte', 'Libellé', 'Débit', 'Crédit', 'Solde']);
  
  final comptes = await getComptesAvecMouvements(exercice);
  
  for (var compte in comptes) {
    sheet.appendRow([
      compte.numero,
      compte.libelle,
      compte.totalDebit,
      compte.totalCredit,
      compte.solde,
    ]);
  }
  
  return saveExcel(excel, 'grand_livre_$exercice.xlsx');
}
```

---

## 🎨 Interfaces Utilisateur (Screens)

### 1. Dashboard (Écran d'accueil)
```
┌─────────────────────────────────────────┐
│  🏠 Tableau de Bord                     │
├─────────────────────────────────────────┤
│  📊 KPIs                                │
│  ┌──────────┐ ┌──────────┐ ┌─────────┐│
│  │ CA: 45K€ │ │Charges:  │ │Tréso:   ││
│  │          │ │25K€      │ │12K€     ││
│  └──────────┘ └──────────┘ └─────────┘│
│                                         │
│  📈 Graphique CA/Charges (12 mois)      │
│  [Graphique en barres]                  │
│                                         │
│  🔔 Alertes (3)                         │
│  • Facture #123 en retard               │
│  • Déclaration TVA à faire (15/12)     │
│  • Paiement fournisseur (20/12)        │
└─────────────────────────────────────────┘
```

### 2. Liste Factures
```
┌─────────────────────────────────────────┐
│  📄 Factures                  [+ Créer] │
├─────────────────────────────────────────┤
│  Filtres: [Ventes▼] [Toutes▼] [2024▼] │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐   │
│  │ #FAC-2024-001  Client ABC       │   │
│  │ 15/11/2024     1,200.00€  ✓Payée│   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ #FAC-2024-002  Client XYZ       │   │
│  │ 20/11/2024     850.00€  ⏱En att.│   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### 3. Formulaire Facture
```
┌─────────────────────────────────────────┐
│  ✏️ Nouvelle Facture                    │
├─────────────────────────────────────────┤
│  Type: ⚪ Vente  ⚪ Achat               │
│  N° Facture: [FAC-2024-003]             │
│  Date émission: [09/12/2024]            │
│  Client/Fournisseur: [________]         │
│                                         │
│  Lignes:                                │
│  Description    Qté  PU HT   TVA  Total│
│  [Produit A]    [1]  [100€] [20%] 120€ │
│  [+ Ajouter ligne]                      │
│                                         │
│  Total HT:  100.00€                     │
│  Total TVA:  20.00€                     │
│  Total TTC: 120.00€                     │
│                                         │
│  [Annuler]           [Enregistrer]      │
└─────────────────────────────────────────┘
```

### 4. Tableau de Bord TVA
```
┌─────────────────────────────────────────┐
│  💰 TVA - T4 2024                       │
├─────────────────────────────────────────┤
│  Période: 01/10/2024 - 31/12/2024       │
│                                         │
│  TVA Collectée:     4,500.00€           │
│  TVA Déductible:    2,100.00€           │
│  ─────────────────────────────          │
│  TVA à Payer:       2,400.00€           │
│                                         │
│  Détail par taux:                       │
│  • 20%: 3,800€ coll. / 1,900€ déd.     │
│  • 10%:   500€ coll. /   150€ déd.     │
│  •  5.5%: 200€ coll. /    50€ déd.     │
│                                         │
│  [Générer CA3]  [Exporter PDF]          │
└─────────────────────────────────────────┘
```

### 5. Immobilisations
```
┌─────────────────────────────────────────┐
│  🏢 Immobilisations          [+ Créer]  │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐   │
│  │ 💻 Ordinateur Dell              │   │
│  │ Achat: 15/01/2024  1,200€       │   │
│  │ Amort: Linéaire 3 ans           │   │
│  │ VNC: 933€  │ Amort 2024: 267€   │   │
│  │ [Voir plan amortissement]       │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ 🚗 Véhicule Renault             │   │
│  │ Achat: 10/03/2023  18,000€      │   │
│  │ Amort: Dégressif 5 ans          │   │
│  │ VNC: 11,475€ │ Amort 2024: 3,6K€│   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### 6. Documents Comptables
```
┌─────────────────────────────────────────┐
│  📚 Documents Comptables                │
├─────────────────────────────────────────┤
│  Exercice: [2024▼]                      │
│                                         │
│  📗 Journal Comptable                   │
│     [Ventes] [Achats] [Banque] [OD]    │
│     [Consulter] [Exporter PDF]          │
│                                         │
│  📘 Grand Livre                         │
│     Par compte / Par classe             │
│     [Consulter] [Exporter Excel]        │
│                                         │
│  📙 Bilan Comptable                     │
│     Actif / Passif au 31/12/2024        │
│     [Consulter] [Exporter PDF]          │
│                                         │
│  📕 Compte de Résultat                  │
│     Charges / Produits 2024             │
│     [Consulter] [Exporter PDF]          │
└─────────────────────────────────────────┘
```

---

## ✅ TODO - Plan d'Implémentation

### Phase 1 : Fondations (Semaine 1-2)
- [x] Créer la structure du projet Flutter
- [ ] Configurer `pubspec.yaml` avec toutes les dépendances
- [ ] Créer les modèles de données (models/)
- [ ] Implémenter le DatabaseHelper (SQLite)
- [ ] Créer le schéma de base de données complet
- [ ] Peupler la table `comptes_pcg` avec plan comptable

### Phase 2 : Services Métier (Semaine 3-4)
- [ ] Implémenter `FactureService` (CRUD + calculs TVA)
- [ ] Implémenter `TVAService` (calculs, déclarations)
- [ ] Implémenter `BanqueService` (transactions, rapprochement)
- [ ] Implémenter `ImmobilisationService` (amortissements)
- [ ] Implémenter `ComptabiliteService` (écritures, journaux)
- [ ] Implémenter `CalculService` (tous les calculs comptables)

### Phase 3 : Interface Utilisateur (Semaine 5-7)
- [ ] Créer le `main.dart` et `app.dart`
- [ ] Implémenter le Dashboard avec KPIs et graphiques
- [ ] Créer les écrans de gestion des factures (liste, formulaire, détail)
- [ ] Créer les écrans de gestion de la TVA
- [ ] Créer les écrans de gestion bancaire
- [ ] Créer les écrans d'immobilisations
- [ ] Créer les écrans de documents comptables
- [ ] Créer les widgets réutilisables (cards, charts, forms)

### Phase 4 : Export et Rapports (Semaine 8)
- [ ] Implémenter l'export PDF (journal, grand livre, bilan, compte de résultat)
- [ ] Implémenter l'export Excel
- [ ] Créer les templates PDF professionnels
- [ ] Implémenter la génération de CA3 (TVA)

### Phase 5 : Fonctionnalités Avancées (Semaine 9-10)
- [ ] Système d'alertes et notifications
- [ ] Import de fichiers bancaires (CSV, OFX)
- [ ] Rapprochement bancaire automatique
- [ ] Gestion des exercices comptables
- [ ] Validation et clôture d'exercice
- [ ] Système de sauvegarde/restauration

### Phase 6 : Conformité et Sécurité (Semaine 11)
- [ ] Traçabilité complète (horodatage, audit trail)
- [ ] Système de rectification (pas de suppression)
- [ ] Numérotation séquentielle des pièces
- [ ] Archivage automatique
- [ ] Chiffrement des données sensibles

### Phase 7 : Cloud et Synchronisation (Semaine 12)
- [ ] Intégration Firebase/Supabase (optionnel)
- [ ] Authentification utilisateur
- [ ] Synchronisation multi-appareils
- [ ] Sauvegarde cloud automatique

### Phase 8 : Tests et Optimisation (Semaine 13-14)
- [ ] Tests unitaires (services, calculs)
- [ ] Tests d'intégration
- [ ] Tests UI
- [ ] Optimisation des performances
- [ ] Responsive design (mobile, tablette, web)
- [ ] Mode sombre/clair

### Phase 9 : Documentation et Déploiement (Semaine 15)
- [ ] Documentation utilisateur
- [ ] Documentation technique (API, code)
- [ ] Guide d'installation
- [ ] Configuration CI/CD
- [ ] Build Android/iOS/Web
- [ ] Publication sur stores (optionnel)

---

## 📦 Dépendances Principales (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.1
  
  # Base de données
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  path: ^1.8.3
  
  # Export PDF/Excel
  pdf: ^3.10.7
  printing: ^5.11.1
  excel: ^4.0.2
  
  # Graphiques
  fl_chart: ^0.65.0
  
  # Internationalisation
  intl: ^0.18.1
  
  # UI
  google_fonts: ^6.1.0
  
  # Import fichiers
  file_picker: ^6.1.1
  csv: ^5.1.1
  
  # Stockage local
  shared_preferences: ^2.2.2
  
  # Cloud (optionnel)
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  
  # Utilitaires
  uuid: ^4.2.2
  collection: ^1.18.0
```

---

## 🔐 Conformité Légale

### Obligations Comptables EI
1. **Conservation** : 10 ans minimum
2. **Traçabilité** : Toutes les opérations horodatées
3. **Immuabilité** : Pas de suppression, uniquement rectifications
4. **Numérotation** : Séquentielle et continue
5. **Loi anti-fraude TVA** : Certificat de conformité (si > 25K€ CA)

### Taux de TVA (France)
- **20%** : Taux normal
- **10%** : Taux intermédiaire (restauration, travaux)
- **5.5%** : Taux réduit (alimentation, livres)
- **2.1%** : Taux particulier (médicaments remboursables)

### Plan Comptable (Principales Classes)
- **Classe 1** : Capitaux (passif)
- **Classe 2** : Immobilisations (actif)
- **Classe 3** : Stocks (actif)
- **Classe 4** : Tiers (actif/passif)
- **Classe 5** : Financiers (actif)
- **Classe 6** : Charges
- **Classe 7** : Produits

---

## 📞 Support et Ressources

- **Documentation Flutter** : https://flutter.dev/docs
- **Plan Comptable Général** : https://www.plan-comptable.com
- **Législation TVA** : https://www.impots.gouv.fr
- **SQLite Flutter** : https://pub.dev/packages/sqflite

---

**Version** : 1.0.0  
**Date** : Décembre 2024  
**Auteur** : Architecture Compta EI
