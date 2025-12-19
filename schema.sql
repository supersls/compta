-- Schema de la base de données PostgreSQL pour Compta EI
-- Script de création des tables et index uniquement

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

CREATE TABLE IF NOT EXISTS clients (
  id SERIAL PRIMARY KEY,
  entreprise_id INTEGER REFERENCES entreprise(id) ON DELETE CASCADE,
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

CREATE TABLE IF NOT EXISTS factures (
  id SERIAL PRIMARY KEY,
  entreprise_id INTEGER REFERENCES entreprise(id) ON DELETE CASCADE,
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
  reste_a_payer DECIMAL(12, 2) DEFAULT 0,
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
  entreprise_id INTEGER REFERENCES entreprise(id) ON DELETE CASCADE,
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
  entreprise_id INTEGER REFERENCES entreprise(id) ON DELETE CASCADE,
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
  entreprise_id INTEGER REFERENCES entreprise(id) ON DELETE CASCADE,
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
  entreprise_id INTEGER REFERENCES entreprise(id) ON DELETE CASCADE,
  annee INTEGER NOT NULL,
  date_debut DATE NOT NULL,
  date_fin DATE NOT NULL,
  cloture BOOLEAN DEFAULT FALSE,
  date_cloture DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(entreprise_id, annee)
);

CREATE TABLE IF NOT EXISTS declarations_tva (
  id SERIAL PRIMARY KEY,
  entreprise_id INTEGER REFERENCES entreprise(id) ON DELETE CASCADE,
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
  entreprise_id INTEGER REFERENCES entreprise(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  titre VARCHAR(255) NOT NULL,
  message TEXT,
  date_alerte DATE NOT NULL,
  lue BOOLEAN DEFAULT FALSE,
  reference_id INTEGER,
  reference_type VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS journaux (
  id SERIAL PRIMARY KEY,
  code VARCHAR(10) UNIQUE NOT NULL,
  nom VARCHAR(100) NOT NULL,
  description TEXT,
  type VARCHAR(30) CHECK (type IN ('vente', 'achat', 'banque', 'caisse', 'operations_diverses')),
  actif BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS types_immobilisation (
  id SERIAL PRIMARY KEY,
  code VARCHAR(20) UNIQUE NOT NULL,
  nom VARCHAR(100) NOT NULL,
  description TEXT,
  duree_amortissement_defaut INTEGER,
  compte_immobilisation_defaut VARCHAR(10),
  compte_amortissement_defaut VARCHAR(10),
  actif BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_factures_entreprise ON factures(entreprise_id);
CREATE INDEX IF NOT EXISTS idx_factures_type ON factures(type);
CREATE INDEX IF NOT EXISTS idx_factures_statut ON factures(statut);
CREATE INDEX IF NOT EXISTS idx_factures_date_emission ON factures(date_emission);
CREATE INDEX IF NOT EXISTS idx_clients_entreprise ON clients(entreprise_id);
CREATE INDEX IF NOT EXISTS idx_comptes_bancaires_entreprise ON comptes_bancaires(entreprise_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions_bancaires(date_transaction);
CREATE INDEX IF NOT EXISTS idx_immobilisations_entreprise ON immobilisations(entreprise_id);
CREATE INDEX IF NOT EXISTS idx_ecritures_entreprise ON ecritures_comptables(entreprise_id);
CREATE INDEX IF NOT EXISTS idx_ecritures_journal ON ecritures_comptables(journal);
CREATE INDEX IF NOT EXISTS idx_ecritures_compte ON ecritures_comptables(compte);
CREATE INDEX IF NOT EXISTS idx_ecritures_date ON ecritures_comptables(date_ecriture);
CREATE INDEX IF NOT EXISTS idx_declarations_tva_entreprise ON declarations_tva(entreprise_id);
CREATE INDEX IF NOT EXISTS idx_alertes_entreprise ON alertes(entreprise_id);

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
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Schéma de base de données Compta EI créé avec succès!';
    RAISE NOTICE '============================================================';
END $$;
