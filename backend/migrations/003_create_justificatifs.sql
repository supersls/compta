-- Migration pour créer la table des justificatifs
-- Date: 2025-12-19

-- Table principale des justificatifs
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

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_justificatifs_facture ON justificatifs(facture_id);
CREATE INDEX IF NOT EXISTS idx_justificatifs_ecriture ON justificatifs(ecriture_id);
CREATE INDEX IF NOT EXISTS idx_justificatifs_client ON justificatifs(client_id);
CREATE INDEX IF NOT EXISTS idx_justificatifs_type ON justificatifs(type_document);
CREATE INDEX IF NOT EXISTS idx_justificatifs_archive ON justificatifs(archive);
CREATE INDEX IF NOT EXISTS idx_justificatifs_date ON justificatifs(date_document);
CREATE INDEX IF NOT EXISTS idx_justificatifs_provider ON justificatifs(storage_provider);

-- Table pour l'historique des modifications
CREATE TABLE IF NOT EXISTS justificatifs_historique (
    id SERIAL PRIMARY KEY,
    justificatif_id INTEGER NOT NULL REFERENCES justificatifs(id) ON DELETE CASCADE,
    action VARCHAR(50) NOT NULL, -- 'upload', 'download', 'archive', 'delete', 'update'
    details JSONB,
    utilisateur VARCHAR(100),
    date_action TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_justificatifs_historique_justificatif ON justificatifs_historique(justificatif_id);
CREATE INDEX IF NOT EXISTS idx_justificatifs_historique_date ON justificatifs_historique(date_action);

-- Vue pour les statistiques
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

-- Fonction pour enregistrer automatiquement les modifications
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

-- Commentaires
COMMENT ON TABLE justificatifs IS 'Stockage des métadonnées des justificatifs (pièces comptables)';
COMMENT ON COLUMN justificatifs.nom_fichier IS 'Nom unique du fichier sur le système de stockage';
COMMENT ON COLUMN justificatifs.nom_original IS 'Nom original du fichier uploadé';
COMMENT ON COLUMN justificatifs.chemin_stockage IS 'Chemin relatif ou absolu selon le provider';
COMMENT ON COLUMN justificatifs.storage_provider IS 'Provider de stockage: local ou cloud';
COMMENT ON COLUMN justificatifs.checksum IS 'Hash SHA-256 pour vérifier l''intégrité';
