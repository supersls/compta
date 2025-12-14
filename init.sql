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

-- Index pour améliorer les performances
CREATE INDEX idx_factures_entreprise ON factures(entreprise_id);
CREATE INDEX idx_factures_type ON factures(type);
CREATE INDEX idx_factures_statut ON factures(statut);
CREATE INDEX idx_factures_date_emission ON factures(date_emission);
CREATE INDEX idx_clients_entreprise ON clients(entreprise_id);
CREATE INDEX idx_comptes_bancaires_entreprise ON comptes_bancaires(entreprise_id);
CREATE INDEX idx_transactions_date ON transactions_bancaires(date_transaction);
CREATE INDEX idx_immobilisations_entreprise ON immobilisations(entreprise_id);
CREATE INDEX idx_ecritures_entreprise ON ecritures_comptables(entreprise_id);
CREATE INDEX idx_ecritures_journal ON ecritures_comptables(journal);
CREATE INDEX idx_ecritures_compte ON ecritures_comptables(compte);
CREATE INDEX idx_ecritures_date ON ecritures_comptables(date_ecriture);
CREATE INDEX idx_declarations_tva_entreprise ON declarations_tva(entreprise_id);
CREATE INDEX idx_alertes_entreprise ON alertes(entreprise_id);

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

-- Insert default company data
INSERT INTO entreprise (id, nom, siret, adresse, code_postal, ville, email, telephone, regime_tva, date_cloture_exercice)
VALUES (
  1,
  'LAMHAMDI SALAH EI',
  '12345678901234',
  '6 rue des GONDOLES',
  '33270',
  'FLOIRAC',
  'contact@monentreprise.fr',
  '0123456789',
  'reel_normal',
  '2025-12-31'
)
ON CONFLICT (siret) DO NOTHING;

-- Insert sample immobilisations for entreprise 1
INSERT INTO immobilisations (entreprise_id, libelle, type, date_acquisition, valeur_acquisition, duree_amortissement, methode_amortissement, taux_amortissement, compte_immobilisation, compte_amortissement, en_service)
VALUES
  (1, 'Ordinateur portable Dell XPS', 'materiel', '2024-01-15', 1500.00, 3, 'lineaire', 33.33, '2183', '28183', true),
  (1, 'Véhicule utilitaire Renault', 'vehicule', '2023-06-01', 25000.00, 5, 'lineaire', 20.00, '2182', '28182', true),
  (1, 'Photocopieur professionnel', 'materiel', '2024-03-20', 3500.00, 5, 'lineaire', 20.00, '2183', '28183', true),
  (1, 'Bureau ergonomique', 'mobilier', '2024-02-10', 800.00, 10, 'lineaire', 10.00, '2184', '28183', true),
  (1, 'Serveur informatique', 'materiel', '2023-09-01', 8000.00, 3, 'lineaire', 33.33, '2183', '28183', true)
ON CONFLICT DO NOTHING;

-- Insert sample bank accounts for entreprise 1
INSERT INTO comptes_bancaires (entreprise_id, nom, banque, numero_compte, iban, solde_initial, solde_actuel, date_ouverture, actif)
VALUES
  (1, 'Compte Courant Principal', 'BNP Paribas', '30004012345678901', 'FR7630004012345678901234567', 5000.00, 12500.00, '2023-01-10', true)
ON CONFLICT DO NOTHING;

-- Insert sample bank transactions
INSERT INTO transactions_bancaires (compte_bancaire_id, date_transaction, libelle, debit, credit, solde, categorie, rapproche)
VALUES
  (1, '2025-12-01', 'Virement salaire', 0, 3500.00, 8500.00, 'Revenus', true),
  (1, '2025-12-02', 'Loyer bureau', 1200.00, 0, 7300.00, 'Loyer', true),
  (1, '2025-12-05', 'Facture électricité', 150.00, 0, 7150.00, 'Charges', true),
  (1, '2025-12-08', 'Vente prestation', 0, 2500.00, 9650.00, 'Ventes', true),
  (1, '2025-12-10', 'Fournitures bureau', 85.50, 0, 9564.50, 'Achats', true),
  (1, '2025-12-12', 'Paiement fournisseur', 450.00, 0, 9114.50, 'Achats', true),
  (1, '2025-12-14', 'Vente prestation', 0, 3385.50, 12500.00, 'Ventes', true),
  (1, '2025-12-01', 'Virement initial', 0, 5000.00, 15000.00, 'Apport', true),
  (1, '2025-12-03', 'Achat matériel', 1500.00, 0, 13500.00, 'Investissement', true),
  (1, '2025-12-07', 'Paiement assurance', 850.00, 0, 12650.00, 'Assurance', true),
  (1, '2025-12-11', 'Remboursement TVA', 0, 1200.00, 13850.00, 'TVA', true),
  (1, '2025-12-13', 'Services bancaires', 25.00, 0, 13825.00, 'Frais bancaires', true),
  (1, '2025-11-30', 'Virement épargne', 0, 2000.00, 22000.00, 'Épargne', true),
  (1, '2025-12-10', 'Intérêts', 0, 300.00, 22300.00, 'Produits financiers', true)
ON CONFLICT DO NOTHING;

-- Insert sample accounting entries for entreprise 1
INSERT INTO ecritures_comptables (entreprise_id, numero_piece, date_ecriture, journal, compte, libelle, debit, credit, validee)
VALUES
  -- Ventes de décembre 2025
  (1, 'VT-2025-001', '2025-12-01', 'VE', '411', 'Client - Prestation de service', 3000.00, 0, true),
  (1, 'VT-2025-001', '2025-12-01', 'VE', '706', 'Prestations de services', 0, 2500.00, true),
  (1, 'VT-2025-001', '2025-12-01', 'VE', '4457', 'TVA collectée', 0, 500.00, true),
  
  (1, 'VT-2025-002', '2025-12-08', 'VE', '411', 'Client - Vente marchandises', 4800.00, 0, true),
  (1, 'VT-2025-002', '2025-12-08', 'VE', '707', 'Ventes de marchandises', 0, 4000.00, true),
  (1, 'VT-2025-002', '2025-12-08', 'VE', '4457', 'TVA collectée', 0, 800.00, true),
  
  (1, 'VT-2025-003', '2025-12-14', 'VE', '411', 'Client - Prestation conseil', 4062.30, 0, true),
  (1, 'VT-2025-003', '2025-12-14', 'VE', '706', 'Prestations de services', 0, 3385.25, true),
  (1, 'VT-2025-003', '2025-12-14', 'VE', '4457', 'TVA collectée', 0, 677.05, true),
  
  -- Achats et charges
  (1, 'AC-2025-001', '2025-12-02', 'AC', '613', 'Locations', 1200.00, 0, true),
  (1, 'AC-2025-001', '2025-12-02', 'AC', '401', 'Fournisseurs', 0, 1200.00, true),
  
  (1, 'AC-2025-002', '2025-12-03', 'AC', '607', 'Achats de marchandises', 1250.00, 0, true),
  (1, 'AC-2025-002', '2025-12-03', 'AC', '4456', 'TVA déductible', 250.00, 0, true),
  (1, 'AC-2025-002', '2025-12-03', 'AC', '401', 'Fournisseurs', 0, 1500.00, true),
  
  (1, 'AC-2025-003', '2025-12-05', 'AC', '615', 'Entretien et réparations', 150.00, 0, true),
  (1, 'AC-2025-003', '2025-12-05', 'AC', '512', 'Banque', 0, 150.00, true),
  
  (1, 'AC-2025-004', '2025-12-07', 'AC', '616', 'Assurances', 850.00, 0, true),
  (1, 'AC-2025-004', '2025-12-07', 'AC', '512', 'Banque', 0, 850.00, true),
  
  (1, 'AC-2025-005', '2025-12-10', 'AC', '607', 'Achats de marchandises', 71.25, 0, true),
  (1, 'AC-2025-005', '2025-12-10', 'AC', '4456', 'TVA déductible', 14.25, 0, true),
  (1, 'AC-2025-005', '2025-12-10', 'AC', '512', 'Banque', 0, 85.50, true),
  
  (1, 'AC-2025-006', '2025-12-12', 'AC', '601', 'Achats de matières premières', 375.00, 0, true),
  (1, 'AC-2025-006', '2025-12-12', 'AC', '4456', 'TVA déductible', 75.00, 0, true),
  (1, 'AC-2025-006', '2025-12-12', 'AC', '401', 'Fournisseurs', 0, 450.00, true),
  
  (1, 'AC-2025-007', '2025-12-13', 'AC', '627', 'Services bancaires', 25.00, 0, true),
  (1, 'AC-2025-007', '2025-12-13', 'AC', '512', 'Banque', 0, 25.00, true),
  
  -- Salaires
  (1, 'SA-2025-001', '2025-12-01', 'OD', '621', 'Personnel', 3500.00, 0, true),
  (1, 'SA-2025-001', '2025-12-01', 'OD', '512', 'Banque', 0, 3500.00, true),
  
  -- Ventes novembre 2025 (pour avoir plus de données)
  (1, 'VT-2025-N01', '2025-11-05', 'VE', '411', 'Client - Vente', 3600.00, 0, true),
  (1, 'VT-2025-N01', '2025-11-05', 'VE', '707', 'Ventes de marchandises', 0, 3000.00, true),
  (1, 'VT-2025-N01', '2025-11-05', 'VE', '4457', 'TVA collectée', 0, 600.00, true),
  
  (1, 'VT-2025-N02', '2025-11-15', 'VE', '411', 'Client - Prestation', 2400.00, 0, true),
  (1, 'VT-2025-N02', '2025-11-15', 'VE', '706', 'Prestations de services', 0, 2000.00, true),
  (1, 'VT-2025-N02', '2025-11-15', 'VE', '4457', 'TVA collectée', 0, 400.00, true),
  
  -- Charges novembre 2025
  (1, 'AC-2025-N01', '2025-11-02', 'AC', '613', 'Locations', 1200.00, 0, true),
  (1, 'AC-2025-N01', '2025-11-02', 'AC', '401', 'Fournisseurs', 0, 1200.00, true),
  
  (1, 'AC-2025-N02', '2025-11-10', 'AC', '607', 'Achats de marchandises', 800.00, 0, true),
  (1, 'AC-2025-N02', '2025-11-10', 'AC', '4456', 'TVA déductible', 160.00, 0, true),
  (1, 'AC-2025-N02', '2025-11-10', 'AC', '401', 'Fournisseurs', 0, 960.00, true),
  
  (1, 'SA-2025-N01', '2025-11-01', 'OD', '621', 'Personnel', 3500.00, 0, true),
  (1, 'SA-2025-N01', '2025-11-01', 'OD', '512', 'Banque', 0, 3500.00, true)
ON CONFLICT DO NOTHING;

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

-- ============================================================================
-- SEED DATA - Sample Companies and Invoices
-- ============================================================================

-- Insert sample clients
INSERT INTO clients (entreprise_id, nom, siret, adresse, code_postal, ville, email, telephone, contact_principal, actif, created_at, updated_at)
VALUES 
(1, 'ITERA', '12312312312312', '123 Rue du Commerce', '75015', 'Paris', 'contact@itera.fr', '0145678912', 'Jean Dupont', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'ITERA', '12312312312313', '123 Rue du Commerce', '75015', 'Paris', 'contact@itera.fr', '0145678912', 'Jean Dupont', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT DO NOTHING;

-- Insert invoices from the CSV data
INSERT INTO factures (entreprise_id, numero, type, date_emission, date_echeance, client_fournisseur, montant_ht, montant_tva, montant_ttc, statut, categorie, notes, created_at, updated_at)
VALUES
(1, 'FAC-2025-001', 'vente', '2025-11-29', '2025-12-29', 'ITERA', 8640.00, 1728.00, 10368.00, 'en_attente', NULL, 'Facture de Novembre 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2025-002', 'vente', '2025-10-02', '2025-11-02', 'ITERA', 10800.00, 2160.00, 12960.00, 'en_attente', NULL, 'Facture de Octobre 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2025-003', 'vente', '2025-09-30', '2025-10-30', 'ITERA', 11880.00, 2376.00, 14256.00, 'payee', NULL, 'Facture de Septembre 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2025-004', 'vente', '2025-08-13', '2025-09-13', 'ITERA', 10260.00, 2052.00, 12312.00, 'payee', NULL, 'Facture de Août 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2025-005', 'vente', '2025-07-31', '2025-08-31', 'ITERA', 11880.00, 2376.00, 14256.00, 'payee', NULL, 'Facture de Juillet 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2025-006', 'vente', '2025-06-30', '2025-07-30', 'ITERA', 10584.00, 2116.80, 12700.80, 'payee', NULL, 'Facture de Juin 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2025-007', 'vente', '2025-05-30', '2025-06-30', 'ITERA', 4030.00, 806.00, 4836.00, 'payee', NULL, 'Facture de Mai 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2025-008', 'vente', '2025-04-30', '2025-05-30', 'ITERA', 10080.00, 2016.00, 12096.00, 'payee', NULL, 'Facture de Avril 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2025-009', 'vente', '2025-03-31', '2025-04-30', 'ITERA', 10584.00, 2116.80, 12700.80, 'payee', NULL, 'Facture de Mars 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2025-010', 'vente', '2025-02-28', '2025-03-30', 'ITERA', 9576.00, 1915.20, 11491.20, 'en_attente', NULL, 'Facture de Février 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2025-011', 'vente', '2025-02-28', '2025-03-30', 'ITERA', 10584.00, 2116.80, 12700.80, 'payee', NULL, 'Facture de Février 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2025-012', 'vente', '2025-01-31', '2025-02-28', 'ITERA', 8048.00, 1609.60, 9657.60, 'payee', NULL, 'Facture de Janvier 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2025-013', 'vente', '2025-01-20', '2025-02-20', 'Weevi', 5076.00, 1015.20, 6091.20, 'payee', NULL, 'Facture de Janvier 2025 - WaVii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2024-014', 'vente', '2024-12-06', '2025-01-06', 'Weevi', 7611.00, 1522.20, 9133.20, 'payee', NULL, 'Facture de Décembre 2024 - WaVii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2024-015', 'vente', '2024-11-15', '2024-12-15', 'Weevi', 9156.80, 1831.36, 10988.16, 'payee', NULL, 'Facture de Novembre 2024 - WaVii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2024-016', 'vente', '2024-10-01', '2024-11-01', 'Weevi', 15675.80, 3135.16, 18810.96, 'payee', NULL, 'Facture de Octobre 2024 - WaVii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2024-017', 'vente', '2024-09-16', '2024-10-16', 'Weevi', 1522.50, 304.50, 1827.00, 'payee', NULL, 'Facture de Septembre 2024 - WaVii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2024-018', 'vente', '2024-08-01', '2024-09-01', 'Weevi', 8121.60, 1624.32, 9745.92, 'payee', NULL, 'Facture de Août 2024 - WaVii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2024-019', 'vente', '2024-07-02', '2024-08-02', 'Weevi', 10659.60, 2131.92, 12791.52, 'payee', NULL, 'Facture de Juillet 2024 - Weevii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2024-020', 'vente', '2024-06-05', '2024-07-05', 'Weevi', 7611.00, 1522.20, 9133.20, 'payee', NULL, 'Facture de Juin 2024 - Weevii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2024-021', 'vente', '2024-05-06', '2024-06-06', 'Weevi', 9360.60, 1872.12, 11232.72, 'payee', NULL, 'Facture de Mai 2024 - Weevii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2024-022', 'vente', '2024-04-05', '2024-05-05', 'Weevi', 8460.00, 1692.00, 10152.00, 'payee', NULL, 'Facture de Avril 2024 - Weevii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2024-023', 'vente', '2024-03-05', '2024-04-05', 'Weevi', 8160.00, 1632.00, 9792.00, 'payee', NULL, 'Facture de Mars 2024 - Weevi', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2024-024', 'vente', '2024-02-05', '2024-03-05', 'Weevi', 8832.00, 1766.40, 10598.40, 'payee', NULL, 'Facture de Février 2024 - Waevii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2024-025', 'vente', '2024-01-05', '2024-02-05', 'Weevi', 9306.00, 1861.20, 11167.20, 'payee', NULL, 'Facture de Janvier 2024 - Waevii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2023-026', 'vente', '2023-12-05', '2024-01-05', 'Weevi', 8940.00, 1788.00, 10728.00, 'payee', NULL, 'Décembre 2023 - Waevi', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2023-027', 'vente', '2023-11-05', '2023-12-05', 'Weevi', 3507.00, 701.40, 4208.40, 'payee', NULL, 'Novembre 2023 - Waovi', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (numero) DO NOTHING;

-- Set montant_paye for paid invoices
UPDATE factures SET montant_paye = montant_ttc WHERE statut = 'payee';

-- Calculate and set reste_a_payer for all invoices
UPDATE factures SET reste_a_payer = montant_ttc - montant_paye;

-- Insert paiements for paid invoices (using date_echeance as payment date)
INSERT INTO paiements (facture_id, date_paiement, montant, mode_paiement, reference, created_at)
SELECT 
  id,
  date_echeance,
  montant_ttc,
  'virement',
  'PAIEMENT-' || numero,
  CURRENT_TIMESTAMP
FROM factures
WHERE statut = 'payee' AND type = 'vente';

-- Final verification and summary
DO $$
BEGIN
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Initialisation complète de la base de données Compta EI';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Total factures: %', (SELECT COUNT(*) FROM factures);
    RAISE NOTICE 'Montant total: % €', (SELECT SUM(montant_ttc) FROM factures);
    RAISE NOTICE 'Total paiements: %', (SELECT COUNT(*) FROM paiements);
    RAISE NOTICE '============================================================';
END $$;
