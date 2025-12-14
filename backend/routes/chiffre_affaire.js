const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// Récupérer le chiffre d'affaires par mois
router.get('/mensuel', async (req, res) => {
  try {
    const { exercice } = req.query;
    
    let whereClause = '';
    let params = [];

    if (exercice && exercice !== 'all') {
      // Filtrer par exercice (année)
      const annee = parseInt(exercice);
      whereClause = `AND EXTRACT(YEAR FROM p.date_paiement) = $1`;
      params.push(annee);
    }

    const query = `
      SELECT 
        EXTRACT(YEAR FROM p.date_paiement) as annee,
        EXTRACT(MONTH FROM p.date_paiement) as mois,
        TO_CHAR(DATE_TRUNC('month', p.date_paiement), 'YYYY-MM') as periode,
        TO_CHAR(DATE_TRUNC('month', p.date_paiement), 'Month YYYY') as periode_libelle,
        COUNT(DISTINCT f.id) as nombre_factures,
        SUM(p.montant) as chiffre_affaire,
        SUM(f.montant_ht * (p.montant / f.montant_ttc)) as chiffre_affaire_ht,
        SUM(f.montant_tva * (p.montant / f.montant_ttc)) as total_tva
      FROM paiements p
      INNER JOIN factures f ON p.facture_id = f.id
      WHERE f.type = 'vente'
        ${whereClause}
      GROUP BY annee, mois, periode, periode_libelle
      ORDER BY annee, mois
    `;

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération du CA mensuel' });
  }
});

// Récupérer les statistiques globales du CA
router.get('/statistiques', async (req, res) => {
  try {
    const { exercice } = req.query;
    
    let whereClause = '';
    let params = [];

    if (exercice && exercice !== 'all') {
      const annee = parseInt(exercice);
      whereClause = `AND EXTRACT(YEAR FROM p.date_paiement) = $1`;
      params.push(annee);
    }

    const query = `
      SELECT 
        COUNT(DISTINCT f.id) as nombre_factures,
        SUM(p.montant) as chiffre_affaire_total,
        SUM(f.montant_ht * (p.montant / f.montant_ttc)) as chiffre_affaire_ht_total,
        SUM(f.montant_tva * (p.montant / f.montant_ttc)) as tva_totale,
        AVG(p.montant) as montant_moyen,
        MAX(p.montant) as montant_max,
        MIN(p.montant) as montant_min
      FROM paiements p
      INNER JOIN factures f ON p.facture_id = f.id
      WHERE f.type = 'vente'
        ${whereClause}
    `;

    const result = await pool.query(query, params);
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des statistiques CA' });
  }
});

// Récupérer les exercices disponibles
router.get('/exercices', async (req, res) => {
  try {
    const query = `
      SELECT DISTINCT 
        EXTRACT(YEAR FROM p.date_paiement) as annee
      FROM paiements p
      INNER JOIN factures f ON p.facture_id = f.id
      WHERE f.type = 'vente'
      ORDER BY annee DESC
    `;

    const result = await pool.query(query);
    res.json(result.rows.map(row => row.annee));
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des exercices' });
  }
});

// Récupérer le CA par client pour un exercice
router.get('/par-client', async (req, res) => {
  try {
    const { exercice } = req.query;
    
    let whereClause = '';
    let params = [];

    if (exercice && exercice !== 'all') {
      const annee = parseInt(exercice);
      whereClause = `AND EXTRACT(YEAR FROM p.date_paiement) = $1`;
      params.push(annee);
    }

    const query = `
      SELECT 
        f.client_fournisseur as nom,
        COUNT(DISTINCT f.id) as nombre_factures,
        SUM(p.montant) as chiffre_affaire,
        SUM(f.montant_ht * (p.montant / f.montant_ttc)) as chiffre_affaire_ht
      FROM paiements p
      INNER JOIN factures f ON p.facture_id = f.id
      WHERE f.type = 'vente'
        ${whereClause}
      GROUP BY f.client_fournisseur
      ORDER BY chiffre_affaire DESC
      LIMIT 10
    `;

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération du CA par client' });
  }
});

module.exports = router;
