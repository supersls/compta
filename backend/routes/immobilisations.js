const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// GET immobilisations
router.get('/', async (req, res) => {
  try {
    const { entreprise_id } = req.query;
    
    if (!entreprise_id) {
      return res.status(400).json({ error: 'entreprise_id est requis' });
    }
    
    const result = await pool.query(
      'SELECT * FROM immobilisations WHERE entreprise_id = $1 ORDER BY date_acquisition DESC',
      [entreprise_id]
    );
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
      SELECT a.*, i.libelle as immobilisation_nom
      FROM amortissements a
      LEFT JOIN immobilisations i ON a.immobilisation_id = i.id
      ORDER BY a.annee DESC
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
      duree_amortissement, methode_amortissement, taux_amortissement, 
      valeur_residuelle, compte_immobilisation, compte_amortissement, en_service, notes
    } = req.body;
    
    const result = await pool.query(`
      INSERT INTO immobilisations (
        libelle, type, date_acquisition, valeur_acquisition,
        duree_amortissement, methode_amortissement, taux_amortissement,
        valeur_residuelle, compte_immobilisation, compte_amortissement, en_service, notes
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
      RETURNING *
    `, [
      libelle, type, date_acquisition, valeur_acquisition,
      duree_amortissement, methode_amortissement || 'lineaire', taux_amortissement,
      valeur_residuelle || 0, compte_immobilisation, compte_amortissement, en_service !== false, notes
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
    const { immobilisation_id, annee, dotation, montant_amortissement, cumul_amortissements, valeur_nette_comptable, exercice } = req.body;
    
    const result = await pool.query(`
      INSERT INTO amortissements (
        immobilisation_id, annee, exercice, montant_amortissement, 
        cumul_amortissements, valeur_nette_comptable
      ) VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `, [
      immobilisation_id, 
      annee, 
      exercice || annee,
      montant_amortissement || dotation,
      cumul_amortissements,
      valeur_nette_comptable
    ]);
    
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
      duree_amortissement, methode_amortissement, taux_amortissement, 
      valeur_residuelle, compte_immobilisation, compte_amortissement, en_service, notes
    } = req.body;
    
    const result = await pool.query(`
      UPDATE immobilisations 
      SET libelle = $1, type = $2, date_acquisition = $3, 
          valeur_acquisition = $4, duree_amortissement = $5,
          methode_amortissement = $6, taux_amortissement = $7, 
          valeur_residuelle = $8, compte_immobilisation = $9,
          compte_amortissement = $10, en_service = $11, notes = $12
      WHERE id = $13
      RETURNING *
    `, [
      libelle, type, date_acquisition, valeur_acquisition,
      duree_amortissement, methode_amortissement, taux_amortissement, 
      valeur_residuelle, compte_immobilisation, compte_amortissement, en_service, notes, id
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
      SELECT COALESCE(SUM(montant_amortissement), 0) as cumul
      FROM amortissements
      WHERE immobilisation_id = $1 AND annee < $2
    `, [id, annee]);
    
    const cumulPrecedent = parseFloat(previousResult.rows[0].cumul || 0);
    const vncDebut = parseFloat(immo.valeur_acquisition) - cumulPrecedent;
    
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
    const { entreprise_id } = req.query;
    
    if (!entreprise_id) {
      return res.status(400).json({ error: 'entreprise_id est requis' });
    }
    
    const result = await pool.query(`
      SELECT 
        COALESCE(SUM(valeur_acquisition), 0) as total_acquisition,
        COALESCE(SUM(valeur_acquisition - valeur_residuelle), 0) as total_amortissable,
        COUNT(*) as nombre_immobilisations,
        COUNT(CASE WHEN en_service = true THEN 1 END) as actives,
        COUNT(CASE WHEN en_service = false OR date_cession IS NOT NULL THEN 1 END) as cedees
      FROM immobilisations
      WHERE entreprise_id = $1
    `, [entreprise_id]);
    
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
        type as categorie,
        COUNT(*) as nombre,
        COALESCE(SUM(valeur_acquisition), 0) as total_acquisition,
        COALESCE(SUM(valeur_acquisition - valeur_residuelle), 0) as total_vnc
      FROM immobilisations
      WHERE date_cession IS NULL
      GROUP BY type
      ORDER BY total_acquisition DESC
    `);
    
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération par catégorie' });
  }
});

module.exports = router;
