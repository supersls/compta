import '../services/api_service.dart';
import '../models/ecriture_comptable.dart';
import '../config/api_config.dart';
import '../utils/url_helper.dart';

class DocumentsService {
  // Journal Comptable
  Future<List<EcritureComptable>> getJournalComptable({
    required int entrepriseId,
    required DateTime debut,
    required DateTime fin,
    String? journal,
  }) async {
    final params = {
      'entreprise_id': entrepriseId,
      'debut': debut.toIso8601String(),
      'fin': fin.toIso8601String(),
      if (journal != null) 'journal': journal,
    };
    
    final data = await ApiService.get('documents/journal', queryParams: params);
    return (data as List).map((e) => EcritureComptable.fromMap(e)).toList();
  }

  // Grand Livre
  Future<List<Map<String, dynamic>>> getGrandLivre({
    required int entrepriseId,
    required DateTime debut,
    required DateTime fin,
    String? compte,
  }) async {
    final params = {
      'entreprise_id': entrepriseId,
      'debut': debut.toIso8601String(),
      'fin': fin.toIso8601String(),
      if (compte != null) 'compte': compte,
    };
    
    final data = await ApiService.get('documents/grand-livre', queryParams: params);
    return List<Map<String, dynamic>>.from(data);
  }

  // Bilan Comptable
  Future<Map<String, dynamic>> getBilan({
    required int entrepriseId,
    required DateTime dateArrete,
  }) async {
    final params = {
      'entreprise_id': entrepriseId,
      'date': dateArrete.toIso8601String(),
    };
    
    return await ApiService.get('documents/bilan', queryParams: params);
  }

  // Compte de Résultat
  Future<Map<String, dynamic>> getCompteResultat({
    required int entrepriseId,
    required DateTime debut,
    required DateTime fin,
  }) async {
    final params = {
      'entreprise_id': entrepriseId,
      'debut': debut.toIso8601String(),
      'fin': fin.toIso8601String(),
    };
    
    return await ApiService.get('documents/compte-resultat', queryParams: params);
  }

  // Export PDF
  Future<void> exportPDF(String documentType, Map<String, dynamic> params) async {
    try {
      // Construire l'URL avec les paramètres
      final uri = Uri.parse('${ApiConfig.baseUrl}/documents/export/pdf/$documentType')
          .replace(queryParameters: params.map((key, value) => MapEntry(key, value.toString())));
      
      // Ouvrir dans un nouvel onglet pour télécharger le PDF
      UrlHelper.openInNewTab(uri.toString());
    } catch (e) {
      rethrow;
    }
  }

  // Export Excel
  Future<void> exportExcel(String documentType, Map<String, dynamic> params) async {
    try {
      // Construire l'URL avec les paramètres
      final uri = Uri.parse('${ApiConfig.baseUrl}/documents/export/excel/$documentType')
          .replace(queryParameters: params.map((key, value) => MapEntry(key, value.toString())));
      
      // Ouvrir dans un nouvel onglet pour télécharger l'Excel
      UrlHelper.openInNewTab(uri.toString());
    } catch (e) {
      rethrow;
    }
  }

  // Balance des comptes
  Future<List<Map<String, dynamic>>> getBalance({
    required int entrepriseId,
    required DateTime debut,
    required DateTime fin,
  }) async {
    final params = {
      'entreprise_id': entrepriseId,
      'debut': debut.toIso8601String(),
      'fin': fin.toIso8601String(),
    };
    
    final data = await ApiService.get('documents/balance', queryParams: params);
    return List<Map<String, dynamic>>.from(data);
  }

  // Créer une nouvelle écriture comptable
  Future<EcritureComptable> createEcriture({
    required int entrepriseId,
    required String numeroPiece,
    required DateTime dateEcriture,
    required String journal,
    required String compte,
    required String libelle,
    required double debit,
    required double credit,
  }) async {
    final data = {
      'entreprise_id': entrepriseId,
      'numero_piece': numeroPiece,
      'date_ecriture': dateEcriture.toIso8601String(),
      'journal': journal,
      'compte': compte,
      'libelle': libelle,
      'debit': debit,
      'credit': credit,
      'validee': true,
    };
    
    final response = await ApiService.post('comptabilite/ecritures', data);
    return EcritureComptable.fromMap(response);
  }
}
