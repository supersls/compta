const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// GET déclarations TVA
router.get('/declarations', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM declarations_tva ORDER BY periode_debut DESC'
    );
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
    
    const tva_a_decaisser = tva_collectee - tva_deductible;
    
    const result = await pool.query(`
      INSERT INTO declarations_tva (
        periode_debut, periode_fin, tva_collectee, tva_deductible, 
        tva_a_decaisser, statut
      ) VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `, [periode_debut, periode_fin, tva_collectee, tva_deductible, tva_a_decaisser, statut || 'en_cours']);
    
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la création de la déclaration TVA' });
  }
});

module.exports = router;
