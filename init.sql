-- Script d'initialisation de la base de données PostgreSQL pour Compta EI
-- Ce script sera exécuté automatiquement lors de la création du conteneur

-- Création de la base de données (déjà créée via POSTGRES_DB)
-- CREATE DATABASE compta_ei;

-- Se connecter à la base de données
\c compta_ei;

-- Activer les extensions utiles
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Création des tables
CREATE TABLE IF NOT EXISTS entreprise (
  id SERIAL PRIMARY KEY,
  nom VARCHAR(255) NOT NULL,
  siret VARCHAR(14) UNIQUE,
  adresse TEXT,
  code_postal VARCHAR(10),
  ville VARCHAR(100),
  email VARCHAR(255),
  telephone VARCHAR(20),
  regime_tva VARCHAR(50) DEFAULT 'reel_normal',
  date_cloture_exercice DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS factures (
  id SERIAL PRIMARY KEY,
  numero VARCHAR(50) UNIQUE NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('vente', 'achat')),
  date_emission DATE NOT NULL,
  date_echeance DATE,
  client_fournisseur VARCHAR(255) NOT NULL,
  siret_client VARCHAR(14),
  montant_ht DECIMAL(12, 2) NOT NULL,
  montant_tva DECIMAL(12, 2) NOT NULL,
  montant_ttc DECIMAL(12, 2) NOT NULL,
  statut VARCHAR(30) DEFAULT 'en_attente' CHECK (statut IN ('en_attente', 'payee', 'partiellement_payee', 'en_retard')),
  montant_paye DECIMAL(12, 2) DEFAULT 0,
  categorie VARCHAR(100),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS paiements (
  id SERIAL PRIMARY KEY,
  facture_id INTEGER NOT NULL REFERENCES factures(id) ON DELETE CASCADE,
  date_paiement DATE NOT NULL,
  montant DECIMAL(12, 2) NOT NULL,
  mode_paiement VARCHAR(30),
  reference VARCHAR(100),
  compte_bancaire_id INTEGER,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS comptes_bancaires (
  id SERIAL PRIMARY KEY,
  nom VARCHAR(255) NOT NULL,
  banque VARCHAR(255),
  numero_compte VARCHAR(50),
  iban VARCHAR(34),
  solde_initial DECIMAL(12, 2) DEFAULT 0,
  solde_actuel DECIMAL(12, 2) DEFAULT 0,
  date_ouverture DATE,
  actif BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS transactions_bancaires (
  id SERIAL PRIMARY KEY,
  compte_bancaire_id INTEGER NOT NULL REFERENCES comptes_bancaires(id) ON DELETE CASCADE,
  date_transaction DATE NOT NULL,
  date_valeur DATE,
  libelle TEXT NOT NULL,
  debit DECIMAL(12, 2) DEFAULT 0,
  credit DECIMAL(12, 2) DEFAULT 0,
  solde DECIMAL(12, 2),
  categorie VARCHAR(100),
  rapproche BOOLEAN DEFAULT FALSE,
  facture_id INTEGER REFERENCES factures(id),
  ecriture_id INTEGER,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS immobilisations (
  id SERIAL PRIMARY KEY,
  libelle VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL,
  date_acquisition DATE NOT NULL,
  valeur_acquisition DECIMAL(12, 2) NOT NULL,
  duree_amortissement INTEGER NOT NULL,
  methode_amortissement VARCHAR(20) DEFAULT 'lineaire',
  taux_amortissement DECIMAL(5, 2),
  valeur_residuelle DECIMAL(12, 2) DEFAULT 0,
  compte_immobilisation VARCHAR(10),
  compte_amortissement VARCHAR(10),
  en_service BOOLEAN DEFAULT TRUE,
  date_cession DATE,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS amortissements (
  id SERIAL PRIMARY KEY,
  immobilisation_id INTEGER NOT NULL REFERENCES immobilisations(id) ON DELETE CASCADE,
  exercice INTEGER NOT NULL,
  annee INTEGER NOT NULL,
  montant_amortissement DECIMAL(12, 2) NOT NULL,
  cumul_amortissements DECIMAL(12, 2) NOT NULL,
  valeur_nette_comptable DECIMAL(12, 2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ecritures_comptables (
  id SERIAL PRIMARY KEY,
  numero_piece VARCHAR(50) NOT NULL,
  date_ecriture DATE NOT NULL,
  journal VARCHAR(20) NOT NULL,
  compte VARCHAR(10) NOT NULL,
  libelle TEXT NOT NULL,
  debit DECIMAL(12, 2) DEFAULT 0,
  credit DECIMAL(12, 2) DEFAULT 0,
  reference_externe VARCHAR(100),
  type_reference VARCHAR(50),
  lettrage VARCHAR(10),
  validee BOOLEAN DEFAULT TRUE,
  rectification_de INTEGER REFERENCES ecritures_comptables(id),
  created_by VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS comptes_pcg (
  numero VARCHAR(10) PRIMARY KEY,
  libelle VARCHAR(255) NOT NULL,
  classe INTEGER NOT NULL,
  type VARCHAR(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS exercices_comptables (
  id SERIAL PRIMARY KEY,
  annee INTEGER NOT NULL UNIQUE,
  date_debut DATE NOT NULL,
  date_fin DATE NOT NULL,
  cloture BOOLEAN DEFAULT FALSE,
  date_cloture DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS declarations_tva (
  id SERIAL PRIMARY KEY,
  periode_debut DATE NOT NULL,
  periode_fin DATE NOT NULL,
  tva_collectee DECIMAL(12, 2) NOT NULL,
  tva_deductible DECIMAL(12, 2) NOT NULL,
  tva_a_payer DECIMAL(12, 2) NOT NULL,
  statut VARCHAR(20) DEFAULT 'brouillon',
  date_declaration DATE,
  date_paiement DATE,
  fichier_export TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS alertes (
  id SERIAL PRIMARY KEY,
  type VARCHAR(50) NOT NULL,
  titre VARCHAR(255) NOT NULL,
  message TEXT,
  date_alerte DATE NOT NULL,
  lue BOOLEAN DEFAULT FALSE,
  reference_id INTEGER,
  reference_type VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour améliorer les performances
CREATE INDEX idx_factures_type ON factures(type);
CREATE INDEX idx_factures_statut ON factures(statut);
CREATE INDEX idx_factures_date_emission ON factures(date_emission);
CREATE INDEX idx_transactions_date ON transactions_bancaires(date_transaction);
CREATE INDEX idx_ecritures_journal ON ecritures_comptables(journal);
CREATE INDEX idx_ecritures_compte ON ecritures_comptables(compte);
CREATE INDEX idx_ecritures_date ON ecritures_comptables(date_ecriture);

-- Peupler le Plan Comptable Général (PCG) simplifié
INSERT INTO comptes_pcg (numero, libelle, classe, type) VALUES
-- Classe 1 - Capitaux
('101', 'Capital', 1, 'passif'),
('120', 'Résultat de l''exercice', 1, 'passif'),
('164', 'Emprunts', 1, 'passif'),

-- Classe 2 - Immobilisations
('2154', 'Matériel industriel', 2, 'actif'),
('2182', 'Matériel de transport', 2, 'actif'),
('2183', 'Matériel de bureau', 2, 'actif'),
('2184', 'Mobilier', 2, 'actif'),
('28154', 'Amortissement matériel industriel', 2, 'actif'),
('28182', 'Amortissement matériel transport', 2, 'actif'),
('28183', 'Amortissement matériel bureau', 2, 'actif'),

-- Classe 4 - Tiers
('401', 'Fournisseurs', 4, 'passif'),
('411', 'Clients', 4, 'actif'),
('4456', 'TVA déductible', 4, 'actif'),
('4457', 'TVA collectée', 4, 'passif'),
('4458', 'TVA à régulariser', 4, 'actif'),

-- Classe 5 - Financiers
('512', 'Banque', 5, 'actif'),
('530', 'Caisse', 5, 'actif'),

-- Classe 6 - Charges
('601', 'Achats de matières premières', 6, 'charge'),
('607', 'Achats de marchandises', 6, 'charge'),
('611', 'Sous-traitance générale', 6, 'charge'),
('613', 'Locations', 6, 'charge'),
('615', 'Entretien et réparations', 6, 'charge'),
('616', 'Assurances', 6, 'charge'),
('621', 'Personnel', 6, 'charge'),
('626', 'Frais postaux', 6, 'charge'),
('627', 'Services bancaires', 6, 'charge'),
('681', 'Dotations aux amortissements', 6, 'charge'),

-- Classe 7 - Produits
('701', 'Ventes de produits finis', 7, 'produit'),
('706', 'Prestations de services', 7, 'produit'),
('707', 'Ventes de marchandises', 7, 'produit'),
('708', 'Produits des activités annexes', 7, 'produit')
ON CONFLICT (numero) DO NOTHING;

-- Trigger pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_factures_updated_at BEFORE UPDATE ON factures
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Message de confirmation
DO $$
BEGIN
    RAISE NOTICE 'Base de données Compta EI initialisée avec succès!';
END $$;
