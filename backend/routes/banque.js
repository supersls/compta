const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// GET comptes bancaires
router.get('/comptes', async (req, res) => {
  try {
    const { entreprise_id } = req.query;
    
    if (!entreprise_id) {
      return res.status(400).json({ error: 'entreprise_id est requis' });
    }
    
    const result = await pool.query(
      'SELECT * FROM comptes_bancaires WHERE entreprise_id = $1 ORDER BY nom',
      [entreprise_id]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des comptes' });
  }
});

// GET transactions
router.get('/transactions', async (req, res) => {
  try {
    const { entreprise_id } = req.query;
    
    if (!entreprise_id) {
      return res.status(400).json({ error: 'entreprise_id est requis' });
    }
    
    const result = await pool.query(`
      SELECT t.*, c.nom as compte_nom 
      FROM transactions_bancaires t
      LEFT JOIN comptes_bancaires c ON t.compte_bancaire_id = c.id
      WHERE c.entreprise_id = $1
      ORDER BY t.date_transaction DESC
    `, [entreprise_id]);
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
    const { entreprise_id, nom, banque, numero_compte, iban, solde_initial } = req.body;
    
    if (!entreprise_id) {
      return res.status(400).json({ error: 'entreprise_id est requis' });
    }
    
    const result = await pool.query(`
      INSERT INTO comptes_bancaires (entreprise_id, nom, banque, numero_compte, iban, solde_initial, solde_actuel)
      VALUES ($1, $2, $3, $4, $5, $6, $6)
      RETURNING *
    `, [entreprise_id, nom, banque, numero_compte, iban, solde_initial || 0]);
    
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la création du compte' });
  }
});

// POST créer transaction
router.post('/transactions', async (req, res) => {
  try {
    const { compte_bancaire_id, date_transaction, date_valeur, libelle, debit, credit, categorie, notes } = req.body;
    
    // Get current balance
    const compteResult = await pool.query(
      'SELECT solde_actuel FROM comptes_bancaires WHERE id = $1',
      [compte_bancaire_id]
    );
    
    if (compteResult.rows.length === 0) {
      return res.status(404).json({ error: 'Compte bancaire non trouvé' });
    }
    
    const soldeActuel = parseFloat(compteResult.rows[0]?.solde_actuel || 0);
    const nouveauSolde = soldeActuel + parseFloat(credit || 0) - parseFloat(debit || 0);
    
    const result = await pool.query(`
      INSERT INTO transactions_bancaires (
        compte_bancaire_id, date_transaction, date_valeur, libelle, debit, credit, solde, categorie, notes
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *
    `, [compte_bancaire_id, date_transaction, date_valeur, libelle, debit || 0, credit || 0, nouveauSolde, categorie, notes]);
    
    // Mise à jour du solde du compte
    await pool.query(
      'UPDATE comptes_bancaires SET solde_actuel = $1 WHERE id = $2',
      [nouveauSolde, compte_bancaire_id]
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
    const { compte_bancaire_id, date_transaction, date_valeur, libelle, debit, credit, categorie, notes } = req.body;
    
    // Récupérer l'ancienne transaction pour recalculer le solde
    const oldResult = await pool.query(
      'SELECT * FROM transactions_bancaires WHERE id = $1',
      [id]
    );
    
    if (oldResult.rows.length === 0) {
      return res.status(404).json({ error: 'Transaction non trouvée' });
    }
    
    const oldTransaction = oldResult.rows[0];
    
    // Calculer impact ancien et nouveau
    const oldImpact = parseFloat(oldTransaction.credit || 0) - parseFloat(oldTransaction.debit || 0);
    const newImpact = parseFloat(credit || 0) - parseFloat(debit || 0);
    
    // Get current solde
    const compteResult = await pool.query(
      'SELECT solde_actuel FROM comptes_bancaires WHERE id = $1',
      [compte_bancaire_id]
    );
    
    const soldeActuel = parseFloat(compteResult.rows[0]?.solde_actuel || 0);
    const nouveauSolde = soldeActuel - oldImpact + newImpact;
    
    // Mise à jour de la transaction
    const result = await pool.query(`
      UPDATE transactions_bancaires 
      SET compte_bancaire_id = $1, date_transaction = $2, date_valeur = $3, libelle = $4,
          debit = $5, credit = $6, solde = $7, categorie = $8, notes = $9
      WHERE id = $10
      RETURNING *
    `, [compte_bancaire_id, date_transaction, date_valeur, libelle, debit || 0, credit || 0, nouveauSolde, categorie, notes, id]);
    
    // Mise à jour du solde du compte
    await pool.query(
      'UPDATE comptes_bancaires SET solde_actuel = $1 WHERE id = $2',
      [nouveauSolde, compte_bancaire_id]
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
    const impact = parseFloat(transaction.credit || 0) - parseFloat(transaction.debit || 0);
    await pool.query(
      'UPDATE comptes_bancaires SET solde_actuel = solde_actuel - $1 WHERE id = $2',
      [impact, transaction.compte_bancaire_id]
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
      SET rapproche = true
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
        COALESCE(SUM(credit), 0) as total_credits,
        COALESCE(SUM(debit), 0) as total_debits,
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
    const { entreprise_id } = req.query;
    
    if (!entreprise_id) {
      return res.status(400).json({ error: 'entreprise_id est requis' });
    }
    
    const result = await pool.query(`
      SELECT 
        COUNT(DISTINCT cb.id) as nombre_comptes,
        COALESCE(SUM(cb.solde_actuel), 0) as total_soldes,
        COUNT(tb.id) as nombre_transactions,
        COALESCE(SUM(CASE WHEN tb.credit > 0 THEN tb.credit ELSE 0 END), 0) as total_credits,
        COALESCE(SUM(CASE WHEN tb.debit > 0 THEN tb.debit ELSE 0 END), 0) as total_debits
      FROM comptes_bancaires cb
      LEFT JOIN transactions_bancaires tb ON cb.id = tb.compte_bancaire_id
      WHERE cb.entreprise_id = $1
    `, [entreprise_id]);
    
    const stats = result.rows[0];
    res.json({
      nombreComptes: parseInt(stats.nombre_comptes || 0),
      totalSoldes: parseFloat(stats.total_soldes || 0),
      totalTresorerie: parseFloat(stats.total_soldes || 0),
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




