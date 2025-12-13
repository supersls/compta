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
      LEFT JOIN comptes_bancaires c ON t.compte_bancaire_id = c.id
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
      'SELECT * FROM transactions_bancaires WHERE compte_bancaire_id = $1 ORDER BY date_transaction DESC',
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
    const { compte_bancaire_id, date_transaction, type, montant, categorie, description, reference } = req.body;
    
    const result = await pool.query(`
      INSERT INTO transactions_bancaires (
        compte_bancaire_id, date_transaction, type, montant, categorie, description, reference
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `, [compte_bancaire_id, date_transaction, type, montant, categorie, description, reference]);
    
    // Mise à jour du solde du compte
    const montantAjuste = type === 'credit' ? montant : -montant;
    await pool.query(
      'UPDATE comptes_bancaires SET solde_actuel = solde_actuel + $1 WHERE id = $2',
      [montantAjuste, compte_bancaire_id]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la création de la transaction' });
  }
});

// PUT modifier compte
router.put('/comptes/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { nom, banque, numero_compte, iban, actif } = req.body;
    
    const result = await pool.query(`
      UPDATE comptes_bancaires 
      SET nom = $1, banque = $2, numero_compte = $3, iban = $4, actif = $5
      WHERE id = $6
      RETURNING *
    `, [nom, banque, numero_compte, iban, actif, id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Compte non trouvé' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la modification du compte' });
  }
});

// DELETE supprimer compte
router.delete('/comptes/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Supprimer d'abord les transactions
    await pool.query('DELETE FROM transactions_bancaires WHERE compte_bancaire_id = $1', [id]);
    
    const result = await pool.query(
      'DELETE FROM comptes_bancaires WHERE id = $1 RETURNING *',
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Compte non trouvé' });
    }
    
    res.json({ message: 'Compte supprimé avec succès' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la suppression du compte' });
  }
});

// PUT modifier transaction
router.put('/transactions/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { compte_bancaire_id, date_transaction, type, montant, categorie, description, reference } = req.body;
    
    // Récupérer l'ancienne transaction pour recalculer le solde
    const oldResult = await pool.query(
      'SELECT * FROM transactions_bancaires WHERE id = $1',
      [id]
    );
    
    if (oldResult.rows.length === 0) {
      return res.status(404).json({ error: 'Transaction non trouvée' });
    }
    
    const oldTransaction = oldResult.rows[0];
    
    // Mise à jour de la transaction
    const result = await pool.query(`
      UPDATE transactions_bancaires 
      SET compte_bancaire_id = $1, date_transaction = $2, type = $3, montant = $4,
          categorie = $5, description = $6, reference = $7
      WHERE id = $8
      RETURNING *
    `, [compte_bancaire_id, date_transaction, type, montant, categorie, description, reference, id]);
    
    // Annuler l'ancien impact sur le solde
    const oldMontantAjuste = oldTransaction.type === 'credit' ? -oldTransaction.montant : oldTransaction.montant;
    // Appliquer le nouveau impact
    const newMontantAjuste = type === 'credit' ? montant : -montant;
    
    await pool.query(
      'UPDATE comptes_bancaires SET solde_actuel = solde_actuel + $1 + $2 WHERE id = $3',
      [oldMontantAjuste, newMontantAjuste, compte_bancaire_id]
    );
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la modification de la transaction' });
  }
});

// DELETE supprimer transaction
router.delete('/transactions/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Récupérer la transaction pour recalculer le solde
    const transactionResult = await pool.query(
      'SELECT * FROM transactions_bancaires WHERE id = $1',
      [id]
    );
    
    if (transactionResult.rows.length === 0) {
      return res.status(404).json({ error: 'Transaction non trouvée' });
    }
    
    const transaction = transactionResult.rows[0];
    
    // Supprimer la transaction
    await pool.query('DELETE FROM transactions_bancaires WHERE id = $1', [id]);
    
    // Annuler l'impact sur le solde
    const montantAjuste = transaction.type === 'credit' ? -transaction.montant : transaction.montant;
    await pool.query(
      'UPDATE comptes_bancaires SET solde_actuel = solde_actuel + $1 WHERE id = $2',
      [montantAjuste, transaction.compte_bancaire_id]
    );
    
    res.json({ message: 'Transaction supprimée avec succès' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la suppression de la transaction' });
  }
});

// PATCH rapprocher transaction
router.patch('/transactions/:id/rapprocher', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(`
      UPDATE transactions_bancaires 
      SET rapproche = true, date_rapprochement = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Transaction non trouvée' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors du rapprochement' });
  }
});

// GET statistiques globales
router.get('/statistiques', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        SUM(solde_actuel) as solde_total,
        COUNT(*) as nombre_comptes,
        (SELECT COUNT(*) FROM transactions_bancaires) as nombre_transactions
      FROM comptes_bancaires
    `);
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des statistiques' });
  }
});

// GET statistiques par compte
router.get('/comptes/:id/statistiques', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(`
      SELECT 
        SUM(CASE WHEN type = 'credit' THEN montant ELSE 0 END) as total_credits,
        SUM(CASE WHEN type = 'debit' THEN montant ELSE 0 END) as total_debits,
        COUNT(*) as nombre_transactions,
        COUNT(CASE WHEN rapproche = true THEN 1 END) as nombre_rapprochees
      FROM transactions_bancaires
      WHERE compte_bancaire_id = $1
    `, [id]);
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des statistiques' });
  }
});

// GET transactions non rapprochées
router.get('/comptes/:id/non-rapprochees', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(
      'SELECT * FROM transactions_bancaires WHERE compte_bancaire_id = $1 AND rapproche = false ORDER BY date_transaction DESC',
      [id]
    );
    
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des transactions' });
  }
});

// GET statistiques banque
router.get('/statistiques', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        COUNT(DISTINCT cb.id) as nombre_comptes,
        COALESCE(SUM(cb.solde_actuel), 0) as total_soldes,
        COUNT(tb.id) as nombre_transactions,
        COALESCE(SUM(CASE WHEN tb.credit > 0 THEN tb.credit ELSE 0 END), 0) as total_credits,
        COALESCE(SUM(CASE WHEN tb.debit > 0 THEN tb.debit ELSE 0 END), 0) as total_debits
      FROM comptes_bancaires cb
      LEFT JOIN transactions_bancaires tb ON cb.id = tb.compte_bancaire_id
    `);
    
    const stats = result.rows[0];
    res.json({
      nombreComptes: parseInt(stats.nombre_comptes || 0),
      totalSoldes: parseFloat(stats.total_soldes || 0),
      nombreTransactions: parseInt(stats.nombre_transactions || 0),
      totalCredits: parseFloat(stats.total_credits || 0),
      totalDebits: parseFloat(stats.total_debits || 0)
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors du calcul des statistiques' });
  }
});

module.exports = router;



