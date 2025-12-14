const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// Récupérer toutes les entreprises
router.get('/', async (req, res) => {
  try {
    const query = `
      SELECT 
        id,
        nom,
        siret,
        adresse,
        code_postal,
        ville,
        email,
        telephone,
        regime_tva,
        date_cloture_exercice,
        created_at
      FROM entreprise
      ORDER BY nom ASC
    `;

    const result = await pool.query(query);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des entreprises' });
  }
});

// Récupérer une entreprise par ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const query = `
      SELECT 
        id,
        nom,
        siret,
        adresse,
        code_postal,
        ville,
        email,
        telephone,
        regime_tva,
        date_cloture_exercice,
        created_at
      FROM entreprise
      WHERE id = $1
    `;

    const result = await pool.query(query, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Entreprise non trouvée' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération de l\'entreprise' });
  }
});

// Créer une nouvelle entreprise
router.post('/', async (req, res) => {
  try {
    const {
      nom,
      siret,
      adresse,
      code_postal,
      ville,
      email,
      telephone,
      regime_tva,
      date_cloture_exercice
    } = req.body;

    const query = `
      INSERT INTO entreprise (
        nom, siret, adresse, code_postal, ville,
        email, telephone, regime_tva, date_cloture_exercice
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *
    `;

    const values = [
      nom,
      siret,
      adresse,
      code_postal,
      ville,
      email,
      telephone,
      regime_tva || 'reel_normal',
      date_cloture_exercice
    ];

    const result = await pool.query(query, values);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    if (err.code === '23505') {
      return res.status(400).json({ error: 'Une entreprise avec ce SIRET existe déjà' });
    }
    res.status(500).json({ error: 'Erreur lors de la création de l\'entreprise' });
  }
});

// Mettre à jour une entreprise
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const {
      nom,
      siret,
      adresse,
      code_postal,
      ville,
      email,
      telephone,
      regime_tva,
      date_cloture_exercice
    } = req.body;

    const query = `
      UPDATE entreprise
      SET 
        nom = $1,
        siret = $2,
        adresse = $3,
        code_postal = $4,
        ville = $5,
        email = $6,
        telephone = $7,
        regime_tva = $8,
        date_cloture_exercice = $9
      WHERE id = $10
      RETURNING *
    `;

    const values = [
      nom,
      siret,
      adresse,
      code_postal,
      ville,
      email,
      telephone,
      regime_tva,
      date_cloture_exercice,
      id
    ];

    const result = await pool.query(query, values);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Entreprise non trouvée' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    if (err.code === '23505') {
      return res.status(400).json({ error: 'Une entreprise avec ce SIRET existe déjà' });
    }
    res.status(500).json({ error: 'Erreur lors de la mise à jour de l\'entreprise' });
  }
});

// Supprimer une entreprise
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const query = 'DELETE FROM entreprise WHERE id = $1 RETURNING id';
    const result = await pool.query(query, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Entreprise non trouvée' });
    }

    res.json({ message: 'Entreprise supprimée avec succès' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la suppression de l\'entreprise' });
  }
});

module.exports = router;
