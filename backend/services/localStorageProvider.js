const fs = require('fs').promises;
const fsSync = require('fs');
const path = require('path');

/**
 * Provider de stockage local pour les justificatifs
 */
class LocalStorageProvider {
  constructor(config) {
    this.storagePath = config.storagePath;
    this.archivePath = path.join(this.storagePath, 'archives');
    this.ensureDirectories();
  }

  /**
   * S'assure que les répertoires de stockage existent
   */
  async ensureDirectories() {
    try {
      await fs.mkdir(this.storagePath, { recursive: true });
      await fs.mkdir(this.archivePath, { recursive: true });
    } catch (error) {
      console.error('Erreur lors de la création des répertoires:', error);
    }
  }

  /**
   * Upload un fichier
   * @param {Buffer} file - Contenu du fichier
   * @param {Object} metadata - Métadonnées
   * @returns {Promise<Object>}
   */
  async upload(file, metadata) {
    await this.ensureDirectories();
    
    const filePath = path.join(this.storagePath, metadata.fileName);
    
    // Créer des sous-dossiers par année/mois pour une meilleure organisation
    const date = new Date();
    const yearMonth = `${date.getFullYear()}/${String(date.getMonth() + 1).padStart(2, '0')}`;
    const organizedPath = path.join(this.storagePath, yearMonth);
    await fs.mkdir(organizedPath, { recursive: true });
    
    const finalPath = path.join(organizedPath, metadata.fileName);

    try {
      // Écrire le fichier
      await fs.writeFile(finalPath, file);

      return {
        path: path.relative(this.storagePath, finalPath),
        url: null,
        success: true,
      };
    } catch (error) {
      throw new Error(`Erreur lors de l'écriture du fichier: ${error.message}`);
    }
  }

  /**
   * Télécharge un fichier
   * @param {string} fileName - Nom du fichier ou chemin relatif
   * @returns {Promise<Buffer>}
   */
  async download(fileName) {
    // Chercher le fichier dans la structure organisée
    const filePath = await this.findFile(fileName);
    
    if (!filePath) {
      throw new Error(`Fichier non trouvé: ${fileName}`);
    }

    try {
      return await fs.readFile(filePath);
    } catch (error) {
      throw new Error(`Erreur lors de la lecture du fichier: ${error.message}`);
    }
  }

  /**
   * Trouve un fichier dans la structure de stockage
   * @param {string} fileName - Nom du fichier
   * @returns {Promise<string|null>}
   */
  async findFile(fileName) {
    // Si c'est déjà un chemin relatif complet
    const directPath = path.join(this.storagePath, fileName);
    if (fsSync.existsSync(directPath)) {
      return directPath;
    }

    // Chercher récursivement
    const searchInDir = async (dir) => {
      try {
        const entries = await fs.readdir(dir, { withFileTypes: true });
        
        for (const entry of entries) {
          const fullPath = path.join(dir, entry.name);
          
          if (entry.isDirectory()) {
            const found = await searchInDir(fullPath);
            if (found) return found;
          } else if (entry.name === path.basename(fileName)) {
            return fullPath;
          }
        }
      } catch (error) {
        // Ignorer les erreurs de permission
      }
      return null;
    };

    return await searchInDir(this.storagePath);
  }

  /**
   * Supprime un fichier
   * @param {string} fileName - Nom du fichier
   * @returns {Promise<boolean>}
   */
  async delete(fileName) {
    const filePath = await this.findFile(fileName);
    
    if (!filePath) {
      return false;
    }

    try {
      await fs.unlink(filePath);
      return true;
    } catch (error) {
      throw new Error(`Erreur lors de la suppression: ${error.message}`);
    }
  }

  /**
   * Liste les fichiers
   * @param {Object} options - Options de filtrage
   * @returns {Promise<Array>}
   */
  async list(options = {}) {
    const files = [];
    
    const scanDir = async (dir, basePath = '') => {
      try {
        const entries = await fs.readdir(dir, { withFileTypes: true });
        
        for (const entry of entries) {
          const fullPath = path.join(dir, entry.name);
          const relativePath = path.join(basePath, entry.name);
          
          if (entry.isDirectory() && entry.name !== 'archives') {
            await scanDir(fullPath, relativePath);
          } else if (entry.isFile()) {
            const stats = await fs.stat(fullPath);
            files.push({
              name: entry.name,
              path: relativePath,
              size: stats.size,
              created: stats.birthtime,
              modified: stats.mtime,
            });
          }
        }
      } catch (error) {
        console.error(`Erreur lors du scan de ${dir}:`, error);
      }
    };

    await scanDir(this.storagePath);
    
    // Appliquer les filtres si nécessaire
    let filtered = files;
    if (options.prefix) {
      filtered = filtered.filter(f => f.name.startsWith(options.prefix));
    }
    if (options.limit) {
      filtered = filtered.slice(0, options.limit);
    }
    
    return filtered;
  }

  /**
   * Vérifie si un fichier existe
   * @param {string} fileName - Nom du fichier
   * @returns {Promise<boolean>}
   */
  async exists(fileName) {
    const filePath = await this.findFile(fileName);
    return filePath !== null;
  }

  /**
   * Obtient les métadonnées d'un fichier
   * @param {string} fileName - Nom du fichier
   * @returns {Promise<Object>}
   */
  async getMetadata(fileName) {
    const filePath = await this.findFile(fileName);
    
    if (!filePath) {
      throw new Error(`Fichier non trouvé: ${fileName}`);
    }

    try {
      const stats = await fs.stat(filePath);
      return {
        size: stats.size,
        created: stats.birthtime,
        modified: stats.mtime,
        path: path.relative(this.storagePath, filePath),
      };
    } catch (error) {
      throw new Error(`Erreur lors de la récupération des métadonnées: ${error.message}`);
    }
  }

  /**
   * Archive un fichier
   * @param {string} fileName - Nom du fichier
   * @returns {Promise<Object>}
   */
  async archive(fileName) {
    const filePath = await this.findFile(fileName);
    
    if (!filePath) {
      throw new Error(`Fichier non trouvé: ${fileName}`);
    }

    await this.ensureDirectories();
    
    const archivePath = path.join(this.archivePath, path.basename(fileName));

    try {
      // Déplacer le fichier vers le dossier archives
      await fs.rename(filePath, archivePath);
      
      return {
        success: true,
        archivedPath: path.relative(this.storagePath, archivePath),
      };
    } catch (error) {
      throw new Error(`Erreur lors de l'archivage: ${error.message}`);
    }
  }

  /**
   * Obtient des statistiques de stockage
   * @returns {Promise<Object>}
   */
  async getStats() {
    const files = await this.list();
    
    const totalSize = files.reduce((sum, file) => sum + file.size, 0);
    
    return {
      fileCount: files.length,
      totalSize,
      totalSizeMB: (totalSize / (1024 * 1024)).toFixed(2),
      storagePath: this.storagePath,
      archivePath: this.archivePath,
    };
  }
}

module.exports = LocalStorageProvider;
