const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// Journal Comptable
router.get('/journal', async (req, res) => {
  try {
    const { debut, fin, journal } = req.query;
    
    let query = `
      SELECT * FROM ecritures_comptables 
      WHERE date_ecriture BETWEEN $1 AND $2
    `;
    const params = [debut, fin];
    
    if (journal) {
      query += ` AND journal = $3`;
      params.push(journal);
    }
    
    query += ` ORDER BY date_ecriture, id`;
    
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération du journal' });
  }
});

// Grand Livre
router.get('/grand-livre', async (req, res) => {
  try {
    const { debut, fin, compte } = req.query;
    
    let whereClause = 'WHERE date_ecriture BETWEEN $1 AND $2';
    const params = [debut, fin];
    
    if (compte) {
      whereClause += ' AND compte = $3';
      params.push(compte);
    }
    
    // Récupérer tous les comptes avec leurs écritures
    const query = `
      SELECT 
        compte as numero_compte,
        MAX(COALESCE(compte, '')) as nom_compte,
        0 as solde_initial,
        SUM(debit) as total_debit,
        SUM(credit) as total_credit,
        SUM(debit - credit) as solde_final,
        json_agg(
          json_build_object(
            'id', id,
            'date_ecriture', date_ecriture,
            'libelle', libelle,
            'debit', debit,
            'credit', credit,
            'journal', journal
          ) ORDER BY date_ecriture
        ) as ecritures
      FROM ecritures_comptables
      ${whereClause}
      GROUP BY compte
      ORDER BY compte
    `;
    
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération du grand livre' });
  }
});

// Bilan Comptable
router.get('/bilan', async (req, res) => {
  try {
    const { date } = req.query;
    
    // Récupérer les soldes des comptes de bilan
    const query = `
      SELECT 
        CASE 
          WHEN compte LIKE '1%' THEN 'Capitaux propres'
          WHEN compte LIKE '2%' THEN 'Immobilisations'
          WHEN compte LIKE '3%' THEN 'Stocks'
          WHEN compte LIKE '4%' AND compte < '43' THEN 'Créances clients'
          WHEN compte LIKE '4%' AND compte >= '43' THEN 'Dettes fournisseurs'
          WHEN compte LIKE '5%' THEN 'Trésorerie'
          ELSE 'Autres'
        END as categorie,
        CASE
          WHEN compte LIKE '2%' OR compte LIKE '3%' OR (compte LIKE '4%' AND compte < '43') OR compte LIKE '5%' THEN 'actif'
          ELSE 'passif'
        END as type,
        SUM(debit - credit) as solde
      FROM ecritures_comptables
      WHERE date_ecriture <= $1
      GROUP BY categorie, type
      HAVING SUM(debit - credit) != 0
    `;
    
    const result = await pool.query(query, [date]);
    
    const actif = {};
    const passif = {};
    let totalActif = 0;
    let totalPassif = 0;
    
    result.rows.forEach(row => {
      const montant = Math.abs(row.solde);
      if (row.type === 'actif') {
        actif[row.categorie] = montant;
        totalActif += montant;
      } else {
        passif[row.categorie] = montant;
        totalPassif += montant;
      }
    });
    
    // Calculer le résultat
    const resultat = totalActif - totalPassif;
    
    res.json({
      date_arrete: date,
      actif,
      passif,
      total_actif: totalActif,
      total_passif: totalPassif,
      resultat,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la génération du bilan' });
  }
});

// Compte de Résultat
router.get('/compte-resultat', async (req, res) => {
  try {
    const { debut, fin } = req.query;
    
    const query = `
      SELECT 
        CASE 
          WHEN compte LIKE '6%' THEN 
            CASE 
              WHEN compte LIKE '60%' THEN 'Achats'
              WHEN compte LIKE '61%' THEN 'Services extérieurs'
              WHEN compte LIKE '62%' THEN 'Autres services'
              WHEN compte LIKE '63%' THEN 'Impôts et taxes'
              WHEN compte LIKE '64%' THEN 'Charges de personnel'
              WHEN compte LIKE '65%' THEN 'Autres charges'
              WHEN compte LIKE '66%' THEN 'Charges financières'
              WHEN compte LIKE '67%' THEN 'Charges exceptionnelles'
              WHEN compte LIKE '68%' THEN 'Dotations aux amortissements'
              ELSE 'Autres charges'
            END
          WHEN compte LIKE '7%' THEN 
            CASE 
              WHEN compte LIKE '70%' THEN 'Ventes de marchandises'
              WHEN compte LIKE '71%' THEN 'Production vendue'
              WHEN compte LIKE '72%' THEN 'Production stockée'
              WHEN compte LIKE '74%' THEN 'Subventions d\'exploitation'
              WHEN compte LIKE '75%' THEN 'Autres produits'
              WHEN compte LIKE '76%' THEN 'Produits financiers'
              WHEN compte LIKE '77%' THEN 'Produits exceptionnels'
              WHEN compte LIKE '78%' THEN 'Reprises sur amortissements'
              ELSE 'Autres produits'
            END
          ELSE 'Autres'
        END as categorie,
        CASE
          WHEN compte LIKE '6%' THEN 'charges'
          WHEN compte LIKE '7%' THEN 'produits'
          ELSE 'autre'
        END as type,
        SUM(CASE WHEN compte LIKE '6%' THEN debit ELSE credit END) as montant
      FROM ecritures_comptables
      WHERE date_ecriture BETWEEN $1 AND $2
        AND (compte LIKE '6%' OR compte LIKE '7%')
      GROUP BY categorie, type
      HAVING SUM(CASE WHEN compte LIKE '6%' THEN debit ELSE credit END) > 0
    `;
    
    const result = await pool.query(query, [debut, fin]);
    
    const charges = {};
    const produits = {};
    let totalCharges = 0;
    let totalProduits = 0;
    
    result.rows.forEach(row => {
      if (row.type === 'charges') {
        charges[row.categorie] = row.montant;
        totalCharges += row.montant;
      } else if (row.type === 'produits') {
        produits[row.categorie] = row.montant;
        totalProduits += row.montant;
      }
    });
    
    const resultatNet = totalProduits - totalCharges;
    
    res.json({
      periode_debut: debut,
      periode_fin: fin,
      charges,
      produits,
      total_charges: totalCharges,
      total_produits: totalProduits,
      resultat_net: resultatNet,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la génération du compte de résultat' });
  }
});

// Balance des comptes
router.get('/balance', async (req, res) => {
  try {
    const { debut, fin } = req.query;
    
    const query = `
      SELECT 
        compte,
        SUM(debit) as total_debit,
        SUM(credit) as total_credit,
        SUM(debit - credit) as solde
      FROM ecritures_comptables
      WHERE date_ecriture BETWEEN $1 AND $2
      GROUP BY compte
      HAVING SUM(debit) != 0 OR SUM(credit) != 0
      ORDER BY compte
    `;
    
    const result = await pool.query(query, [debut, fin]);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération de la balance' });
  }
});

// Export PDF (placeholder - nécessite une bibliothèque PDF)
router.get('/export/pdf/:type', async (req, res) => {
  const { type } = req.params;
  res.json({ 
    message: `Export PDF ${type} - Fonctionnalité à implémenter avec PDFKit ou similaire`,
    url: `/api/documents/${type}?${new URLSearchParams(req.query)}`
  });
});

// Export Excel (placeholder - nécessite une bibliothèque Excel)
router.get('/export/excel/:type', async (req, res) => {
  const { type } = req.params;
  res.json({ 
    message: `Export Excel ${type} - Fonctionnalité à implémenter avec ExcelJS ou similaire`,
    url: `/api/documents/${type}?${new URLSearchParams(req.query)}`
  });
});

module.exports = router;
