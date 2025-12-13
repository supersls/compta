const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// GET écritures comptables
router.get('/ecritures', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT e.*, c.numero as compte_numero, c.libelle as compte_libelle
      FROM ecritures_comptables e
      LEFT JOIN plan_comptable c ON e.compte_id = c.id
      ORDER BY e.date_ecriture DESC, e.numero_piece
    `);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des écritures' });
  }
});

// GET plan comptable
router.get('/plan-comptable', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM comptes_pcg ORDER BY numero');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération du plan comptable' });
  }
});

// GET comptes (alias for plan-comptable)
router.get('/comptes', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM comptes_pcg ORDER BY numero');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération du plan comptable' });
  }
});

// GET grand livre
router.get('/grand-livre/:debut/:fin', async (req, res) => {
  try {
    const { debut, fin } = req.params;
    
    const result = await pool.query(`
      SELECT 
        c.numero,
        c.libelle,
        SUM(e.debit) as total_debit,
        SUM(e.credit) as total_credit,
        SUM(e.debit) - SUM(e.credit) as solde
      FROM ecritures_comptables e
      JOIN plan_comptable c ON e.compte_id = c.id
      WHERE e.date_ecriture BETWEEN $1 AND $2
      GROUP BY c.numero, c.libelle
      ORDER BY c.numero
    `, [debut, fin]);
    
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la génération du grand livre' });
  }
});

// GET balance
router.get('/balance/:debut/:fin', async (req, res) => {
  try {
    const { debut, fin } = req.params;
    
    const result = await pool.query(`
      SELECT 
        c.numero,
        c.libelle,
        c.type,
        SUM(e.debit) as total_debit,
        SUM(e.credit) as total_credit,
        SUM(e.debit) - SUM(e.credit) as solde
      FROM plan_comptable c
      LEFT JOIN ecritures_comptables e ON c.id = e.compte_id 
        AND e.date_ecriture BETWEEN $1 AND $2
      GROUP BY c.id, c.numero, c.libelle, c.type
      HAVING SUM(e.debit) > 0 OR SUM(e.credit) > 0
      ORDER BY c.numero
    `, [debut, fin]);
    
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la génération de la balance' });
  }
});

// POST créer écriture comptable
router.post('/ecritures', async (req, res) => {
  try {
    const {
      date_ecriture, numero_piece, journal, compte_id, libelle,
      debit, credit, lettrage, facture_id
    } = req.body;
    
    const result = await pool.query(`
      INSERT INTO ecritures_comptables (
        date_ecriture, numero_piece, journal, compte_id, libelle,
        debit, credit, lettrage, facture_id
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *
    `, [
      date_ecriture, numero_piece, journal, compte_id, libelle,
      debit || 0, credit || 0, lettrage, facture_id
    ]);
    
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la création de l\'écriture' });
  }
});

module.exports = router;
