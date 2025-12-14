import 'api_service.dart';
import '../models/declaration_tva.dart';

class TVAService {
  // Récupérer toutes les déclarations TVA
  Future<List<DeclarationTVA>> getAllDeclarations(int entrepriseId) async {
    final List<dynamic> data = await ApiService.get('tva/declarations', queryParams: {'entreprise_id': entrepriseId});
    return data.map((json) => DeclarationTVA.fromMap(json)).toList();
  }

  // Calculer la TVA pour une période
  Future<Map<String, dynamic>> calculerTVA(DateTime debut, DateTime fin) async {
    final debutStr = debut.toIso8601String().split('T')[0];
    final finStr = fin.toIso8601String().split('T')[0];
    
    final result = await ApiService.get('tva/calcul/$debutStr/$finStr');
    
    // Map backend field names to frontend expected names
    return {
      'tva_collectee': result['tvaCollectee'] ?? 0,
      'tva_deductible': result['tvaDeductible'] ?? 0,
      'tva_a_decaisser': result['tvaADecaisser'] ?? 0,
      'periode_debut': result['periodeDebut'],
      'periode_fin': result['periodeFin'],
    };
  }

  // NOTE: Create, update, delete endpoints are not implemented in backend yet
  // These features are disabled until backend implementation is complete
  
  // Récupérer les statistiques TVA
  Future<Map<String, dynamic>> getStatistiquesTVA(int entrepriseId) async {
    return await ApiService.get('tva/statistiques', queryParams: {'entreprise_id': entrepriseId});
  }

  // Alias pour getTVAStats
  Future<Map<String, dynamic>> getTVAStats(int entrepriseId) async {
    return await getStatistiquesTVA(entrepriseId);
  }

  // Récupérer le détail de la TVA par taux
  Future<List<Map<String, dynamic>>> getDetailParTaux(DateTime debut, DateTime fin) async {
    final debutStr = debut.toIso8601String().split('T')[0];
    final finStr = fin.toIso8601String().split('T')[0];
    
    final List<dynamic> data = await ApiService.get('tva/detail-taux/$debutStr/$finStr');
    return List<Map<String, dynamic>>.from(data);
  }
}
