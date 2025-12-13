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
      libelle, type, date_acquisition, valeur_acquisition,
      duree_amortissement, methode_amortissement, taux_amortissement, notes
    } = req.body;
    
    const result = await pool.query(`
      INSERT INTO immobilisations (
        designation, categorie, date_acquisition, valeur_acquisition,
        duree_amortissement, methode_amortissement, taux_amortissement,
        valeur_nette_comptable, notes
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $4, $8)
      RETURNING *
    `, [
      libelle, type, date_acquisition, valeur_acquisition,
      duree_amortissement, methode_amortissement, taux_amortissement, notes
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

// PUT modifier immobilisation
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const {
      libelle, type, date_acquisition, valeur_acquisition,
      duree_amortissement, methode_amortissement, taux_amortissement, notes
    } = req.body;
    
    const result = await pool.query(`
      UPDATE immobilisations 
      SET designation = $1, categorie = $2, date_acquisition = $3, 
          valeur_acquisition = $4, duree_amortissement = $5,
          methode_amortissement = $6, taux_amortissement = $7, notes = $8
      WHERE id = $9
      RETURNING *
    `, [
      libelle, type, date_acquisition, valeur_acquisition,
      duree_amortissement, methode_amortissement, taux_amortissement, notes, id
    ]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Immobilisation non trouvée' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la modification de l\'immobilisation' });
  }
});

// DELETE supprimer immobilisation
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Supprimer d'abord les amortissements liés
    await pool.query('DELETE FROM amortissements WHERE immobilisation_id = $1', [id]);
    
    const result = await pool.query(
      'DELETE FROM immobilisations WHERE id = $1 RETURNING *',
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Immobilisation non trouvée' });
    }
    
    res.json({ message: 'Immobilisation supprimée avec succès' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la suppression de l\'immobilisation' });
  }
});

// POST céder immobilisation
router.post('/:id/cession', async (req, res) => {
  try {
    const { id } = req.params;
    const { date_cession, prix_cession } = req.body;
    
    const result = await pool.query(`
      UPDATE immobilisations 
      SET date_cession = $1, prix_cession = $2
      WHERE id = $3
      RETURNING *
    `, [date_cession, prix_cession || null, id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Immobilisation non trouvée' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la cession de l\'immobilisation' });
  }
});

// GET amortissements d'une immobilisation
router.get('/:id/amortissements', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(`
      SELECT * FROM amortissements
      WHERE immobilisation_id = $1
      ORDER BY annee ASC
    `, [id]);
    
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des amortissements' });
  }
});

// GET calcul amortissement pour une année
router.get('/:id/amortissement/:annee', async (req, res) => {
  try {
    const { id, annee } = req.params;
    
    const immoResult = await pool.query(
      'SELECT * FROM immobilisations WHERE id = $1',
      [id]
    );
    
    if (immoResult.rows.length === 0) {
      return res.status(404).json({ error: 'Immobilisation non trouvée' });
    }
    
    const immo = immoResult.rows[0];
    const anneeAcquisition = new Date(immo.date_acquisition).getFullYear();
    const anneeIndex = parseInt(annee) - anneeAcquisition + 1;
    
    if (anneeIndex < 1 || anneeIndex > immo.duree_amortissement) {
      return res.status(400).json({ error: 'Année hors de la période d\'amortissement' });
    }
    
    // Récupérer les amortissements précédents
    const previousResult = await pool.query(`
      SELECT SUM(montant) as cumul
      FROM amortissements
      WHERE immobilisation_id = $1 AND annee < $2
    `, [id, annee]);
    
    const cumulPrecedent = parseFloat(previousResult.rows[0].cumul || 0);
    const vncDebut = immo.valeur_acquisition - cumulPrecedent;
    
    let dotation;
    if (immo.methode_amortissement === 'lineaire') {
      dotation = immo.valeur_acquisition / immo.duree_amortissement;
      
      // Prorata temporis première année
      if (anneeIndex === 1) {
        const moisAcquisition = new Date(immo.date_acquisition).getMonth() + 1;
        if (moisAcquisition !== 1) {
          const moisRestants = 13 - moisAcquisition;
          dotation = (dotation * moisRestants) / 12;
        }
      }
    } else {
      // Dégressif
      const taux = immo.taux_amortissement || (100 / immo.duree_amortissement * 2.25);
      dotation = vncDebut * (taux / 100);
      
      // Prorata temporis première année
      if (anneeIndex === 1) {
        const moisAcquisition = new Date(immo.date_acquisition).getMonth() + 1;
        if (moisAcquisition !== 1) {
          const moisRestants = 13 - moisAcquisition;
          dotation = (dotation * moisRestants) / 12;
        }
      }
      
      // Passage au linéaire si plus avantageux
      const dotationLineaire = vncDebut / (immo.duree_amortissement - anneeIndex + 1);
      if (dotationLineaire > dotation) {
        dotation = dotationLineaire;
      }
    }
    
    const vncFin = Math.max(0, vncDebut - dotation);
    
    res.json({
      immobilisation_id: parseInt(id),
      annee: parseInt(annee),
      montant: dotation,
      valeur_nette_comptable: vncFin
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors du calcul de l\'amortissement' });
  }
});

// GET statistiques
router.get('/statistiques', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        COALESCE(SUM(valeur_acquisition), 0) as total_acquisition,
        COALESCE(SUM(valeur_acquisition - valeur_residuelle), 0) as total_amortissable,
        COUNT(*) as nombre_immobilisations,
        COUNT(CASE WHEN en_service = true THEN 1 END) as actives,
        COUNT(CASE WHEN en_service = false OR date_cession IS NOT NULL THEN 1 END) as cedees
      FROM immobilisations
    `);
    
    const stats = result.rows[0];
    res.json({
      totalAcquisition: parseFloat(stats.total_acquisition),
      totalAmortissable: parseFloat(stats.total_amortissable),
      nombreImmobilisations: parseInt(stats.nombre_immobilisations),
      actives: parseInt(stats.actives),
      cedees: parseInt(stats.cedees)
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des statistiques' });
  }
});

// GET par catégorie
router.get('/par-categorie', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        categorie,
        COUNT(*) as nombre,
        SUM(valeur_acquisition) as total_acquisition,
        SUM(valeur_nette_comptable) as total_vnc
      FROM immobilisations
      WHERE date_cession IS NULL
      GROUP BY categorie
      ORDER BY total_acquisition DESC
    `);
    
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération par catégorie' });
  }
});

module.exports = router;
