const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// GET informations entreprise
router.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM entreprise LIMIT 1');
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Informations entreprise non trouvées' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des informations' });
  }
});

// POST/PUT créer ou mettre à jour entreprise
router.post('/', async (req, res) => {
  try {
    const {
      nom, forme_juridique, siret, adresse, code_postal, ville,
      telephone, email, regime_tva, debut_exercice, fin_exercice
    } = req.body;
    
    // Vérifier si existe déjà
    const existing = await pool.query('SELECT id FROM entreprise LIMIT 1');
    
    let result;
    if (existing.rows.length > 0) {
      // Update
      result = await pool.query(`
        UPDATE entreprise SET
          nom = $1, forme_juridique = $2, siret = $3, adresse = $4,
          code_postal = $5, ville = $6, telephone = $7, email = $8,
          regime_tva = $9, debut_exercice = $10, fin_exercice = $11,
          updated_at = CURRENT_TIMESTAMP
        WHERE id = $12
        RETURNING *
      `, [
        nom, forme_juridique, siret, adresse, code_postal, ville,
        telephone, email, regime_tva, debut_exercice, fin_exercice,
        existing.rows[0].id
      ]);
    } else {
      // Insert
      result = await pool.query(`
        INSERT INTO entreprise (
          nom, forme_juridique, siret, adresse, code_postal, ville,
          telephone, email, regime_tva, debut_exercice, fin_exercice
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        RETURNING *
      `, [
        nom, forme_juridique, siret, adresse, code_postal, ville,
        telephone, email, regime_tva, debut_exercice, fin_exercice
      ]);
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la sauvegarde des informations' });
  }
});

module.exports = router;
