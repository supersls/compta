# Frontend Flutter - Compta EI

Application web et mobile développée avec Flutter pour la gestion de la comptabilité.

## 🚀 Installation

```bash
flutter pub get
```

## 🎨 Lancement

### Web (Chrome)
```bash
flutter run -d chrome
```

### Windows
```bash
flutter run -d windows
```

### Android/iOS
```bash
flutter run
```

## 📦 Build Production

### Web
```bash
flutter build web
```

### Windows
```bash
flutter build windows
```

### Android
```bash
flutter build apk
# ou
flutter build appbundle
```

### iOS
```bash
flutter build ios
```

## 🏗️ Structure

```
lib/
├── config/          # Configuration (API, constantes)
├── models/          # Modèles de données
├── screens/         # Écrans de l'application
│   └── factures/    # Gestion des factures
├── services/        # Services HTTP et logique métier
├── utils/           # Utilitaires (formatters, validators, constants)
├── widgets/         # Widgets réutilisables
└── main.dart        # Point d'entrée
```

## 🔧 Configuration

### API Backend

Modifier `lib/config/api_config.dart` pour changer l'URL du backend :

```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:3000/api';
  // Pour mobile/émulateur, utiliser l'IP de votre machine:
  // static const String baseUrl = 'http://192.168.1.X:3000/api';
}
```

## 📱 Plateformes supportées

- ✅ Web (Chrome, Firefox, Safari, Edge)
- ✅ Windows
- ✅ Android
- ✅ iOS
- ✅ macOS
- ✅ Linux

## 🎨 Thème

L'application utilise Material Design 3 avec un thème personnalisé.

## 📚 Dépendances principales

- `http` - Client HTTP pour l'API
- `provider` - Gestion d'état
- `intl` - Internationalisation et formatage
- `fl_chart` - Graphiques
- `pdf` - Génération PDF
- `excel` - Export Excel
- `file_picker` - Sélection de fichiers

## 🐛 Débogage

### Hot Reload
Pendant l'exécution, appuyez sur `r` pour un hot reload.

### DevTools
Ouvrir Flutter DevTools pour le débogage :
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

## 🧪 Tests

```bash
flutter test
```

## 📝 Notes

- L'application nécessite que le backend soit démarré sur `http://localhost:3000`
- Pour mobile, assurez-vous d'utiliser l'IP correcte de votre machine dans `api_config.dart`
- Les données sont persistées dans PostgreSQL via l'API REST
