import '../services/api_service.dart';
import '../models/ecriture_comptable.dart';

class DocumentsService {
  // Journal Comptable
  Future<List<EcritureComptable>> getJournalComptable({
    required DateTime debut,
    required DateTime fin,
    String? journal,
  }) async {
    final params = {
      'debut': debut.toIso8601String(),
      'fin': fin.toIso8601String(),
      if (journal != null) 'journal': journal,
    };
    
    final data = await ApiService.get('documents/journal', queryParams: params);
    return (data as List).map((e) => EcritureComptable.fromMap(e)).toList();
  }

  // Grand Livre
  Future<List<Map<String, dynamic>>> getGrandLivre({
    required DateTime debut,
    required DateTime fin,
    String? compte,
  }) async {
    final params = {
      'debut': debut.toIso8601String(),
      'fin': fin.toIso8601String(),
      if (compte != null) 'compte': compte,
    };
    
    final data = await ApiService.get('documents/grand-livre', queryParams: params);
    return List<Map<String, dynamic>>.from(data);
  }

  // Bilan Comptable
  Future<Map<String, dynamic>> getBilan({
    required DateTime dateArrete,
  }) async {
    final params = {
      'date': dateArrete.toIso8601String(),
    };
    
    return await ApiService.get('documents/bilan', queryParams: params);
  }

  // Compte de Résultat
  Future<Map<String, dynamic>> getCompteResultat({
    required DateTime debut,
    required DateTime fin,
  }) async {
    final params = {
      'debut': debut.toIso8601String(),
      'fin': fin.toIso8601String(),
    };
    
    return await ApiService.get('documents/compte-resultat', queryParams: params);
  }

  // Export PDF
  Future<void> exportPDF(String documentType, Map<String, dynamic> params) async {
    final response = await ApiService.downloadFile(
      'documents/export/pdf/$documentType',
      queryParams: params,
    );
    // Le téléchargement sera géré par le navigateur
  }

  // Export Excel
  Future<void> exportExcel(String documentType, Map<String, dynamic> params) async {
    final response = await ApiService.downloadFile(
      'documents/export/excel/$documentType',
      queryParams: params,
    );
    // Le téléchargement sera géré par le navigateur
  }

  // Balance des comptes
  Future<List<Map<String, dynamic>>> getBalance({
    required DateTime debut,
    required DateTime fin,
  }) async {
    final params = {
      'debut': debut.toIso8601String(),
      'fin': fin.toIso8601String(),
    };
    
    final data = await ApiService.get('documents/balance', queryParams: params);
    return List<Map<String, dynamic>>.from(data);
  }
}
