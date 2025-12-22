const express = require('express');
const router = express.Router();

// Simple hardcoded authentication
const ADMIN_USER = {
  username: 'admin',
  password: 'admin',
  token: 'compta-admin-token-2025'
};

// POST /api/auth/login
router.post('/login', (req, res) => {
  try {
    const { username, password } = req.body;

    // Validation
    if (!username || !password) {
      return res.status(400).json({ 
        error: 'Username et password requis' 
      });
    }

    // Check credentials
    if (username === ADMIN_USER.username && password === ADMIN_USER.password) {
      return res.json({
        success: true,
        token: ADMIN_USER.token,
        user: {
          username: ADMIN_USER.username,
          role: 'admin'
        }
      });
    }

    // Invalid credentials
    return res.status(401).json({ 
      error: 'Identifiants incorrects' 
    });
  } catch (error) {
    console.error('Erreur login:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// POST /api/auth/verify - Verify token
router.post('/verify', (req, res) => {
  try {
    const { token } = req.body;

    if (token === ADMIN_USER.token) {
      return res.json({
        success: true,
        user: {
          username: ADMIN_USER.username,
          role: 'admin'
        }
      });
    }

    return res.status(401).json({ error: 'Token invalide' });
  } catch (error) {
    console.error('Erreur verify:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// POST /api/auth/logout
router.post('/logout', (req, res) => {
  res.json({ success: true, message: 'Déconnexion réussie' });
});

module.exports = router;
