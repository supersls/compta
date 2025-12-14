const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const pool = require('../config/database');

// Validation middleware
const validateFacture = [
  body('numero').notEmpty().withMessage('Le numéro est requis'),
  body('type').isIn(['vente', 'achat']).withMessage('Type invalide'),
  body('client_fournisseur').notEmpty().withMessage('Client/Fournisseur requis'),
  body('montant_ht').isFloat({ min: 0 }).withMessage('Montant HT invalide'),
  body('montant_tva').isFloat({ min: 0 }).withMessage('Montant TVA invalide'),
  body('montant_ttc').isFloat({ min: 0 }).withMessage('Montant TTC invalide'),
  body('date_emission').isISO8601().withMessage('Date émission invalide'),
];

// GET toutes les factures
router.get('/', async (req, res) => {
  try {
    const { entreprise_id } = req.query;
    
    if (!entreprise_id) {
      return res.status(400).json({ error: 'entreprise_id est requis' });
    }
    
    const result = await pool.query(
      'SELECT * FROM factures WHERE entreprise_id = $1 ORDER BY date_emission DESC',
      [entreprise_id]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des factures' });
  }
});

// GET facture par ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM factures WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Facture non trouvée' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération de la facture' });
  }
});

// GET factures par type
router.get('/type/:type', async (req, res) => {
  try {
    const { type } = req.params;
    
    if (!['vente', 'achat'].includes(type)) {
      return res.status(400).json({ error: 'Type invalide' });
    }
    
    const result = await pool.query(
      'SELECT * FROM factures WHERE type = $1 ORDER BY date_emission DESC',
      [type]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des factures' });
  }
});

// GET factures par statut
router.get('/statut/:statut', async (req, res) => {
  try {
    const { statut } = req.params;
    const result = await pool.query(
      'SELECT * FROM factures WHERE statut = $1 ORDER BY date_emission DESC',
      [statut]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des factures' });
  }
});

// GET factures en retard
router.get('/filter/retard', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT * FROM factures 
      WHERE statut != 'payee' 
      AND date_echeance IS NOT NULL 
      AND date_echeance < CURRENT_DATE
      ORDER BY date_echeance ASC
    `);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des factures' });
  }
});

// GET statistiques
router.get('/stats/overview', async (req, res) => {
  try {
    const { entreprise_id } = req.query;
    
    if (!entreprise_id) {
      return res.status(400).json({ error: 'entreprise_id est requis' });
    }
    
    const result = await pool.query(`
      SELECT 
        SUM(CASE WHEN type = 'vente' THEN montant_ttc ELSE 0 END) as total_ventes,
        SUM(CASE WHEN type = 'achat' THEN montant_ttc ELSE 0 END) as total_achats,
        SUM(CASE WHEN statut != 'payee' THEN reste_a_payer ELSE 0 END) as total_impayees,
        COUNT(CASE WHEN statut != 'payee' THEN 1 END) as count_impayees,
        COUNT(CASE WHEN statut != 'payee' AND date_echeance < CURRENT_DATE THEN 1 END) as count_retard,
        COUNT(CASE WHEN type = 'vente' THEN 1 END) as countVentes
      FROM factures
      WHERE entreprise_id = $1
    `, [entreprise_id]);
    
    const stats = result.rows[0];
    res.json({
      totalVentes: parseFloat(stats.total_ventes || 0),
      totalAchats: parseFloat(stats.total_achats || 0),
      totalImpayees: parseFloat(stats.total_impayees || 0),
      countImpayees: parseInt(stats.count_impayees || 0),
      countRetard: parseInt(stats.count_retard || 0),
      countVentes: parseInt(stats.countVentes || 0)
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors du calcul des statistiques' });
  }
});

// POST recherche factures
router.post('/search', async (req, res) => {
  try {
    const { query } = req.body;
    const searchPattern = `%${query}%`;
    
    const result = await pool.query(`
      SELECT * FROM factures 
      WHERE numero ILIKE $1 
      OR client_fournisseur ILIKE $1 
      OR notes ILIKE $1
      ORDER BY date_emission DESC
    `, [searchPattern]);
    
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la recherche' });
  }
});

// GET factures par période
router.get('/periode/:debut/:fin', async (req, res) => {
  try {
    const { debut, fin } = req.params;
    const result = await pool.query(
      'SELECT * FROM factures WHERE date_emission BETWEEN $1 AND $2 ORDER BY date_emission DESC',
      [debut, fin]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des factures' });
  }
});

// POST générer numéro facture
router.post('/generer-numero', async (req, res) => {
  try {
    const { type } = req.body;
    
    if (!['vente', 'achat'].includes(type)) {
      return res.status(400).json({ error: 'Type invalide' });
    }
    
    const annee = new Date().getFullYear();
    const prefix = type === 'vente' ? 'FAC' : 'ACH';
    
    const result = await pool.query(`
      SELECT MAX(CAST(SUBSTRING(numero FROM '[0-9]+$') AS INTEGER)) as max_num
      FROM factures
      WHERE numero LIKE $1
    `, [`${prefix}-${annee}-%`]);
    
    const maxNum = result.rows[0].max_num || 0;
    const nextNum = maxNum + 1;
    const numero = `${prefix}-${annee}-${String(nextNum).padStart(4, '0')}`;
    
    res.json({ numero });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la génération du numéro' });
  }
});

// POST créer facture
router.post('/', validateFacture, async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  
  try {
    const {
      numero,
      type,
      date_emission,
      date_echeance,
      client_fournisseur,
      siret_client,
      montant_ht,
      montant_tva,
      montant_ttc,
      statut,
      montant_paye,
      categorie,
      notes
    } = req.body;
    
    const reste_a_payer = montant_ttc - (montant_paye || 0);
    
    const result = await pool.query(`
      INSERT INTO factures (
        numero, type, date_emission, date_echeance, client_fournisseur,
        siret_client, montant_ht, montant_tva, montant_ttc, statut,
        montant_paye, reste_a_payer, categorie, notes
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
      RETURNING *
    `, [
      numero, type, date_emission, date_echeance, client_fournisseur,
      siret_client, montant_ht, montant_tva, montant_ttc, statut || 'en_attente',
      montant_paye || 0, reste_a_payer, categorie, notes
    ]);
    
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la création de la facture' });
  }
});

// PUT mettre à jour facture
router.put('/:id', validateFacture, async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  
  try {
    const { id } = req.params;
    const {
      numero,
      type,
      date_emission,
      date_echeance,
      client_fournisseur,
      siret_client,
      montant_ht,
      montant_tva,
      montant_ttc,
      statut,
      montant_paye,
      categorie,
      notes
    } = req.body;
    
    const reste_a_payer = montant_ttc - (montant_paye || 0);
    
    const result = await pool.query(`
      UPDATE factures SET
        numero = $1, type = $2, date_emission = $3, date_echeance = $4,
        client_fournisseur = $5, siret_client = $6, montant_ht = $7,
        montant_tva = $8, montant_ttc = $9, statut = $10, montant_paye = $11,
        reste_a_payer = $12, categorie = $13, notes = $14, updated_at = CURRENT_TIMESTAMP
      WHERE id = $15
      RETURNING *
    `, [
      numero, type, date_emission, date_echeance, client_fournisseur,
      siret_client, montant_ht, montant_tva, montant_ttc, statut,
      montant_paye, reste_a_payer, categorie, notes, id
    ]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Facture non trouvée' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la mise à jour de la facture' });
  }
});

// PATCH mettre à jour statut
router.patch('/:id/statut', async (req, res) => {
  try {
    const { id } = req.params;
    const { montant_paye } = req.body;
    
    const facture = await pool.query('SELECT * FROM factures WHERE id = $1', [id]);
    
    if (facture.rows.length === 0) {
      return res.status(404).json({ error: 'Facture non trouvée' });
    }
    
    const montantTTC = parseFloat(facture.rows[0].montant_ttc);
    const resteAPayer = montantTTC - montant_paye;
    
    let statut;
    if (resteAPayer <= 0) {
      statut = 'payee';
    } else if (montant_paye > 0) {
      statut = 'partiellement_payee';
    } else {
      const dateEcheance = facture.rows[0].date_echeance;
      if (dateEcheance && new Date(dateEcheance) < new Date()) {
        statut = 'en_retard';
      } else {
        statut = 'en_attente';
      }
    }
    
    const result = await pool.query(`
      UPDATE factures 
      SET montant_paye = $1, reste_a_payer = $2, statut = $3, updated_at = CURRENT_TIMESTAMP
      WHERE id = $4
      RETURNING *
    `, [montant_paye, resteAPayer, statut, id]);
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la mise à jour du statut' });
  }
});

// DELETE supprimer facture
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM factures WHERE id = $1 RETURNING *', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Facture non trouvée' });
    }
    
    res.json({ message: 'Facture supprimée', facture: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la suppression de la facture' });
  }
});

module.exports = router;
