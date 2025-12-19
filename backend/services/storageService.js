const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');

/**
 * Service abstrait de stockage pour les justificatifs
 * Permet de basculer entre stockage local et cloud de manière transparente
 */
class StorageService {
  constructor() {
    this.provider = null;
    this.storageMode = process.env.STORAGE_MODE || 'local';
    this.initializeProvider();
  }

  /**
   * Initialise le provider de stockage selon la configuration
   */
  initializeProvider() {
    if (this.storageMode === 'cloud') {
      const CloudStorageProvider = require('./cloudStorageProvider');
      this.provider = new CloudStorageProvider({
        accessKeyId: process.env.S3_ACCESS_KEY_ID,
        secretAccessKey: process.env.S3_SECRET_ACCESS_KEY,
        region: process.env.S3_REGION || 'eu-west-1',
        bucket: process.env.S3_BUCKET || 'compta-justificatifs',
      });
    } else {
      const LocalStorageProvider = require('./localStorageProvider');
      this.provider = new LocalStorageProvider({
        storagePath: process.env.LOCAL_STORAGE_PATH || path.join(__dirname, '../storage/justificatifs'),
      });
    }
  }

  /**
   * Upload un fichier
   * @param {Buffer|Stream} file - Contenu du fichier
   * @param {Object} metadata - Métadonnées du fichier
   * @returns {Promise<Object>} Informations sur le fichier uploadé
   */
  async upload(file, metadata) {
    try {
      // Générer un nom unique pour le fichier
      const uniqueName = this.generateUniqueFilename(metadata.originalName);
      
      // Calculer le checksum
      const checksum = this.calculateChecksum(file);
      
      // Upload via le provider
      const result = await this.provider.upload(file, {
        ...metadata,
        fileName: uniqueName,
        checksum,
      });

      return {
        fileName: uniqueName,
        originalName: metadata.originalName,
        size: file.length || file.size,
        mimeType: metadata.mimeType,
        storagePath: result.path,
        checksum,
        storageProvider: this.storageMode,
        cloudUrl: result.url || null,
      };
    } catch (error) {
      throw new Error(`Erreur lors de l'upload: ${error.message}`);
    }
  }

  /**
   * Télécharge un fichier
   * @param {string} fileName - Nom du fichier
   * @returns {Promise<Buffer|Stream>} Contenu du fichier
   */
  async download(fileName) {
    try {
      return await this.provider.download(fileName);
    } catch (error) {
      throw new Error(`Erreur lors du téléchargement: ${error.message}`);
    }
  }

  /**
   * Supprime un fichier
   * @param {string} fileName - Nom du fichier
   * @returns {Promise<boolean>}
   */
  async delete(fileName) {
    try {
      return await this.provider.delete(fileName);
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
    try {
      return await this.provider.list(options);
    } catch (error) {
      throw new Error(`Erreur lors du listage: ${error.message}`);
    }
  }

  /**
   * Vérifie si un fichier existe
   * @param {string} fileName - Nom du fichier
   * @returns {Promise<boolean>}
   */
  async exists(fileName) {
    try {
      return await this.provider.exists(fileName);
    } catch (error) {
      return false;
    }
  }

  /**
   * Obtient les métadonnées d'un fichier
   * @param {string} fileName - Nom du fichier
   * @returns {Promise<Object>}
   */
  async getMetadata(fileName) {
    try {
      return await this.provider.getMetadata(fileName);
    } catch (error) {
      throw new Error(`Erreur lors de la récupération des métadonnées: ${error.message}`);
    }
  }

  /**
   * Archive un fichier (déplacement vers un dossier d'archives)
   * @param {string} fileName - Nom du fichier
   * @returns {Promise<Object>}
   */
  async archive(fileName) {
    try {
      return await this.provider.archive(fileName);
    } catch (error) {
      throw new Error(`Erreur lors de l'archivage: ${error.message}`);
    }
  }

  /**
   * Génère un nom de fichier unique
   * @param {string} originalName - Nom original du fichier
   * @returns {string}
   */
  generateUniqueFilename(originalName) {
    const timestamp = Date.now();
    const random = crypto.randomBytes(8).toString('hex');
    const ext = path.extname(originalName);
    const baseName = path.basename(originalName, ext)
      .replace(/[^a-z0-9]/gi, '_')
      .toLowerCase();
    
    return `${timestamp}_${random}_${baseName}${ext}`;
  }

  /**
   * Calcule le checksum SHA-256 d'un fichier
   * @param {Buffer} buffer - Contenu du fichier
   * @returns {string}
   */
  calculateChecksum(buffer) {
    return crypto.createHash('sha256').update(buffer).digest('hex');
  }

  /**
   * Vérifie l'intégrité d'un fichier
   * @param {string} fileName - Nom du fichier
   * @param {string} expectedChecksum - Checksum attendu
   * @returns {Promise<boolean>}
   */
  async verifyIntegrity(fileName, expectedChecksum) {
    try {
      const file = await this.download(fileName);
      const actualChecksum = this.calculateChecksum(file);
      return actualChecksum === expectedChecksum;
    } catch (error) {
      return false;
    }
  }

  /**
   * Obtient des statistiques de stockage
   * @returns {Promise<Object>}
   */
  async getStorageStats() {
    try {
      return await this.provider.getStats();
    } catch (error) {
      return {
        error: error.message,
        totalSize: 0,
        fileCount: 0,
      };
    }
  }

  /**
   * Migre un fichier d'un provider à un autre
   * @param {string} fileName - Nom du fichier
   * @param {string} targetMode - Mode cible ('local' ou 'cloud')
   * @returns {Promise<Object>}
   */
  async migrate(fileName, targetMode) {
    if (targetMode === this.storageMode) {
      throw new Error('Le fichier est déjà dans le mode de stockage cible');
    }

    // Télécharger depuis le provider actuel
    const fileContent = await this.download(fileName);
    const metadata = await this.getMetadata(fileName);

    // Créer temporairement un provider cible
    const originalMode = this.storageMode;
    this.storageMode = targetMode;
    this.initializeProvider();

    try {
      // Upload vers le nouveau provider
      const result = await this.upload(fileContent, {
        originalName: metadata.originalName || fileName,
        mimeType: metadata.mimeType || 'application/octet-stream',
      });

      // Restaurer le provider original et supprimer l'ancien fichier
      this.storageMode = originalMode;
      this.initializeProvider();
      await this.delete(fileName);

      return result;
    } catch (error) {
      // En cas d'erreur, restaurer le provider original
      this.storageMode = originalMode;
      this.initializeProvider();
      throw error;
    }
  }
}

module.exports = new StorageService();
