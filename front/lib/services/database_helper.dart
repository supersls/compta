import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('compta_ei.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Table entreprise
    await db.execute('''
      CREATE TABLE entreprise (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        siret TEXT UNIQUE,
        adresse TEXT,
        code_postal TEXT,
        ville TEXT,
        email TEXT,
        telephone TEXT,
        regime_tva TEXT DEFAULT 'reel_normal',
        date_cloture_exercice TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Table factures
    await db.execute('''
      CREATE TABLE factures (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numero TEXT UNIQUE NOT NULL,
        type TEXT NOT NULL,
        date_emission TEXT NOT NULL,
        date_echeance TEXT,
        client_fournisseur TEXT NOT NULL,
        siret_client TEXT,
        montant_ht REAL NOT NULL,
        montant_tva REAL NOT NULL,
        montant_ttc REAL NOT NULL,
        statut TEXT DEFAULT 'en_attente',
        montant_paye REAL DEFAULT 0,
        categorie TEXT,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');



    // Table paiements
    await db.execute('''
      CREATE TABLE paiements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        facture_id INTEGER NOT NULL,
        date_paiement TEXT NOT NULL,
        montant REAL NOT NULL,
        mode_paiement TEXT,
        reference TEXT,
        compte_bancaire_id INTEGER,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (facture_id) REFERENCES factures(id) ON DELETE CASCADE,
        FOREIGN KEY (compte_bancaire_id) REFERENCES comptes_bancaires(id)
      )
    ''');

    // Table comptes_bancaires
    await db.execute('''
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
      )
    ''');

    // Table transactions_bancaires
    await db.execute('''
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
        rapproche INTEGER DEFAULT 0,
        facture_id INTEGER,
        ecriture_id INTEGER,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (compte_bancaire_id) REFERENCES comptes_bancaires(id) ON DELETE CASCADE,
        FOREIGN KEY (facture_id) REFERENCES factures(id),
        FOREIGN KEY (ecriture_id) REFERENCES ecritures_comptables(id)
      )
    ''');

    // Table immobilisations
    await db.execute('''
      CREATE TABLE immobilisations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        libelle TEXT NOT NULL,
        type TEXT NOT NULL,
        date_acquisition TEXT NOT NULL,
        valeur_acquisition REAL NOT NULL,
        duree_amortissement INTEGER NOT NULL,
        methode_amortissement TEXT DEFAULT 'lineaire',
        taux_amortissement REAL,
        valeur_residuelle REAL DEFAULT 0,
        compte_immobilisation TEXT,
        compte_amortissement TEXT,
        en_service INTEGER DEFAULT 1,
        date_cession TEXT,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Table amortissements
    await db.execute('''
      CREATE TABLE amortissements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        immobilisation_id INTEGER NOT NULL,
        exercice INTEGER NOT NULL,
        annee INTEGER NOT NULL,
        montant_amortissement REAL NOT NULL,
        cumul_amortissements REAL NOT NULL,
        valeur_nette_comptable REAL NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (immobilisation_id) REFERENCES immobilisations(id) ON DELETE CASCADE
      )
    ''');

    // Table ecritures_comptables
    await db.execute('''
      CREATE TABLE ecritures_comptables (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numero_piece TEXT NOT NULL,
        date_ecriture TEXT NOT NULL,
        journal TEXT NOT NULL,
        compte TEXT NOT NULL,
        libelle TEXT NOT NULL,
        debit REAL DEFAULT 0,
        credit REAL DEFAULT 0,
        reference_externe TEXT,
        type_reference TEXT,
        lettrage TEXT,
        validee INTEGER DEFAULT 1,
        rectification_de INTEGER,
        created_by TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (rectification_de) REFERENCES ecritures_comptables(id)
      )
    ''');

    // Table comptes_pcg
    await db.execute('''
      CREATE TABLE comptes_pcg (
        numero TEXT PRIMARY KEY,
        libelle TEXT NOT NULL,
        classe INTEGER NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    // Table exercices_comptables
    await db.execute('''
      CREATE TABLE exercices_comptables (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        annee INTEGER NOT NULL UNIQUE,
        date_debut TEXT NOT NULL,
        date_fin TEXT NOT NULL,
        cloture INTEGER DEFAULT 0,
        date_cloture TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Table declarations_tva
    await db.execute('''
      CREATE TABLE declarations_tva (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        periode_debut TEXT NOT NULL,
        periode_fin TEXT NOT NULL,
        tva_collectee REAL NOT NULL,
        tva_deductible REAL NOT NULL,
        tva_a_payer REAL NOT NULL,
        statut TEXT DEFAULT 'brouillon',
        date_declaration TEXT,
        date_paiement TEXT,
        fichier_export TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Table alertes
    await db.execute('''
      CREATE TABLE alertes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        titre TEXT NOT NULL,
        message TEXT,
        date_alerte TEXT NOT NULL,
        lue INTEGER DEFAULT 0,
        reference_id INTEGER,
        reference_type TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Peupler le Plan Comptable Général (PCG) simplifié
    await _populatePCG(db);
  }

  Future<void> _populatePCG(Database db) async {
    // Classe 1 - Capitaux
    await db.insert('comptes_pcg', {'numero': '101', 'libelle': 'Capital', 'classe': 1, 'type': 'passif'});
    await db.insert('comptes_pcg', {'numero': '120', 'libelle': 'Résultat de l\'exercice', 'classe': 1, 'type': 'passif'});
    await db.insert('comptes_pcg', {'numero': '164', 'libelle': 'Emprunts', 'classe': 1, 'type': 'passif'});

    // Classe 2 - Immobilisations
    await db.insert('comptes_pcg', {'numero': '2154', 'libelle': 'Matériel industriel', 'classe': 2, 'type': 'actif'});
    await db.insert('comptes_pcg', {'numero': '2182', 'libelle': 'Matériel de transport', 'classe': 2, 'type': 'actif'});
    await db.insert('comptes_pcg', {'numero': '2183', 'libelle': 'Matériel de bureau', 'classe': 2, 'type': 'actif'});
    await db.insert('comptes_pcg', {'numero': '2184', 'libelle': 'Mobilier', 'classe': 2, 'type': 'actif'});
    await db.insert('comptes_pcg', {'numero': '28154', 'libelle': 'Amortissement matériel industriel', 'classe': 2, 'type': 'actif'});
    await db.insert('comptes_pcg', {'numero': '28182', 'libelle': 'Amortissement matériel transport', 'classe': 2, 'type': 'actif'});
    await db.insert('comptes_pcg', {'numero': '28183', 'libelle': 'Amortissement matériel bureau', 'classe': 2, 'type': 'actif'});

    // Classe 4 - Tiers
    await db.insert('comptes_pcg', {'numero': '401', 'libelle': 'Fournisseurs', 'classe': 4, 'type': 'passif'});
    await db.insert('comptes_pcg', {'numero': '411', 'libelle': 'Clients', 'classe': 4, 'type': 'actif'});
    await db.insert('comptes_pcg', {'numero': '4456', 'libelle': 'TVA déductible', 'classe': 4, 'type': 'actif'});
    await db.insert('comptes_pcg', {'numero': '4457', 'libelle': 'TVA collectée', 'classe': 4, 'type': 'passif'});
    await db.insert('comptes_pcg', {'numero': '4458', 'libelle': 'TVA à régulariser', 'classe': 4, 'type': 'actif'});

    // Classe 5 - Financiers
    await db.insert('comptes_pcg', {'numero': '512', 'libelle': 'Banque', 'classe': 5, 'type': 'actif'});
    await db.insert('comptes_pcg', {'numero': '530', 'libelle': 'Caisse', 'classe': 5, 'type': 'actif'});

    // Classe 6 - Charges
    await db.insert('comptes_pcg', {'numero': '601', 'libelle': 'Achats de matières premières', 'classe': 6, 'type': 'charge'});
    await db.insert('comptes_pcg', {'numero': '607', 'libelle': 'Achats de marchandises', 'classe': 6, 'type': 'charge'});
    await db.insert('comptes_pcg', {'numero': '611', 'libelle': 'Sous-traitance générale', 'classe': 6, 'type': 'charge'});
    await db.insert('comptes_pcg', {'numero': '613', 'libelle': 'Locations', 'classe': 6, 'type': 'charge'});
    await db.insert('comptes_pcg', {'numero': '615', 'libelle': 'Entretien et réparations', 'classe': 6, 'type': 'charge'});
    await db.insert('comptes_pcg', {'numero': '616', 'libelle': 'Assurances', 'classe': 6, 'type': 'charge'});
    await db.insert('comptes_pcg', {'numero': '621', 'libelle': 'Personnel', 'classe': 6, 'type': 'charge'});
    await db.insert('comptes_pcg', {'numero': '626', 'libelle': 'Frais postaux', 'classe': 6, 'type': 'charge'});
    await db.insert('comptes_pcg', {'numero': '627', 'libelle': 'Services bancaires', 'classe': 6, 'type': 'charge'});
    await db.insert('comptes_pcg', {'numero': '681', 'libelle': 'Dotations aux amortissements', 'classe': 6, 'type': 'charge'});

    // Classe 7 - Produits
    await db.insert('comptes_pcg', {'numero': '701', 'libelle': 'Ventes de produits finis', 'classe': 7, 'type': 'produit'});
    await db.insert('comptes_pcg', {'numero': '706', 'libelle': 'Prestations de services', 'classe': 7, 'type': 'produit'});
    await db.insert('comptes_pcg', {'numero': '707', 'libelle': 'Ventes de marchandises', 'classe': 7, 'type': 'produit'});
    await db.insert('comptes_pcg', {'numero': '708', 'libelle': 'Produits des activités annexes', 'classe': 7, 'type': 'produit'});
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
