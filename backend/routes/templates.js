const express = require('express');
const router = express.Router();
const templateService = require('../services/templateService');

// GET /api/templates - Liste tous les templates disponibles
router.get('/', async (req, res) => {
  try {
    const templates = {
      factures: ['facture'],
      documents: ['compte_resultat', 'bilan', 'journal', 'grand_livre']
    };
    res.json(templates);
  } catch (error) {
    console.error('Erreur lors de la récupération des templates:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// GET /api/templates/:category/:name - Charger un template spécifique
router.get('/:category/:name', async (req, res) => {
  try {
    const { category, name } = req.params;
    const template = await templateService.loadTemplate(category, name);
    
    if (!template) {
      return res.status(404).json({ error: 'Template non trouvé' });
    }
    
    res.json(template);
  } catch (error) {
    console.error('Erreur lors du chargement du template:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;
