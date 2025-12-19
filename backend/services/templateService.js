const fs = require('fs').promises;
const path = require('path');

class TemplateService {
  constructor() {
    this.templatesPath = path.join(__dirname, '../templates');
    this.cache = new Map();
  }

  /**
   * Charge un template depuis le système de fichiers
   * @param {string} category - Catégorie du template (factures, documents, etc.)
   * @param {string} name - Nom du template
   * @returns {Promise<Object>} Le template chargé
   */
  async loadTemplate(category, name) {
    const cacheKey = `${category}/${name}`;
    
    // Vérifier le cache
    if (this.cache.has(cacheKey)) {
      return this.cache.get(cacheKey);
    }

    try {
      const templatePath = path.join(this.templatesPath, `${name}.json`);
      const templateContent = await fs.readFile(templatePath, 'utf8');
      const template = JSON.parse(templateContent);
      
      // Mettre en cache
      this.cache.set(cacheKey, template);
      
      return template;
    } catch (error) {
      console.error(`Erreur lors du chargement du template ${cacheKey}:`, error);
      return null;
    }
  }

  /**
   * Interpole les variables dans un template
   * @param {Object} template - Le template à interpoler
   * @param {Object} data - Les données pour l'interpolation
   * @returns {Object} Le template interpolé
   */
  interpolate(template, data) {
    const interpolateValue = (value) => {
      if (typeof value === 'string') {
        return value.replace(/\{\{(\w+)\}\}/g, (match, key) => {
          return data[key] !== undefined ? data[key] : match;
        });
      }
      if (typeof value === 'object' && value !== null) {
        if (Array.isArray(value)) {
          return value.map(interpolateValue);
        }
        const result = {};
        for (const [k, v] of Object.entries(value)) {
          result[k] = interpolateValue(v);
        }
        return result;
      }
      return value;
    };

    return interpolateValue(template);
  }

  /**
   * Catégorise les items d'une facture par type
   * @param {Array} items - Les items à catégoriser
   * @returns {Object} Items catégorisés
   */
  categorizeItems(items) {
    const categories = {
      produits: [],
      services: [],
      autres: []
    };

    items.forEach(item => {
      const category = item.type || 'autres';
      if (categories[category]) {
        categories[category].push(item);
      } else {
        categories.autres.push(item);
      }
    });

    return categories;
  }

  /**
   * Applique un style à un élément
   * @param {Object} element - L'élément à styler
   * @param {Object} styles - Les styles à appliquer
   * @returns {Object} L'élément stylé
   */
  applyStyle(element, styles) {
    return {
      ...element,
      style: {
        ...element.style,
        ...styles
      }
    };
  }

  /**
   * Vide le cache des templates
   */
  clearCache() {
    this.cache.clear();
  }
}

module.exports = new TemplateService();
