# PDF Export Implementation - Backend Architecture

## Vue d'ensemble
L'export PDF a été implémenté dans le backend avec une architecture réutilisable pour tous les documents comptables.

## Architecture

### Backend
#### Service PDF réutilisable (`backend/services/pdfGenerator.js`)
Un service centralisé qui fournit:
- **Méthodes utilitaires communes**:
  - `createDocument()` - Création de document PDF
  - `addHeader()` - En-tête standardisé
  - `addFooter()` - Pied de page avec date de génération
  - `addTable()` - Tableaux avec style alterné
  - `addSection()` - Sections avec titres
  - `addKeyValue()` - Lignes clé-valeur
  - `addHighlightBox()` - Encadrés mis en évidence
  - `formatDate()` - Formatage de dates
  - `formatCurrency()` - Formatage de montants

- **Générateurs spécifiques**:
  - `generateCompteResultat(data)` - Compte de résultat
  - `generateJournal(ecritures, options)` - Journal comptable
  - `generateGrandLivre(comptes, options)` - Grand livre
  - `generateBilan(data)` - Bilan comptable

#### Route d'export (`backend/routes/documents.js`)
- **Endpoint unique**: `GET /api/documents/export/pdf/:type`
- **Types supportés**: 
  - `compte-resultat`
  - `journal`
  - `grand-livre`
  - `bilan`
- **Workflow**:
  1. Récupération des données depuis la base
  2. Génération du PDF via le service
  3. Envoi en streaming avec headers appropriés
  4. Téléchargement automatique côté client

### Frontend
#### Service de documents (`front/lib/services/documents_service.dart`)
- Méthode `exportPDF()` qui ouvre l'URL du PDF dans un nouvel onglet
- Utilise `UrlHelper` pour compatibilité web

#### Helper URL (`front/lib/utils/url_helper.dart`)
- Utilise `dart:html` pour Flutter Web
- `openInNewTab()` - Ouvre l'URL dans un nouvel onglet
- `downloadFile()` - Télécharge directement un fichier

## Utilisation

### Ajouter un nouveau type de document
1. **Créer le générateur dans `pdfGenerator.js`**:
```javascript
generateMonDocument(data) {
  const doc = this.createDocument();
  this.addHeader(doc, 'MON DOCUMENT', 'Sous-titre');
  // ... logique de génération
  this.addFooter(doc);
  return doc;
}
```

2. **Ajouter le case dans `documents.js`**:
```javascript
case 'mon-document': {
  // Récupérer les données
  const data = await fetchData();
  doc = pdfGenerator.generateMonDocument(data);
  filename = 'mon-document.pdf';
  break;
}
```

3. **Appeler depuis le frontend**:
```dart
await _service.exportPDF('mon-document', {
  'param1': value1,
  'param2': value2,
});
```

## Avantages de cette architecture
✅ **Réutilisabilité**: Un seul service pour tous les documents
✅ **Cohérence**: Style uniforme pour tous les PDFs
✅ **Maintenabilité**: Modifications centralisées
✅ **Performance**: Génération côté serveur
✅ **Scalabilité**: Facile d'ajouter de nouveaux documents
✅ **Séparation des responsabilités**: Frontend/Backend bien séparés

## Technologies utilisées
- **Backend**: Node.js + PDFKit
- **Frontend**: Flutter Web + dart:html
- **Base de données**: PostgreSQL

## Prochaines étapes possibles
- [ ] Ajouter l'export Excel avec un service similaire
- [ ] Permettre la personnalisation du style (logo, couleurs)
- [ ] Ajouter des graphiques dans les PDFs
- [ ] Implémenter un système de templates
- [ ] Ajouter la compression des PDFs
