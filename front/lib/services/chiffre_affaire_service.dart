import '../services/api_service.dart';

class ChiffreAffaireService {
  // Récupérer le CA mensuel
  Future<List<Map<String, dynamic>>> getCaMensuel({String? exercice}) async {
    final params = <String, dynamic>{};
    if (exercice != null) {
      params['exercice'] = exercice;
    }

    final data = await ApiService.get('chiffre-affaire/mensuel', queryParams: params);
    return List<Map<String, dynamic>>.from(data);
  }

  // Récupérer les statistiques globales
  Future<Map<String, dynamic>> getStatistiques({String? exercice}) async {
    final params = <String, dynamic>{};
    if (exercice != null) {
      params['exercice'] = exercice;
    }

    return await ApiService.get('chiffre-affaire/statistiques', queryParams: params);
  }

  // Récupérer les exercices disponibles
  Future<List<int>> getExercices() async {
    final data = await ApiService.get('chiffre-affaire/exercices');
    return List<int>.from(data);
  }

  // Récupérer le CA par client
  Future<List<Map<String, dynamic>>> getCaParClient({String? exercice}) async {
    final params = <String, dynamic>{};
    if (exercice != null) {
      params['exercice'] = exercice;
    }

    final data = await ApiService.get('chiffre-affaire/par-client', queryParams: params);
    return List<Map<String, dynamic>>.from(data);
  }
}
