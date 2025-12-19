const express = require('express');
const router = express.Router();
const multer = require('multer');
const pool = require('../config/database');
const storageService = require('../services/storageService');

// Configuration de multer pour l'upload en mémoire
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10 MB max
  },
  fileFilter: (req, file, cb) => {
    // Types de fichiers autorisés
    const allowedMimes = [
      'application/pdf',
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-excel',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    ];

    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Type de fichier non autorisé'), false);
    }
  },
});

/**
 * Upload un justificatif
 * POST /api/justificatifs/upload
 */
router.post('/upload', upload.single('file'), async (req, res) => {
  const client = await pool.connect();
  
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: 'Aucun fichier fourni',
      });
    }

    const { 
      description, 
      type_document, 
      date_document, 
      facture_id, 
      ecriture_id, 
      client_id 
    } = req.body;

    // Upload via le service de stockage
    const uploadResult = await storageService.upload(req.file.buffer, {
      originalName: req.file.originalname,
      mimeType: req.file.mimetype,
    });

    // Enregistrer les métadonnées en base
    const query = `
      INSERT INTO justificatifs (
        nom_fichier, nom_original, type_mime, taille_octets, chemin_stockage,
        description, type_document, date_document,
        facture_id, ecriture_id, client_id,
        storage_provider, cloud_url, checksum, cree_par
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
      RETURNING *
    `;

    const values = [
      uploadResult.fileName,
      uploadResult.originalName,
      uploadResult.mimeType,
      uploadResult.size,
      uploadResult.storagePath,
      description || null,
      type_document || null,
      date_document || null,
      facture_id || null,
      ecriture_id || null,
      client_id || null,
      uploadResult.storageProvider,
      uploadResult.cloudUrl,
      uploadResult.checksum,
      req.user?.username || 'system',
    ];

    const result = await client.query(query, values);

    // Enregistrer l'action dans l'historique
    await client.query(
      `INSERT INTO justificatifs_historique (justificatif_id, action, utilisateur)
       VALUES ($1, $2, $3)`,
      [result.rows[0].id, 'upload', req.user?.username || 'system']
    );

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      justificatif: result.rows[0],
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Erreur upload justificatif:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  } finally {
    client.release();
  }
});

/**
 * Liste tous les justificatifs
 * GET /api/justificatifs
 */
router.get('/', async (req, res) => {
  try {
    const { 
      type_document, 
      facture_id, 
      client_id, 
      archive, 
      limit = 100, 
      offset = 0 
    } = req.query;

    let query = 'SELECT * FROM justificatifs WHERE 1=1';
    const values = [];
    let paramCount = 1;

    if (type_document) {
      query += ` AND type_document = $${paramCount}`;
      values.push(type_document);
      paramCount++;
    }

    if (facture_id) {
      query += ` AND facture_id = $${paramCount}`;
      values.push(facture_id);
      paramCount++;
    }

    if (client_id) {
      query += ` AND client_id = $${paramCount}`;
      values.push(client_id);
      paramCount++;
    }

    if (archive !== undefined) {
      query += ` AND archive = $${paramCount}`;
      values.push(archive === 'true');
      paramCount++;
    }

    query += ` ORDER BY cree_le DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    values.push(parseInt(limit), parseInt(offset));

    const result = await pool.query(query, values);

    // Compter le total
    let countQuery = 'SELECT COUNT(*) FROM justificatifs WHERE 1=1';
    const countValues = values.slice(0, -2); // Enlever limit et offset
    if (type_document) countQuery += ' AND type_document = $1';
    if (facture_id) countQuery += ` AND facture_id = $${countValues.length}`;
    if (client_id) countQuery += ` AND client_id = $${countValues.length}`;
    if (archive !== undefined) countQuery += ` AND archive = $${countValues.length}`;

    const countResult = await pool.query(countQuery, countValues);

    res.json({
      success: true,
      justificatifs: result.rows,
      pagination: {
        total: parseInt(countResult.rows[0].count),
        limit: parseInt(limit),
        offset: parseInt(offset),
      },
    });
  } catch (error) {
    console.error('Erreur liste justificatifs:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * Récupère un justificatif spécifique
 * GET /api/justificatifs/:id
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(
      'SELECT * FROM justificatifs WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Justificatif non trouvé',
      });
    }

    res.json({
      success: true,
      justificatif: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * Télécharge le fichier d'un justificatif
 * GET /api/justificatifs/:id/download
 */
router.get('/:id/download', async (req, res) => {
  const client = await pool.connect();
  
  try {
    const { id } = req.params;
    
    // Récupérer les infos du justificatif
    const result = await client.query(
      'SELECT * FROM justificatifs WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Justificatif non trouvé',
      });
    }

    const justificatif = result.rows[0];

    // Télécharger le fichier depuis le stockage
    const fileBuffer = await storageService.download(justificatif.nom_fichier);

    // Enregistrer le téléchargement dans l'historique
    await client.query(
      `INSERT INTO justificatifs_historique (justificatif_id, action, utilisateur)
       VALUES ($1, $2, $3)`,
      [id, 'download', req.user?.username || 'anonymous']
    );

    // Envoyer le fichier
    res.set({
      'Content-Type': justificatif.type_mime,
      'Content-Disposition': `attachment; filename="${justificatif.nom_original}"`,
      'Content-Length': justificatif.taille_octets,
    });

    res.send(fileBuffer);
  } catch (error) {
    console.error('Erreur téléchargement justificatif:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  } finally {
    client.release();
  }
});

/**
 * Visualise un justificatif (inline au lieu de download)
 * GET /api/justificatifs/:id/view
 */
router.get('/:id/view', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(
      'SELECT * FROM justificatifs WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Justificatif non trouvé',
      });
    }

    const justificatif = result.rows[0];
    const fileBuffer = await storageService.download(justificatif.nom_fichier);

    res.set({
      'Content-Type': justificatif.type_mime,
      'Content-Disposition': `inline; filename="${justificatif.nom_original}"`,
    });

    res.send(fileBuffer);
  } catch (error) {
    console.error('Erreur visualisation justificatif:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * Archive un justificatif
 * POST /api/justificatifs/:id/archive
 */
router.post('/:id/archive', async (req, res) => {
  const client = await pool.connect();
  
  try {
    const { id } = req.params;

    await client.query('BEGIN');

    // Vérifier que le justificatif existe
    const checkResult = await client.query(
      'SELECT * FROM justificatifs WHERE id = $1',
      [id]
    );

    if (checkResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        error: 'Justificatif non trouvé',
      });
    }

    const justificatif = checkResult.rows[0];

    // Archiver le fichier via le service
    const archiveResult = await storageService.archive(justificatif.nom_fichier);

    // Mettre à jour la base de données
    const updateResult = await client.query(
      `UPDATE justificatifs 
       SET archive = true, 
           date_archivage = CURRENT_TIMESTAMP,
           chemin_stockage = $1,
           modifie_par = $2
       WHERE id = $3
       RETURNING *`,
      [archiveResult.archivedPath, req.user?.username || 'system', id]
    );

    // Enregistrer dans l'historique
    await client.query(
      `INSERT INTO justificatifs_historique (justificatif_id, action, utilisateur)
       VALUES ($1, $2, $3)`,
      [id, 'archive', req.user?.username || 'system']
    );

    await client.query('COMMIT');

    res.json({
      success: true,
      justificatif: updateResult.rows[0],
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Erreur archivage justificatif:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  } finally {
    client.release();
  }
});

/**
 * Supprime un justificatif
 * DELETE /api/justificatifs/:id
 */
router.delete('/:id', async (req, res) => {
  const client = await pool.connect();
  
  try {
    const { id } = req.params;

    await client.query('BEGIN');

    // Récupérer les infos du justificatif
    const result = await client.query(
      'SELECT * FROM justificatifs WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        error: 'Justificatif non trouvé',
      });
    }

    const justificatif = result.rows[0];

    // Supprimer le fichier du stockage
    await storageService.delete(justificatif.nom_fichier);

    // Enregistrer la suppression dans l'historique avant de supprimer
    await client.query(
      `INSERT INTO justificatifs_historique (justificatif_id, action, utilisateur, details)
       VALUES ($1, $2, $3, $4)`,
      [id, 'delete', req.user?.username || 'system', JSON.stringify({ nom_fichier: justificatif.nom_fichier })]
    );

    // Supprimer de la base
    await client.query('DELETE FROM justificatifs WHERE id = $1', [id]);

    await client.query('COMMIT');

    res.json({
      success: true,
      message: 'Justificatif supprimé avec succès',
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Erreur suppression justificatif:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  } finally {
    client.release();
  }
});

/**
 * Met à jour les métadonnées d'un justificatif
 * PUT /api/justificatifs/:id
 */
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { description, type_document, date_document, facture_id, ecriture_id, client_id } = req.body;

    const query = `
      UPDATE justificatifs
      SET description = COALESCE($1, description),
          type_document = COALESCE($2, type_document),
          date_document = COALESCE($3, date_document),
          facture_id = COALESCE($4, facture_id),
          ecriture_id = COALESCE($5, ecriture_id),
          client_id = COALESCE($6, client_id),
          modifie_par = $7
      WHERE id = $8
      RETURNING *
    `;

    const result = await pool.query(query, [
      description,
      type_document,
      date_document,
      facture_id,
      ecriture_id,
      client_id,
      req.user?.username || 'system',
      id,
    ]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Justificatif non trouvé',
      });
    }

    res.json({
      success: true,
      justificatif: result.rows[0],
    });
  } catch (error) {
    console.error('Erreur mise à jour justificatif:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * Obtient les statistiques des justificatifs
 * GET /api/justificatifs/stats/summary
 */
router.get('/stats/summary', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM justificatifs_stats');
    
    // Obtenir les stats du service de stockage
    const storageStats = await storageService.getStorageStats();

    res.json({
      success: true,
      stats: {
        ...result.rows[0],
        storage: storageStats,
      },
    });
  } catch (error) {
    console.error('Erreur stats justificatifs:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * Obtient l'historique d'un justificatif
 * GET /api/justificatifs/:id/history
 */
router.get('/:id/history', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(
      `SELECT * FROM justificatifs_historique 
       WHERE justificatif_id = $1 
       ORDER BY date_action DESC`,
      [id]
    );

    res.json({
      success: true,
      history: result.rows,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
