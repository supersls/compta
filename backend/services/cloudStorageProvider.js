const { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand, ListObjectsV2Command, HeadObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const stream = require('stream');

/**
 * Provider de stockage cloud (S3-compatible) pour les justificatifs
 * Compatible avec AWS S3, MinIO, DigitalOcean Spaces, etc.
 */
class CloudStorageProvider {
  constructor(config) {
    this.bucket = config.bucket;
    this.region = config.region || 'eu-west-1';
    this.prefix = config.prefix || 'justificatifs/';
    this.archivePrefix = config.archivePrefix || 'justificatifs/archives/';
    
    // Initialiser le client S3
    this.s3Client = new S3Client({
      region: this.region,
      credentials: {
        accessKeyId: config.accessKeyId,
        secretAccessKey: config.secretAccessKey,
      },
      // Pour utiliser des services compatibles S3 (MinIO, etc.)
      ...(config.endpoint && { endpoint: config.endpoint }),
      ...(config.forcePathStyle && { forcePathStyle: true }),
    });
  }

  /**
   * Upload un fichier vers S3
   * @param {Buffer} file - Contenu du fichier
   * @param {Object} metadata - Métadonnées
   * @returns {Promise<Object>}
   */
  async upload(file, metadata) {
    // Organiser par année/mois
    const date = new Date();
    const yearMonth = `${date.getFullYear()}/${String(date.getMonth() + 1).padStart(2, '0')}`;
    const key = `${this.prefix}${yearMonth}/${metadata.fileName}`;

    const command = new PutObjectCommand({
      Bucket: this.bucket,
      Key: key,
      Body: file,
      ContentType: metadata.mimeType || 'application/octet-stream',
      Metadata: {
        originalName: metadata.originalName || '',
        uploadDate: new Date().toISOString(),
        checksum: metadata.checksum || '',
      },
      // Optionnel: chiffrement côté serveur
      ServerSideEncryption: 'AES256',
    });

    try {
      await this.s3Client.send(command);

      // Générer une URL signée (valide 1 heure)
      const url = await this.getSignedDownloadUrl(key, 3600);

      return {
        path: key,
        url,
        success: true,
      };
    } catch (error) {
      throw new Error(`Erreur lors de l'upload S3: ${error.message}`);
    }
  }

  /**
   * Télécharge un fichier depuis S3
   * @param {string} fileName - Nom du fichier ou clé S3
   * @returns {Promise<Buffer>}
   */
  async download(fileName) {
    // Si fileName est déjà une clé complète, l'utiliser directement
    const key = fileName.includes('/') ? fileName : await this.findKey(fileName);

    const command = new GetObjectCommand({
      Bucket: this.bucket,
      Key: key,
    });

    try {
      const response = await this.s3Client.send(command);
      
      // Convertir le stream en buffer
      return await this.streamToBuffer(response.Body);
    } catch (error) {
      throw new Error(`Erreur lors du téléchargement S3: ${error.message}`);
    }
  }

  /**
   * Trouve la clé S3 d'un fichier par son nom
   * @param {string} fileName - Nom du fichier
   * @returns {Promise<string>}
   */
  async findKey(fileName) {
    const command = new ListObjectsV2Command({
      Bucket: this.bucket,
      Prefix: this.prefix,
    });

    try {
      const response = await this.s3Client.send(command);
      const file = response.Contents?.find(obj => obj.Key.endsWith(fileName));
      
      if (!file) {
        throw new Error(`Fichier non trouvé: ${fileName}`);
      }
      
      return file.Key;
    } catch (error) {
      throw new Error(`Erreur lors de la recherche du fichier: ${error.message}`);
    }
  }

  /**
   * Supprime un fichier de S3
   * @param {string} fileName - Nom du fichier ou clé S3
   * @returns {Promise<boolean>}
   */
  async delete(fileName) {
    const key = fileName.includes('/') ? fileName : await this.findKey(fileName);

    const command = new DeleteObjectCommand({
      Bucket: this.bucket,
      Key: key,
    });

    try {
      await this.s3Client.send(command);
      return true;
    } catch (error) {
      throw new Error(`Erreur lors de la suppression S3: ${error.message}`);
    }
  }

  /**
   * Liste les fichiers dans S3
   * @param {Object} options - Options de filtrage
   * @returns {Promise<Array>}
   */
  async list(options = {}) {
    const command = new ListObjectsV2Command({
      Bucket: this.bucket,
      Prefix: options.prefix || this.prefix,
      MaxKeys: options.limit || 1000,
    });

    try {
      const response = await this.s3Client.send(command);
      
      if (!response.Contents) {
        return [];
      }

      return response.Contents.map(obj => ({
        name: obj.Key.split('/').pop(),
        path: obj.Key,
        size: obj.Size,
        modified: obj.LastModified,
        etag: obj.ETag,
      }));
    } catch (error) {
      throw new Error(`Erreur lors du listage S3: ${error.message}`);
    }
  }

  /**
   * Vérifie si un fichier existe dans S3
   * @param {string} fileName - Nom du fichier
   * @returns {Promise<boolean>}
   */
  async exists(fileName) {
    try {
      const key = fileName.includes('/') ? fileName : await this.findKey(fileName);
      
      const command = new HeadObjectCommand({
        Bucket: this.bucket,
        Key: key,
      });

      await this.s3Client.send(command);
      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * Obtient les métadonnées d'un fichier S3
   * @param {string} fileName - Nom du fichier
   * @returns {Promise<Object>}
   */
  async getMetadata(fileName) {
    const key = fileName.includes('/') ? fileName : await this.findKey(fileName);

    const command = new HeadObjectCommand({
      Bucket: this.bucket,
      Key: key,
    });

    try {
      const response = await this.s3Client.send(command);
      
      return {
        size: response.ContentLength,
        mimeType: response.ContentType,
        modified: response.LastModified,
        metadata: response.Metadata,
        etag: response.ETag,
        path: key,
      };
    } catch (error) {
      throw new Error(`Erreur lors de la récupération des métadonnées S3: ${error.message}`);
    }
  }

  /**
   * Archive un fichier (le déplace vers le préfixe archives)
   * @param {string} fileName - Nom du fichier
   * @returns {Promise<Object>}
   */
  async archive(fileName) {
    const sourceKey = fileName.includes('/') ? fileName : await this.findKey(fileName);
    const targetKey = sourceKey.replace(this.prefix, this.archivePrefix);

    try {
      // Copier vers le dossier archives
      const copyCommand = new PutObjectCommand({
        Bucket: this.bucket,
        Key: targetKey,
        CopySource: `${this.bucket}/${sourceKey}`,
      });

      await this.s3Client.send(copyCommand);

      // Supprimer l'original
      await this.delete(sourceKey);

      return {
        success: true,
        archivedPath: targetKey,
      };
    } catch (error) {
      throw new Error(`Erreur lors de l'archivage S3: ${error.message}`);
    }
  }

  /**
   * Génère une URL signée pour télécharger un fichier
   * @param {string} key - Clé S3 du fichier
   * @param {number} expiresIn - Durée de validité en secondes
   * @returns {Promise<string>}
   */
  async getSignedDownloadUrl(key, expiresIn = 3600) {
    const command = new GetObjectCommand({
      Bucket: this.bucket,
      Key: key,
    });

    try {
      return await getSignedUrl(this.s3Client, command, { expiresIn });
    } catch (error) {
      throw new Error(`Erreur lors de la génération de l'URL signée: ${error.message}`);
    }
  }

  /**
   * Obtient des statistiques de stockage S3
   * @returns {Promise<Object>}
   */
  async getStats() {
    try {
      const files = await this.list();
      const totalSize = files.reduce((sum, file) => sum + file.size, 0);

      return {
        fileCount: files.length,
        totalSize,
        totalSizeMB: (totalSize / (1024 * 1024)).toFixed(2),
        bucket: this.bucket,
        region: this.region,
      };
    } catch (error) {
      return {
        error: error.message,
        fileCount: 0,
        totalSize: 0,
      };
    }
  }

  /**
   * Convertit un stream en buffer
   * @param {Stream} stream - Stream à convertir
   * @returns {Promise<Buffer>}
   */
  async streamToBuffer(readableStream) {
    return new Promise((resolve, reject) => {
      const chunks = [];
      readableStream.on('data', (chunk) => chunks.push(chunk));
      readableStream.on('error', reject);
      readableStream.on('end', () => resolve(Buffer.concat(chunks)));
    });
  }
}

module.exports = CloudStorageProvider;
