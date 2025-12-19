-- Données de test pour Compta EI
-- Script d'insertion de données mock

-- Se connecter à la base de données
\c compta_ei;

-- ============================================================================
-- PLAN COMPTABLE GÉNÉRAL (PCG) - Données essentielles
-- ============================================================================

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

-- ============================================================================
-- JOURNAUX COMPTABLES - Données essentielles
-- ============================================================================

INSERT INTO journaux (code, nom, description, type, actif) VALUES
('VE', 'Ventes', 'Journal des ventes et prestations de services', 'vente', true),
('AC', 'Achats', 'Journal des achats et charges', 'achat', true),
('BQ', 'Banque', 'Journal des opérations bancaires', 'banque', true),
('CA', 'Caisse', 'Journal des opérations de caisse', 'caisse', true),
('OD', 'Opérations Diverses', 'Journal des opérations diverses', 'operations_diverses', true)
ON CONFLICT (code) DO NOTHING;

-- ============================================================================
-- TYPES D'IMMOBILISATION - Données essentielles
-- ============================================================================

INSERT INTO types_immobilisation (code, nom, description, duree_amortissement_defaut, compte_immobilisation_defaut, compte_amortissement_defaut, actif) VALUES
('MATERIEL', 'Matériel et outillage', 'Matériel et outillage industriel et commercial', 5, '2154', '28154', true),
('VEHICULE', 'Véhicule', 'Véhicules de tourisme et utilitaires', 5, '2182', '28182', true),
('MOBILIER', 'Mobilier', 'Mobilier de bureau', 10, '2184', '28184', true),
('INFORMATIQUE', 'Matériel informatique', 'Ordinateurs, serveurs, équipements informatiques', 3, '2183', '28183', true),
('LOGICIEL', 'Logiciel', 'Logiciels et licences', 3, '205', '2805', true),
('IMMOBILIER', 'Immobilier', 'Constructions et bâtiments', 20, '213', '2813', true)
ON CONFLICT (code) DO NOTHING;

-- ============================================================================
-- ENTREPRISE - Données de démonstration
-- ============================================================================

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

-- ============================================================================
-- CLIENTS - Données de test
-- ============================================================================

INSERT INTO clients (entreprise_id, nom, siret, adresse, code_postal, ville, email, telephone, contact_principal, actif, created_at, updated_at)
VALUES 
(1, 'ITERA', '12312312312312', '123 Rue du Commerce', '75015', 'Paris', 'contact@itera.fr', '0145678912', 'Jean Dupont', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'Weevi', '12312312312313', '456 Avenue des Champs', '75008', 'Paris', 'contact@weevi.fr', '0145678913', 'Marie Martin', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- COMPTES BANCAIRES - Données de test
-- ============================================================================

INSERT INTO comptes_bancaires (entreprise_id, nom, banque, numero_compte, iban, solde_initial, solde_actuel, date_ouverture, actif)
VALUES
  (1, 'Compte Courant Principal', 'BNP Paribas', '30004012345678901', 'FR7630004012345678901234567', 5000.00, 12500.00, '2023-01-10', true)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- TRANSACTIONS BANCAIRES - Données de test
-- ============================================================================

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

-- ============================================================================
-- IMMOBILISATIONS - Données de test
-- ============================================================================

INSERT INTO immobilisations (entreprise_id, libelle, type, date_acquisition, valeur_acquisition, duree_amortissement, methode_amortissement, taux_amortissement, compte_immobilisation, compte_amortissement, en_service)
VALUES
  (1, 'Ordinateur portable Dell XPS', 'materiel', '2024-01-15', 1500.00, 3, 'lineaire', 33.33, '2183', '28183', true),
  (1, 'Véhicule utilitaire Renault', 'vehicule', '2023-06-01', 25000.00, 5, 'lineaire', 20.00, '2182', '28182', true),
  (1, 'Photocopieur professionnel', 'materiel', '2024-03-20', 3500.00, 5, 'lineaire', 20.00, '2183', '28183', true),
  (1, 'Bureau ergonomique', 'mobilier', '2024-02-10', 800.00, 10, 'lineaire', 10.00, '2184', '28183', true),
  (1, 'Serveur informatique', 'materiel', '2023-09-01', 8000.00, 3, 'lineaire', 33.33, '2183', '28183', true)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- FACTURES - Données de test (2023-2025)
-- ============================================================================

INSERT INTO factures (entreprise_id, numero, type, date_emission, date_echeance, client_fournisseur, montant_ht, montant_tva, montant_ttc, statut, categorie, notes, created_at, updated_at)
VALUES
-- Factures 2025
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
-- Factures 2024
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
-- Factures 2023
(1, 'FAC-2023-026', 'vente', '2023-12-05', '2024-01-05', 'Weevi', 8940.00, 1788.00, 10728.00, 'payee', NULL, 'Décembre 2023 - Waevi', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'FAC-2023-027', 'vente', '2023-11-05', '2023-12-05', 'Weevi', 3507.00, 701.40, 4208.40, 'payee', NULL, 'Novembre 2023 - Waovi', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (numero) DO NOTHING;

-- Mise à jour des montants payés pour les factures payées
UPDATE factures SET montant_paye = montant_ttc WHERE statut = 'payee';

-- Calcul et mise à jour du reste à payer pour toutes les factures
UPDATE factures SET reste_a_payer = montant_ttc - montant_paye;

-- ============================================================================
-- PAIEMENTS - Données de test
-- ============================================================================

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

-- ============================================================================
-- ÉCRITURES COMPTABLES - Données de test
-- ============================================================================

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

-- ============================================================================
-- RÉSUMÉ FINAL
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Données de test insérées avec succès!';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Comptes PCG: %', (SELECT COUNT(*) FROM comptes_pcg);
    RAISE NOTICE 'Entreprises: %', (SELECT COUNT(*) FROM entreprise);
    RAISE NOTICE 'Clients: %', (SELECT COUNT(*) FROM clients);
    RAISE NOTICE 'Factures: %', (SELECT COUNT(*) FROM factures);
    RAISE NOTICE 'Montant total factures: % €', (SELECT COALESCE(SUM(montant_ttc), 0) FROM factures);
    RAISE NOTICE 'Paiements: %', (SELECT COUNT(*) FROM paiements);
    RAISE NOTICE 'Écritures comptables: %', (SELECT COUNT(*) FROM ecritures_comptables);
    RAISE NOTICE 'Immobilisations: %', (SELECT COUNT(*) FROM immobilisations);
    RAISE NOTICE 'Transactions bancaires: %', (SELECT COUNT(*) FROM transactions_bancaires);
    RAISE NOTICE '============================================================';
END $$;
