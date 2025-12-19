const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const pdfGenerator = require('../services/pdfGenerator');

// Journal Comptable
router.get('/journal', async (req, res) => {
  try {
    const { debut, fin, journal, entreprise_id } = req.query;
    
    let query = `
      SELECT * FROM ecritures_comptables 
      WHERE date_ecriture BETWEEN $1 AND $2
    `;
    const params = [debut, fin];
    
    if (entreprise_id) {
      query += ` AND entreprise_id = $${params.length + 1}`;
      params.push(entreprise_id);
    }
    
    if (journal) {
      query += ` AND journal = $${params.length + 1}`;
      params.push(journal);
    }
    
    query += ` ORDER BY date_ecriture, id`;
    
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération du journal' });
  }
});

// Grand Livre
router.get('/grand-livre', async (req, res) => {
  try {
    const { debut, fin, compte, entreprise_id } = req.query;
    
    let whereClause = 'WHERE date_ecriture BETWEEN $1 AND $2';
    const params = [debut, fin];
    
    if (entreprise_id) {
      whereClause += ` AND entreprise_id = $${params.length + 1}`;
      params.push(entreprise_id);
    }
    
    if (compte) {
      whereClause += ` AND compte = $${params.length + 1}`;
      params.push(compte);
    }
    
    // Récupérer tous les comptes avec leurs écritures
    const query = `
      SELECT 
        compte as numero_compte,
        MAX(COALESCE(compte, '')) as nom_compte,
        0 as solde_initial,
        SUM(debit) as total_debit,
        SUM(credit) as total_credit,
        SUM(debit - credit) as solde_final,
        json_agg(
          json_build_object(
            'id', id,
            'date_ecriture', date_ecriture,
            'libelle', libelle,
            'debit', debit,
            'credit', credit,
            'journal', journal
          ) ORDER BY date_ecriture
        ) as ecritures
      FROM ecritures_comptables
      ${whereClause}
      GROUP BY compte
      ORDER BY compte
    `;
    
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération du grand livre' });
  }
});

// Bilan Comptable
router.get('/bilan', async (req, res) => {
  try {
    const { date, entreprise_id } = req.query;
    
    if (!date) {
      return res.status(400).json({ error: 'La date est requise' });
    }
    
    let whereClause = 'WHERE date_ecriture <= $1';
    const params = [date];
    
    if (entreprise_id) {
      whereClause += ` AND entreprise_id = $${params.length + 1}`;
      params.push(entreprise_id);
    }
    
    // Récupérer les soldes des comptes de bilan (comptes 1-5)
    const query = `
      SELECT 
        CASE 
          WHEN compte LIKE '1%' THEN 'Capitaux propres'
          WHEN compte LIKE '2%' THEN 'Immobilisations'
          WHEN compte LIKE '3%' THEN 'Stocks'
          WHEN compte LIKE '4%' AND compte < '43' THEN 'Créances clients'
          WHEN compte LIKE '4%' AND compte >= '43' THEN 'Dettes fournisseurs'
          WHEN compte LIKE '5%' THEN 'Trésorerie'
          ELSE 'Autres'
        END as categorie,
        CASE
          WHEN compte LIKE '2%' OR compte LIKE '3%' OR (compte LIKE '4%' AND compte < '43') OR compte LIKE '5%' THEN 'actif'
          ELSE 'passif'
        END as type,
        SUM(debit - credit) as solde
      FROM ecritures_comptables
      ${whereClause}
      AND compte NOT LIKE '6%' 
      AND compte NOT LIKE '7%'
      GROUP BY categorie, type
      HAVING SUM(debit - credit) != 0
    `;
    
    const result = await pool.query(query, params);
    
    const actif = {};
    const passif = {};
    let totalActif = 0;
    let totalPassif = 0;
    
    result.rows.forEach(row => {
      const solde = parseFloat(row.solde);
      const montant = Math.abs(solde);
      
      if (row.type === 'actif') {
        actif[row.categorie] = solde > 0 ? montant : -montant;
        totalActif += solde > 0 ? montant : 0;
      } else {
        passif[row.categorie] = solde < 0 ? montant : -montant;
        totalPassif += solde < 0 ? montant : 0;
      }
    });
    
    // Calculer le résultat de l'exercice (produits - charges)
    const resultatQuery = `
      SELECT 
        COALESCE(SUM(CASE WHEN compte LIKE '7%' THEN credit - debit ELSE 0 END), 0) as produits,
        COALESCE(SUM(CASE WHEN compte LIKE '6%' THEN debit - credit ELSE 0 END), 0) as charges
      FROM ecritures_comptables
      ${whereClause}
    `;
    
    const resultatResult = await pool.query(resultatQuery, params);
    const produits = parseFloat(resultatResult.rows[0].produits) || 0;
    const charges = parseFloat(resultatResult.rows[0].charges) || 0;
    const resultat = produits - charges;
    
    // Ajouter le résultat au passif si bénéfice, à l'actif si perte
    if (resultat > 0) {
      passif['Résultat de l\'exercice'] = resultat;
      totalPassif += resultat;
    } else if (resultat < 0) {
      actif['Perte de l\'exercice'] = Math.abs(resultat);
      totalActif += Math.abs(resultat);
    }
    
    res.json({
      date_arrete: date,
      actif,
      passif,
      total_actif: totalActif,
      total_passif: totalPassif,
      resultat,
    });
  } catch (err) {
    console.error('Erreur bilan:', err);
    res.status(500).json({ error: 'Erreur lors de la génération du bilan', details: err.message });
  }
});

// Compte de Résultat
router.get('/compte-resultat', async (req, res) => {
  try {
    const { debut, fin, dateDebut, dateFin, entreprise_id } = req.query;
    const periodeDebut = debut || dateDebut;
    const periodeFin = fin || dateFin;
    
    let whereClause = 'WHERE date_ecriture BETWEEN $1 AND $2';
    const params = [periodeDebut, periodeFin];
    
    if (entreprise_id) {
      whereClause += ` AND entreprise_id = $${params.length + 1}`;
      params.push(entreprise_id);
    }
    
    const query = `
      SELECT 
        CASE 
          WHEN compte LIKE '6%' THEN 
            CASE 
              WHEN compte LIKE '60%' THEN 'Achats'
              WHEN compte LIKE '61%' THEN 'Services extérieurs'
              WHEN compte LIKE '62%' THEN 'Autres services'
              WHEN compte LIKE '63%' THEN 'Impôts et taxes'
              WHEN compte LIKE '64%' THEN 'Charges de personnel'
              WHEN compte LIKE '65%' THEN 'Autres charges'
              WHEN compte LIKE '66%' THEN 'Charges financières'
              WHEN compte LIKE '67%' THEN 'Charges exceptionnelles'
              WHEN compte LIKE '68%' THEN 'Dotations aux amortissements'
              ELSE 'Autres charges'
            END
          WHEN compte LIKE '7%' THEN 
            CASE 
              WHEN compte LIKE '70%' THEN 'Ventes de marchandises'
              WHEN compte LIKE '71%' THEN 'Production vendue'
              WHEN compte LIKE '72%' THEN 'Production stockée'
              WHEN compte LIKE '74%' THEN 'Subventions exploitation'
              WHEN compte LIKE '75%' THEN 'Autres produits'
              WHEN compte LIKE '76%' THEN 'Produits financiers'
              WHEN compte LIKE '77%' THEN 'Produits exceptionnels'
              WHEN compte LIKE '78%' THEN 'Reprises sur amortissements'
              ELSE 'Autres produits'
            END
          ELSE 'Autres'
        END as categorie,
        CASE
          WHEN compte LIKE '6%' THEN 'charges'
          WHEN compte LIKE '7%' THEN 'produits'
          ELSE 'autre'
        END as type,
        SUM(CASE WHEN compte LIKE '6%' THEN debit ELSE credit END) as montant
      FROM ecritures_comptables
      WHERE date_ecriture BETWEEN $1 AND $2
        AND (compte LIKE '6%' OR compte LIKE '7%')
      GROUP BY categorie, type
      HAVING SUM(CASE WHEN compte LIKE '6%' THEN debit ELSE credit END) > 0
    `;
    
    const result = await pool.query(query, [periodeDebut, periodeFin]);
    
    const charges = {};
    const produits = {};
    let totalCharges = 0;
    let totalProduits = 0;
    
    result.rows.forEach(row => {
      if (row.type === 'charges') {
        charges[row.categorie] = row.montant;
        totalCharges += row.montant;
      } else if (row.type === 'produits') {
        produits[row.categorie] = row.montant;
        totalProduits += row.montant;
      }
    });
    
    const resultatNet = totalProduits - totalCharges;
    
    res.json({
      periode_debut: periodeDebut,
      periode_fin: periodeFin,
      charges,
      produits,
      total_charges: totalCharges,
      total_produits: totalProduits,
      resultat_net: resultatNet,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la génération du compte de résultat' });
  }
});

// Balance des comptes
router.get('/balance', async (req, res) => {
  try {
    const { debut, fin, entreprise_id } = req.query;
    
    let whereClause = 'WHERE date_ecriture BETWEEN $1 AND $2';
    const params = [debut, fin];
    
    if (entreprise_id) {
      whereClause += ` AND entreprise_id = $${params.length + 1}`;
      params.push(entreprise_id);
    }
    
    const query = `
      SELECT 
        compte,
        SUM(debit) as total_debit,
        SUM(credit) as total_credit,
        SUM(debit - credit) as solde
      FROM ecritures_comptables
      ${whereClause}
      GROUP BY compte
      HAVING SUM(debit) != 0 OR SUM(credit) != 0
      ORDER BY compte
    `;
    
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération de la balance' });
  }
});

// Export PDF - Fonction réutilisable pour tous les types de documents
router.get('/export/pdf/:type', async (req, res) => {
  try {
    const { type } = req.params;
    let doc;
    let filename;

    switch (type) {
      case 'compte-resultat': {
        const { debut, fin, dateDebut, dateFin } = req.query;
        const periodeDebut = debut || dateDebut;
        const periodeFin = fin || dateFin;

        // Récupérer les données
        const query = `
          SELECT 
            CASE 
              WHEN compte LIKE '6%' THEN 
                CASE 
                  WHEN compte LIKE '60%' THEN 'Achats'
                  WHEN compte LIKE '61%' THEN 'Services extérieurs'
                  WHEN compte LIKE '62%' THEN 'Autres services'
                  WHEN compte LIKE '63%' THEN 'Impôts et taxes'
                  WHEN compte LIKE '64%' THEN 'Charges de personnel'
                  WHEN compte LIKE '65%' THEN 'Autres charges'
                  WHEN compte LIKE '66%' THEN 'Charges financières'
                  WHEN compte LIKE '67%' THEN 'Charges exceptionnelles'
                  WHEN compte LIKE '68%' THEN 'Dotations aux amortissements'
                  ELSE 'Autres charges'
                END
              WHEN compte LIKE '7%' THEN 
                CASE 
                  WHEN compte LIKE '70%' THEN 'Ventes de marchandises'
                  WHEN compte LIKE '71%' THEN 'Production vendue'
                  WHEN compte LIKE '72%' THEN 'Production stockée'
                  WHEN compte LIKE '74%' THEN 'Subventions exploitation'
                  WHEN compte LIKE '75%' THEN 'Autres produits'
                  WHEN compte LIKE '76%' THEN 'Produits financiers'
                  WHEN compte LIKE '77%' THEN 'Produits exceptionnels'
                  WHEN compte LIKE '78%' THEN 'Reprises sur amortissements'
                  ELSE 'Autres produits'
                END
              ELSE 'Autres'
            END as categorie,
            CASE
              WHEN compte LIKE '6%' THEN 'charges'
              WHEN compte LIKE '7%' THEN 'produits'
              ELSE 'autre'
            END as type,
            SUM(CASE WHEN compte LIKE '6%' THEN debit ELSE credit END) as montant
          FROM ecritures_comptables
          WHERE date_ecriture BETWEEN $1 AND $2
            AND (compte LIKE '6%' OR compte LIKE '7%')
          GROUP BY categorie, type
          HAVING SUM(CASE WHEN compte LIKE '6%' THEN debit ELSE credit END) > 0
        `;

        const result = await pool.query(query, [periodeDebut, periodeFin]);

        const charges = {};
        const produits = {};
        let totalCharges = 0;
        let totalProduits = 0;

        result.rows.forEach(row => {
          if (row.type === 'charges') {
            charges[row.categorie] = row.montant;
            totalCharges += row.montant;
          } else if (row.type === 'produits') {
            produits[row.categorie] = row.montant;
            totalProduits += row.montant;
          }
        });

        const data = {
          periode_debut: periodeDebut,
          periode_fin: periodeFin,
          charges,
          produits,
          total_charges: totalCharges,
          total_produits: totalProduits,
          resultat_net: totalProduits - totalCharges,
        };

        doc = pdfGenerator.generateCompteResultat(data);
        filename = `compte-resultat-${periodeDebut}-${periodeFin}.pdf`;
        break;
      }

      case 'journal': {
        const { debut, fin, journal } = req.query;
        let query = `
          SELECT * FROM ecritures_comptables 
          WHERE date_ecriture BETWEEN $1 AND $2
        `;
        const params = [debut, fin];

        if (journal) {
          query += ` AND journal = $3`;
          params.push(journal);
        }

        query += ` ORDER BY date_ecriture, id`;

        const result = await pool.query(query, params);
        doc = pdfGenerator.generateJournal(result.rows, { debut, fin });
        filename = `journal-comptable-${debut}-${fin}.pdf`;
        break;
      }

      case 'grand-livre': {
        const { debut, fin, compte } = req.query;
        let whereClause = 'WHERE date_ecriture BETWEEN $1 AND $2';
        const params = [debut, fin];

        if (compte) {
          whereClause += ' AND compte = $3';
          params.push(compte);
        }

        const query = `
          SELECT 
            compte as numero_compte,
            MAX(COALESCE(compte, '')) as nom_compte,
            0 as solde_initial,
            SUM(debit) as total_debit,
            SUM(credit) as total_credit,
            SUM(debit - credit) as solde_final,
            json_agg(
              json_build_object(
                'id', id,
                'date_ecriture', date_ecriture,
                'libelle', libelle,
                'debit', debit,
                'credit', credit,
                'journal', journal
              ) ORDER BY date_ecriture
            ) as ecritures
          FROM ecritures_comptables
          ${whereClause}
          GROUP BY compte
          ORDER BY compte
        `;

        const result = await pool.query(query, params);
        doc = pdfGenerator.generateGrandLivre(result.rows, { debut, fin });
        filename = `grand-livre-${debut}-${fin}.pdf`;
        break;
      }

      case 'bilan': {
        const { date } = req.query;
        const query = `
          SELECT 
            CASE 
              WHEN compte LIKE '1%' THEN 'Capitaux propres'
              WHEN compte LIKE '2%' THEN 'Immobilisations'
              WHEN compte LIKE '3%' THEN 'Stocks'
              WHEN compte LIKE '4%' AND compte < '43' THEN 'Créances clients'
              WHEN compte LIKE '4%' AND compte >= '43' THEN 'Dettes fournisseurs'
              WHEN compte LIKE '5%' THEN 'Trésorerie'
              ELSE 'Autres'
            END as categorie,
            CASE
              WHEN compte LIKE '2%' OR compte LIKE '3%' OR (compte LIKE '4%' AND compte < '43') OR compte LIKE '5%' THEN 'actif'
              ELSE 'passif'
            END as type,
            SUM(debit - credit) as solde
          FROM ecritures_comptables
          WHERE date_ecriture <= $1
          GROUP BY categorie, type
          HAVING SUM(debit - credit) != 0
        `;

        const result = await pool.query(query, [date]);

        const actif = {};
        const passif = {};
        let totalActif = 0;
        let totalPassif = 0;

        result.rows.forEach(row => {
          const montant = Math.abs(row.solde);
          if (row.type === 'actif') {
            actif[row.categorie] = montant;
            totalActif += montant;
          } else {
            passif[row.categorie] = montant;
            totalPassif += montant;
          }
        });

        const data = {
          date_arrete: date,
          actif,
          passif,
          total_actif: totalActif,
          total_passif: totalPassif,
          resultat: totalActif - totalPassif,
        };

        doc = pdfGenerator.generateBilan(data);
        filename = `bilan-comptable-${date}.pdf`;
        break;
      }

      default:
        return res.status(400).json({ error: 'Type de document non supporté' });
    }

    // Configuration des headers pour le téléchargement
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

    // Envoi du PDF
    doc.pipe(res);
    doc.end();

  } catch (err) {
    console.error('Erreur export PDF:', err);
    res.status(500).json({ error: 'Erreur lors de la génération du PDF' });
  }
});

// Export Excel (placeholder - nécessite une bibliothèque Excel)
router.get('/export/excel/:type', async (req, res) => {
  const { type } = req.params;
  res.json({ 
    message: `Export Excel ${type} - Fonctionnalité à implémenter avec ExcelJS ou similaire`,
    url: `/api/documents/${type}?${new URLSearchParams(req.query)}`
  });
});

module.exports = router;
