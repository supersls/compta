const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// GET comptes bancaires
router.get('/comptes', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM comptes_bancaires ORDER BY nom');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des comptes' });
  }
});

// GET transactions
router.get('/transactions', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT t.*, c.nom as compte_nom 
      FROM transactions_bancaires t
      LEFT JOIN comptes_bancaires c ON t.compte_id = c.id
      ORDER BY t.date_transaction DESC
    `);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des transactions' });
  }
});

// GET transactions par compte
router.get('/comptes/:id/transactions', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      'SELECT * FROM transactions_bancaires WHERE compte_id = $1 ORDER BY date_transaction DESC',
      [id]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des transactions' });
  }
});

// POST créer compte bancaire
router.post('/comptes', async (req, res) => {
  try {
    const { nom, banque, numero_compte, iban, solde_initial } = req.body;
    
    const result = await pool.query(`
      INSERT INTO comptes_bancaires (nom, banque, numero_compte, iban, solde_initial, solde_actuel)
      VALUES ($1, $2, $3, $4, $5, $5)
      RETURNING *
    `, [nom, banque, numero_compte, iban, solde_initial || 0]);
    
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la création du compte' });
  }
});

// POST créer transaction
router.post('/transactions', async (req, res) => {
  try {
    const { compte_id, date_transaction, type, montant, categorie, description, reference } = req.body;
    
    const result = await pool.query(`
      INSERT INTO transactions_bancaires (
        compte_id, date_transaction, type, montant, categorie, description, reference
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `, [compte_id, date_transaction, type, montant, categorie, description, reference]);
    
    // Mise à jour du solde du compte
    const montantAjuste = type === 'credit' ? montant : -montant;
    await pool.query(
      'UPDATE comptes_bancaires SET solde_actuel = solde_actuel + $1 WHERE id = $2',
      [montantAjuste, compte_id]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la création de la transaction' });
  }
});

module.exports = router;
