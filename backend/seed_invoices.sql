-- Seed script for invoices
-- This script populates the factures table with sample data

-- Disable foreign key checks temporarily (if needed)
-- SET session_replication_role = 'replica';

-- Insert invoices from the CSV data
INSERT INTO factures (numero, type, date_emission, date_echeance, client_fournisseur, montant_ht, montant_tva, montant_ttc, statut, categorie, notes, created_at, updated_at)
VALUES
('FAC-2025-001', 'vente', '2025-11-29', '2025-12-29', 'ITERA', 8640.00, 1728.00, 10368.00, 'en_attente', NULL, 'Facture de Novembre 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2025-002', 'vente', '2025-10-02', '2025-11-02', 'ITERA', 10800.00, 2160.00, 12960.00, 'en_attente', NULL, 'Facture de Octobre 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2025-003', 'vente', '2025-09-30', '2025-10-30', 'ITERA', 11880.00, 2376.00, 14256.00, 'payee', NULL, 'Facture de Septembre 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2025-004', 'vente', '2025-08-13', '2025-09-13', 'ITERA', 10260.00, 2052.00, 12312.00, 'payee', NULL, 'Facture de Août 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2025-005', 'vente', '2025-07-31', '2025-08-31', 'ITERA', 11880.00, 2376.00, 14256.00, 'payee', NULL, 'Facture de Juillet 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2025-006', 'vente', '2025-06-30', '2025-07-30', 'ITERA', 10584.00, 2116.80, 12700.80, 'payee', NULL, 'Facture de Juin 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2025-007', 'vente', '2025-05-30', '2025-06-30', 'ITERA', 4030.00, 806.00, 4836.00, 'payee', NULL, 'Facture de Mai 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2025-008', 'vente', '2025-04-30', '2025-05-30', 'ITERA', 10080.00, 2016.00, 12096.00, 'payee', NULL, 'Facture de Avril 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2025-009', 'vente', '2025-03-31', '2025-04-30', 'ITERA', 10584.00, 2116.80, 12700.80, 'payee', NULL, 'Facture de Mars 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2025-010', 'vente', '2025-02-28', '2025-03-30', 'ITERA', 9576.00, 1915.20, 11491.20, 'en_attente', NULL, 'Facture de Février 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2025-011', 'vente', '2025-02-28', '2025-03-30', 'ITERA', 10584.00, 2116.80, 12700.80, 'payee', NULL, 'Facture de Février 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2025-012', 'vente', '2025-01-31', '2025-02-28', 'ITERA', 8048.00, 1609.60, 9657.60, 'payee', NULL, 'Facture de Janvier 2025 - ITERA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2025-013', 'vente', '2025-01-20', '2025-02-20', 'Weevi', 5076.00, 1015.20, 6091.20, 'payee', NULL, 'Facture de Janvier 2025 - WaVii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2024-014', 'vente', '2024-12-06', '2025-01-06', 'Weevi', 7611.00, 1522.20, 9133.20, 'payee', NULL, 'Facture de Décembre 2024 - WaVii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2024-015', 'vente', '2024-11-15', '2024-12-15', 'Weevi', 9156.80, 1831.36, 10988.16, 'payee', NULL, 'Facture de Novembre 2024 - WaVii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2024-016', 'vente', '2024-10-01', '2024-11-01', 'Weevi', 15675.80, 3135.16, 18810.96, 'payee', NULL, 'Facture de Octobre 2024 - WaVii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2024-017', 'vente', '2024-09-16', '2024-10-16', 'Weevi', 1522.50, 304.50, 1827.00, 'payee', NULL, 'Facture de Septembre 2024 - WaVii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2024-018', 'vente', '2024-08-01', '2024-09-01', 'Weevi', 8121.60, 1624.32, 9745.92, 'payee', NULL, 'Facture de Août 2024 - WaVii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2024-019', 'vente', '2024-07-02', '2024-08-02', 'Weevi', 10659.60, 2131.92, 12791.52, 'payee', NULL, 'Facture de Juillet 2024 - Weevii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2024-020', 'vente', '2024-06-05', '2024-07-05', 'Weevi', 7611.00, 1522.20, 9133.20, 'payee', NULL, 'Facture de Juin 2024 - Weevii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2024-021', 'vente', '2024-05-06', '2024-06-06', 'Weevi', 9360.60, 1872.12, 11232.72, 'payee', NULL, 'Facture de Mai 2024 - Weevii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2024-022', 'vente', '2024-04-05', '2024-05-05', 'Weevi', 8460.00, 1692.00, 10152.00, 'payee', NULL, 'Facture de Avril 2024 - Weevii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2024-023', 'vente', '2024-03-05', '2024-04-05', 'Weevi', 8160.00, 1632.00, 9792.00, 'payee', NULL, 'Facture de Mars 2024 - Weevi', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2024-024', 'vente', '2024-02-05', '2024-03-05', 'Weevi', 8832.00, 1766.40, 10598.40, 'payee', NULL, 'Facture de Février 2024 - Waevii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2024-025', 'vente', '2024-01-05', '2024-02-05', 'Weevi', 9306.00, 1861.20, 11167.20, 'payee', NULL, 'Facture de Janvier 2024 - Waevii', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2023-026', 'vente', '2023-12-05', '2024-01-05', 'Weevi', 8940.00, 1788.00, 10728.00, 'payee', NULL, 'Décembre 2023 - Waevi', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('FAC-2023-027', 'vente', '2023-11-05', '2023-12-05', 'Weevi', 3507.00, 701.40, 4208.40, 'payee', NULL, 'Novembre 2023 - Waovi', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Set montant_paye for paid invoices
UPDATE factures SET montant_paye = montant_ttc WHERE statut = 'payee';

-- Calculate and set reste_a_payer for all invoices
UPDATE factures SET reste_a_payer = montant_ttc - montant_paye;

-- Re-enable foreign key checks if needed
-- SET session_replication_role = 'origin';

-- Verification
SELECT COUNT(*) as total_invoices FROM factures;
SELECT SUM(montant_ttc) as total_amount FROM factures;
SELECT statut, COUNT(*) as count FROM factures GROUP BY statut;
