const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const pool = require('../config/database');

// Validation middleware
const validateClient = [
  body('nom').notEmpty().withMessage('Le nom est requis'),
  body('email').optional().isEmail().withMessage('Email invalide'),
  body('siret').optional().isLength({ min: 14, max: 14 }).withMessage('SIRET doit contenir 14 caractères'),
];

// GET tous les clients
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM clients ORDER BY nom ASC'
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des clients' });
  }
});

// GET clients actifs uniquement
router.get('/actifs', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM clients WHERE actif = true ORDER BY nom ASC'
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des clients actifs' });
  }
});

// GET client par ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM clients WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Client non trouvé' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération du client' });
  }
});

// GET factures d'un client
router.get('/:id/factures', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Vérifier que le client existe
    const clientResult = await pool.query('SELECT nom FROM clients WHERE id = $1', [id]);
    if (clientResult.rows.length === 0) {
      return res.status(404).json({ error: 'Client non trouvé' });
    }
    
    const clientNom = clientResult.rows[0].nom;
    
    // Récupérer les factures du client
    const facturesResult = await pool.query(
      'SELECT * FROM factures WHERE client_fournisseur = $1 AND type = $2 ORDER BY date_emission DESC',
      [clientNom, 'vente']
    );
    
    res.json(facturesResult.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des factures du client' });
  }
});

// POST créer un nouveau client
router.post('/', validateClient, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const {
      nom,
      siret,
      adresse,
      code_postal,
      ville,
      pays,
      email,
      telephone,
      contact_principal,
      tva_intracommunautaire,
      conditions_paiement,
      notes,
      actif
    } = req.body;

    const result = await pool.query(
      `INSERT INTO clients (
        nom, siret, adresse, code_postal, ville, pays, email, telephone,
        contact_principal, tva_intracommunautaire, conditions_paiement, notes, actif
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
      RETURNING *`,
      [
        nom, siret, adresse, code_postal, ville, pays || 'France', email, telephone,
        contact_principal, tva_intracommunautaire, conditions_paiement, notes,
        actif !== undefined ? actif : true
      ]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Un client avec ce SIRET existe déjà' });
    }
    res.status(500).json({ error: 'Erreur lors de la création du client' });
  }
});

// PUT mettre à jour un client
router.put('/:id', validateClient, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { id } = req.params;
    const {
      nom,
      siret,
      adresse,
      code_postal,
      ville,
      pays,
      email,
      telephone,
      contact_principal,
      tva_intracommunautaire,
      conditions_paiement,
      notes,
      actif
    } = req.body;

    const result = await pool.query(
      `UPDATE clients SET
        nom = $1,
        siret = $2,
        adresse = $3,
        code_postal = $4,
        ville = $5,
        pays = $6,
        email = $7,
        telephone = $8,
        contact_principal = $9,
        tva_intracommunautaire = $10,
        conditions_paiement = $11,
        notes = $12,
        actif = $13,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $14
      RETURNING *`,
      [
        nom, siret, adresse, code_postal, ville, pays, email, telephone,
        contact_principal, tva_intracommunautaire, conditions_paiement, notes, actif, id
      ]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Client non trouvé' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Un client avec ce SIRET existe déjà' });
    }
    res.status(500).json({ error: 'Erreur lors de la mise à jour du client' });
  }
});

// DELETE supprimer un client
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Vérifier si le client a des factures
    const facturesCheck = await pool.query(
      'SELECT COUNT(*) as count FROM factures f JOIN clients c ON f.client_fournisseur = c.nom WHERE c.id = $1',
      [id]
    );
    
    if (parseInt(facturesCheck.rows[0].count) > 0) {
      return res.status(409).json({ 
        error: 'Impossible de supprimer ce client car il a des factures associées. Désactivez-le plutôt.' 
      });
    }

    const result = await pool.query(
      'DELETE FROM clients WHERE id = $1 RETURNING *',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Client non trouvé' });
    }

    res.json({ message: 'Client supprimé avec succès', client: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la suppression du client' });
  }
});

// PATCH désactiver/activer un client
router.patch('/:id/toggle-actif', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(
      'UPDATE clients SET actif = NOT actif, updated_at = CURRENT_TIMESTAMP WHERE id = $1 RETURNING *',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Client non trouvé' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la modification du statut du client' });
  }
});

// GET statistiques du client
router.get('/:id/stats', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Vérifier que le client existe
    const clientResult = await pool.query('SELECT nom FROM clients WHERE id = $1', [id]);
    if (clientResult.rows.length === 0) {
      return res.status(404).json({ error: 'Client non trouvé' });
    }
    
    const clientNom = clientResult.rows[0].nom;
    
    // Calculer les statistiques
    const statsResult = await pool.query(
      `SELECT 
        COUNT(*) as nombre_factures,
        COALESCE(SUM(montant_ttc), 0) as total_ttc,
        COALESCE(SUM(reste_a_payer), 0) as reste_a_payer,
        COALESCE(SUM(CASE WHEN statut = 'payee' THEN montant_ttc ELSE 0 END), 0) as total_paye
      FROM factures 
      WHERE client_fournisseur = $1 AND type = 'vente'`,
      [clientNom]
    );
    
    res.json(statsResult.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des statistiques' });
  }
});

module.exports = router;
