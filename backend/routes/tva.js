const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// GET déclarations TVA
router.get('/declarations', async (req, res) => {
  try {
    const { entreprise_id } = req.query;
    
    let query = 'SELECT * FROM declarations_tva';
    const params = [];
    
    if (entreprise_id) {
      query += ' WHERE entreprise_id = $1';
      params.push(entreprise_id);
    }
    
    query += ' ORDER BY periode_debut DESC';
    
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des déclarations TVA' });
  }
});

// GET calcul TVA pour une période
router.get('/calcul/:debut/:fin', async (req, res) => {
  try {
    const { debut, fin } = req.params;
    
    const result = await pool.query(`
      SELECT 
        SUM(CASE WHEN type = 'vente' THEN montant_tva ELSE 0 END) as tva_collectee,
        SUM(CASE WHEN type = 'achat' THEN montant_tva ELSE 0 END) as tva_deductible
      FROM factures
      WHERE date_emission BETWEEN $1 AND $2
    `, [debut, fin]);
    
    const tvaCollectee = parseFloat(result.rows[0].tva_collectee || 0);
    const tvaDeductible = parseFloat(result.rows[0].tva_deductible || 0);
    const tvaADecaisser = tvaCollectee - tvaDeductible;
    
    res.json({
      tvaCollectee,
      tvaDeductible,
      tvaADecaisser,
      periodeDebut: debut,
      periodeFin: fin
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors du calcul de la TVA' });
  }
});

// POST créer déclaration TVA
router.post('/declarations', async (req, res) => {
  try {
    const { periode_debut, periode_fin, tva_collectee, tva_deductible, statut } = req.body;
    
    const tva_a_payer = tva_collectee - tva_deductible;
    
    const result = await pool.query(`
      INSERT INTO declarations_tva (
        periode_debut, periode_fin, tva_collectee, tva_deductible, 
        tva_a_payer, statut
      ) VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `, [periode_debut, periode_fin, tva_collectee, tva_deductible, tva_a_payer, statut || 'brouillon']);
    
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la création de la déclaration TVA' });
  }
});

// PUT modifier déclaration TVA
router.put('/declarations/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { periode_debut, periode_fin, tva_collectee, tva_deductible } = req.body;
    
    const tva_a_payer = tva_collectee - tva_deductible;
    
    const result = await pool.query(`
      UPDATE declarations_tva 
      SET periode_debut = $1, periode_fin = $2, tva_collectee = $3, 
          tva_deductible = $4, tva_a_payer = $5
      WHERE id = $6
      RETURNING *
    `, [periode_debut, periode_fin, tva_collectee, tva_deductible, tva_a_payer, id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Déclaration non trouvée' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la modification de la déclaration TVA' });
  }
});

// DELETE supprimer déclaration TVA
router.delete('/declarations/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(
      'DELETE FROM declarations_tva WHERE id = $1 RETURNING *',
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Déclaration non trouvée' });
    }
    
    res.json({ message: 'Déclaration supprimée avec succès' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la suppression de la déclaration TVA' });
  }
});

// PATCH valider déclaration
router.patch('/declarations/:id/valider', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(`
      UPDATE declarations_tva 
      SET statut = 'validee', date_validation = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Déclaration non trouvée' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la validation de la déclaration' });
  }
});

// PATCH marquer transmise
router.patch('/declarations/:id/transmettre', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(`
      UPDATE declarations_tva 
      SET statut = 'transmise', date_transmission = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Déclaration non trouvée' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la transmission de la déclaration' });
  }
});

// PATCH marquer payée
router.patch('/declarations/:id/payer', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(`
      UPDATE declarations_tva 
      SET statut = 'payee', date_paiement = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Déclaration non trouvée' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors du paiement de la déclaration' });
  }
});

// GET statistiques TVA
router.get('/statistiques', async (req, res) => {
  try {
    const { entreprise_id } = req.query;
    
    let query = `
      SELECT 
        COALESCE(SUM(tva_collectee), 0) as total_collectee,
        COALESCE(SUM(tva_deductible), 0) as total_deductible,
        COALESCE(SUM(tva_a_payer), 0) as total_a_payer,
        COUNT(*) as nombre_declarations,
        COUNT(CASE WHEN statut = 'payee' THEN 1 END) as declarations_payees
      FROM declarations_tva
      WHERE EXTRACT(YEAR FROM periode_debut) = EXTRACT(YEAR FROM CURRENT_DATE)`;
    
    const params = [];
    if (entreprise_id) {
      query += ' AND entreprise_id = $1';
      params.push(entreprise_id);
    }
    
    const result = await pool.query(query, params);
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des statistiques' });
  }
});

// GET détail par taux
router.get('/detail-taux/:debut/:fin', async (req, res) => {
  try {
    const { debut, fin } = req.params;
    const { entreprise_id } = req.query;
    
    let query = `
      SELECT 
        taux_tva as taux,
        SUM(CASE WHEN type = 'vente' THEN montant_tva ELSE 0 END) as tva_collectee,
        SUM(CASE WHEN type = 'achat' THEN montant_tva ELSE 0 END) as tva_deductible
      FROM factures
      WHERE date_emission BETWEEN $1 AND $2`;
    
    const params = [debut, fin];
    
    if (entreprise_id) {
      query += ' AND entreprise_id = $3';
      params.push(entreprise_id);
    }
    
    query += `
      GROUP BY taux_tva
      ORDER BY taux_tva DESC`;
    
    const result = await pool.query(query, params);
    
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération du détail par taux' });
  }
});

module.exports = router;
