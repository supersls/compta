import 'api_service.dart';
import '../models/declaration_tva.dart';

class TVAService {
  // Récupérer toutes les déclarations TVA
  Future<List<DeclarationTVA>> getAllDeclarations() async {
    final List<dynamic> data = await ApiService.get('tva/declarations');
    return data.map((json) => DeclarationTVA.fromMap(json)).toList();
  }

  // Calculer la TVA pour une période
  Future<Map<String, dynamic>> calculerTVA(DateTime debut, DateTime fin) async {
    final debutStr = debut.toIso8601String().split('T')[0];
    final finStr = fin.toIso8601String().split('T')[0];
    
    return await ApiService.get('tva/calcul/$debutStr/$finStr');
  }

  // Créer une déclaration TVA
  Future<DeclarationTVA> createDeclaration(DeclarationTVA declaration) async {
    final data = await ApiService.post('tva/declarations', declaration.toMap());
    return DeclarationTVA.fromMap(data);
  }

  // Mettre à jour une déclaration
  Future<DeclarationTVA> updateDeclaration(DeclarationTVA declaration) async {
    final data = await ApiService.put(
      'tva/declarations/${declaration.id}',
      declaration.toMap(),
    );
    return DeclarationTVA.fromMap(data);
  }

  // Supprimer une déclaration
  Future<void> deleteDeclaration(int id) async {
    await ApiService.delete('tva/declarations/$id');
  }

  // Valider une déclaration
  Future<DeclarationTVA> validerDeclaration(int id) async {
    final data = await ApiService.patch('tva/declarations/$id/valider', {});
    return DeclarationTVA.fromMap(data);
  }

  // Marquer comme transmise
  Future<DeclarationTVA> marquerTransmise(int id, DateTime dateTransmission) async {
    final data = await ApiService.patch('tva/declarations/$id/transmettre', {
      'date_transmission': dateTransmission.toIso8601String(),
    });
    return DeclarationTVA.fromMap(data);
  }

  // Marquer comme payée
  Future<DeclarationTVA> marquerPayee(int id, DateTime datePaiement) async {
    final data = await ApiService.patch('tva/declarations/$id/payer', {
      'date_paiement': datePaiement.toIso8601String(),
    });
    return DeclarationTVA.fromMap(data);
  }

  // Récupérer les statistiques TVA
  Future<Map<String, dynamic>> getStatistiquesTVA() async {
    return await ApiService.get('tva/statistiques');
  }

  // Récupérer le détail de la TVA par taux
  Future<List<Map<String, dynamic>>> getDetailParTaux(DateTime debut, DateTime fin) async {
    final debutStr = debut.toIso8601String().split('T')[0];
    final finStr = fin.toIso8601String().split('T')[0];
    
    final List<dynamic> data = await ApiService.get('tva/detail-taux/$debutStr/$finStr');
    return List<Map<String, dynamic>>.from(data);
  }
}
