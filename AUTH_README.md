# Test du système d'authentification

## Backend

### Démarrer le backend
```bash
cd backend
npm install
npm start
```

### Tester l'API d'authentification

**Login**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'
```

Réponse attendue:
```json
{
  "success": true,
  "token": "compta-admin-token-2025",
  "user": {
    "username": "admin",
    "role": "admin"
  }
}
```

**Vérifier le token**
```bash
curl -X POST http://localhost:3000/api/auth/verify \
  -H "Content-Type: application/json" \
  -d '{"token":"compta-admin-token-2025"}'
```

**Logout**
```bash
curl -X POST http://localhost:3000/api/auth/logout \
  -H "Content-Type: application/json"
```

## Frontend

### Démarrer l'application Flutter
```bash
cd front
flutter run -d chrome
```

### Identifiants de connexion
- **Username**: `admin`
- **Password**: `admin`

## Notes

- Le token est stocké dans `SharedPreferences` pour persister la session
- Le système vérifie automatiquement le token au démarrage de l'application
- La déconnexion est disponible dans le menu utilisateur (en haut à droite)
- Pour un système de production, utilisez une vraie base de données et JWT tokens
