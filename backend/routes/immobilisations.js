const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// GET immobilisations
router.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM immobilisations ORDER BY date_acquisition DESC');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des immobilisations' });
  }
});

// GET amortissements
router.get('/amortissements', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT a.*, i.designation as immobilisation_nom
      FROM amortissements a
      LEFT JOIN immobilisations i ON a.immobilisation_id = i.id
      ORDER BY a.annee DESC, a.date_comptabilisation DESC
    `);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des amortissements' });
  }
});

// POST créer immobilisation
router.post('/', async (req, res) => {
  try {
    const {
      designation, categorie, date_acquisition, valeur_acquisition,
      duree_amortissement, methode_amortissement, taux_amortissement
    } = req.body;
    
    const result = await pool.query(`
      INSERT INTO immobilisations (
        designation, categorie, date_acquisition, valeur_acquisition,
        duree_amortissement, methode_amortissement, taux_amortissement,
        valeur_nette_comptable
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $4)
      RETURNING *
    `, [
      designation, categorie, date_acquisition, valeur_acquisition,
      duree_amortissement, methode_amortissement, taux_amortissement
    ]);
    
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la création de l\'immobilisation' });
  }
});

// POST créer amortissement
router.post('/amortissements', async (req, res) => {
  try {
    const { immobilisation_id, annee, montant, valeur_nette_comptable } = req.body;
    
    const result = await pool.query(`
      INSERT INTO amortissements (immobilisation_id, annee, montant, valeur_nette_comptable)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `, [immobilisation_id, annee, montant, valeur_nette_comptable]);
    
    // Mise à jour VNC de l'immobilisation
    await pool.query(
      'UPDATE immobilisations SET valeur_nette_comptable = $1 WHERE id = $2',
      [valeur_nette_comptable, immobilisation_id]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la création de l\'amortissement' });
  }
});

module.exports = router;
