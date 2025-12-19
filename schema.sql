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

-- Table des justificatifs (pièces comptables)
CREATE TABLE IF NOT EXISTS justificatifs (
    id SERIAL PRIMARY KEY,
    nom_fichier VARCHAR(255) NOT NULL,
    nom_original VARCHAR(255) NOT NULL,
    type_mime VARCHAR(100) NOT NULL,
    taille_octets INTEGER NOT NULL,
    chemin_stockage TEXT NOT NULL,
    
    -- Métadonnées
    description TEXT,
    type_document VARCHAR(100), -- 'facture', 'releve', 'contrat', 'autre'
    date_document DATE,
    
    -- Associations
    facture_id INTEGER REFERENCES factures(id) ON DELETE SET NULL,
    ecriture_id INTEGER REFERENCES ecritures_comptables(id) ON DELETE SET NULL,
    client_id INTEGER REFERENCES clients(id) ON DELETE SET NULL,
    
    -- Statut
    archive BOOLEAN DEFAULT FALSE,
    date_archivage TIMESTAMP,
    
    -- Mode de stockage
    storage_provider VARCHAR(50) DEFAULT 'local', -- 'local' ou 'cloud'
    cloud_url TEXT, -- URL si stocké dans le cloud
    
    -- Audit
    cree_le TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cree_par VARCHAR(100),
    modifie_le TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modifie_par VARCHAR(100),
    
    -- Vérification d'intégrité
    checksum VARCHAR(64), -- SHA-256 du fichier
    
    CONSTRAINT unique_nom_fichier UNIQUE (nom_fichier)
);

-- Table pour l'historique des modifications de justificatifs
CREATE TABLE IF NOT EXISTS justificatifs_historique (
    id SERIAL PRIMARY KEY,
    justificatif_id INTEGER NOT NULL REFERENCES justificatifs(id) ON DELETE CASCADE,
    action VARCHAR(50) NOT NULL, -- 'upload', 'download', 'archive', 'delete', 'update'
    details JSONB,
    utilisateur VARCHAR(100),
    date_action TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour les justificatifs
CREATE INDEX IF NOT EXISTS idx_justificatifs_facture ON justificatifs(facture_id);
CREATE INDEX IF NOT EXISTS idx_justificatifs_ecriture ON justificatifs(ecriture_id);
CREATE INDEX IF NOT EXISTS idx_justificatifs_client ON justificatifs(client_id);
CREATE INDEX IF NOT EXISTS idx_justificatifs_type ON justificatifs(type_document);
CREATE INDEX IF NOT EXISTS idx_justificatifs_archive ON justificatifs(archive);
CREATE INDEX IF NOT EXISTS idx_justificatifs_date ON justificatifs(date_document);
CREATE INDEX IF NOT EXISTS idx_justificatifs_provider ON justificatifs(storage_provider);
CREATE INDEX IF NOT EXISTS idx_justificatifs_historique_justificatif ON justificatifs_historique(justificatif_id);
CREATE INDEX IF NOT EXISTS idx_justificatifs_historique_date ON justificatifs_historique(date_action);

-- Vue pour les statistiques de justificatifs
CREATE OR REPLACE VIEW justificatifs_stats AS
SELECT 
    COUNT(*) as total_justificatifs,
    COUNT(CASE WHEN archive = false THEN 1 END) as actifs,
    COUNT(CASE WHEN archive = true THEN 1 END) as archives,
    SUM(taille_octets) as taille_totale_octets,
    ROUND(AVG(taille_octets)) as taille_moyenne_octets,
    COUNT(DISTINCT type_document) as types_documents,
    COUNT(CASE WHEN storage_provider = 'local' THEN 1 END) as stockage_local,
    COUNT(CASE WHEN storage_provider = 'cloud' THEN 1 END) as stockage_cloud
FROM justificatifs;

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

-- Fonction pour enregistrer automatiquement les modifications de justificatifs
CREATE OR REPLACE FUNCTION log_justificatif_modification()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        NEW.modifie_le = CURRENT_TIMESTAMP;
        
        INSERT INTO justificatifs_historique (justificatif_id, action, details)
        VALUES (NEW.id, 'update', jsonb_build_object(
            'champs_modifies', (
                SELECT jsonb_object_agg(key, jsonb_build_object('ancien', old_val, 'nouveau', new_val))
                FROM (
                    SELECT key, 
                           to_jsonb(OLD) -> key as old_val,
                           to_jsonb(NEW) -> key as new_val
                    FROM jsonb_object_keys(to_jsonb(NEW)) key
                    WHERE to_jsonb(OLD) -> key IS DISTINCT FROM to_jsonb(NEW) -> key
                ) changes
            )
        ));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER justificatif_modification_trigger
    BEFORE UPDATE ON justificatifs
    FOR EACH ROW
    EXECUTE FUNCTION log_justificatif_modification();

-- Commentaires sur la table justificatifs
COMMENT ON TABLE justificatifs IS 'Stockage des métadonnées des justificatifs (pièces comptables)';
COMMENT ON COLUMN justificatifs.nom_fichier IS 'Nom unique du fichier sur le système de stockage';
COMMENT ON COLUMN justificatifs.nom_original IS 'Nom original du fichier uploadé';
COMMENT ON COLUMN justificatifs.chemin_stockage IS 'Chemin relatif ou absolu selon le provider';
COMMENT ON COLUMN justificatifs.storage_provider IS 'Provider de stockage: local ou cloud';
COMMENT ON COLUMN justificatifs.checksum IS 'Hash SHA-256 pour vérifier l''intégrité';

-- Message de confirmation
DO $$
BEGIN
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Schéma de base de données Compta EI créé avec succès!';
    RAISE NOTICE '============================================================';
END $$;
