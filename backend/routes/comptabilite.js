const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// GET écritures comptables
router.get('/ecritures', async (req, res) => {
  try {
    const { entreprise_id } = req.query;
    
    let query = `
      SELECT e.*, c.numero as compte_numero, c.libelle as compte_libelle
      FROM ecritures_comptables e
      LEFT JOIN plan_comptable c ON e.compte_id = c.id
    `;
    const params = [];
    
    if (entreprise_id) {
      query += ' WHERE e.entreprise_id = $1';
      params.push(entreprise_id);
    }
    
    query += ' ORDER BY e.date_ecriture DESC, e.numero_piece';
    
    const result = await pool.query(query, params);
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

// GET journaux
router.get('/journaux', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM journaux WHERE actif = true ORDER BY code');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des journaux' });
  }
});

// GET types d'immobilisation
router.get('/types-immobilisation', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM types_immobilisation WHERE actif = true ORDER BY nom');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des types d\'immobilisation' });
  }
});

// POST créer un type d'immobilisation
router.post('/types-immobilisation', async (req, res) => {
  try {
    const { code, nom, description, duree_amortissement_defaut, compte_immobilisation_defaut, compte_amortissement_defaut } = req.body;
    
    if (!code || !nom) {
      return res.status(400).json({ 
        error: 'Les champs code et nom sont obligatoires' 
      });
    }
    
    const result = await pool.query(
      `INSERT INTO types_immobilisation (code, nom, description, duree_amortissement_defaut, compte_immobilisation_defaut, compte_amortissement_defaut, actif) 
       VALUES ($1, $2, $3, $4, $5, $6, true) 
       RETURNING *`,
      [code, nom, description, duree_amortissement_defaut, compte_immobilisation_defaut, compte_amortissement_defaut]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    if (err.code === '23505') {
      res.status(409).json({ error: 'Ce code de type existe déjà' });
    } else {
      res.status(500).json({ error: 'Erreur lors de la création du type d\'immobilisation' });
    }
  }
});

// PUT mettre à jour un type d'immobilisation
router.put('/types-immobilisation/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { code, nom, description, duree_amortissement_defaut, compte_immobilisation_defaut, compte_amortissement_defaut, actif } = req.body;
    
    const result = await pool.query(
      `UPDATE types_immobilisation 
       SET code = $1, nom = $2, description = $3, duree_amortissement_defaut = $4, 
           compte_immobilisation_defaut = $5, compte_amortissement_defaut = $6, actif = $7
       WHERE id = $8 
       RETURNING *`,
      [code, nom, description, duree_amortissement_defaut, compte_immobilisation_defaut, compte_amortissement_defaut, actif, id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Type d\'immobilisation non trouvé' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la mise à jour du type d\'immobilisation' });
  }
});

// DELETE supprimer un type d'immobilisation
router.delete('/types-immobilisation/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(
      'DELETE FROM types_immobilisation WHERE id = $1 RETURNING *',
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Type d\'immobilisation non trouvé' });
    }
    
    res.json({ message: 'Type d\'immobilisation supprimé avec succès' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la suppression du type d\'immobilisation' });
  }
});

// POST créer un compte au plan comptable
router.post('/plan-comptable', async (req, res) => {
  try {
    const { numero, libelle, classe, type } = req.body;
    
    if (!numero || !libelle || !classe || !type) {
      return res.status(400).json({ 
        error: 'Les champs numero, libelle, classe et type sont obligatoires' 
      });
    }
    
    const result = await pool.query(
      `INSERT INTO comptes_pcg (numero, libelle, classe, type) 
       VALUES ($1, $2, $3, $4) 
       RETURNING *`,
      [numero, libelle, classe, type]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    if (err.code === '23505') { // Duplicate key
      res.status(409).json({ error: 'Ce numéro de compte existe déjà' });
    } else {
      res.status(500).json({ error: 'Erreur lors de la création du compte' });
    }
  }
});

// PUT mettre à jour un compte au plan comptable
router.put('/plan-comptable/:numero', async (req, res) => {
  try {
    const { numero } = req.params;
    const { libelle, classe, type } = req.body;
    
    const result = await pool.query(
      `UPDATE comptes_pcg 
       SET libelle = $1, classe = $2, type = $3
       WHERE numero = $4
       RETURNING *`,
      [libelle, classe, type, numero]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Compte non trouvé' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la mise à jour du compte' });
  }
});

// DELETE supprimer un compte au plan comptable
router.delete('/plan-comptable/:numero', async (req, res) => {
  try {
    const { numero } = req.params;
    
    const result = await pool.query(
      'DELETE FROM comptes_pcg WHERE numero = $1 RETURNING *',
      [numero]
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
      entreprise_id, date_ecriture, numero_piece, journal, compte, libelle,
      debit, credit, lettrage, reference_externe, type_reference, validee
    } = req.body;
    
    // Validation des champs obligatoires
    if (!entreprise_id || !numero_piece || !date_ecriture || !journal || !compte || !libelle) {
      return res.status(400).json({ 
        error: 'Les champs entreprise_id, numero_piece, date_ecriture, journal, compte et libelle sont obligatoires' 
      });
    }

    // Vérifier que débit OU crédit est rempli (pas les deux)
    const debitValue = parseFloat(debit) || 0;
    const creditValue = parseFloat(credit) || 0;

    if ((debitValue === 0 && creditValue === 0) || (debitValue > 0 && creditValue > 0)) {
      return res.status(400).json({ 
        error: 'Vous devez remplir soit le débit, soit le crédit (mais pas les deux)' 
      });
    }
    
    const result = await pool.query(`
      INSERT INTO ecritures_comptables (
        entreprise_id, date_ecriture, numero_piece, journal, compte, libelle,
        debit, credit, lettrage, reference_externe, type_reference, validee
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
      RETURNING *
    `, [
      entreprise_id, date_ecriture, numero_piece, journal, compte, libelle,
      debitValue, creditValue, lettrage || null, reference_externe || null, 
      type_reference || null, validee !== undefined ? validee : true
    ]);
    
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la création de l\'écriture', details: err.message });
  }
});

module.exports = router;
