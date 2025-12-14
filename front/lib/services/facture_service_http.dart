import '../models/facture.dart';
import 'api_service.dart';

class FactureService {
  // Créer une nouvelle facture
  Future<Facture> createFacture(Facture facture) async {
    final data = await ApiService.post('factures', facture.toMap());
    return Facture.fromMap(data);
  }

  // Récupérer toutes les factures
  Future<List<Facture>> getAllFactures(int entrepriseId) async {
    final List<dynamic> data = await ApiService.get('factures', queryParams: {'entreprise_id': entrepriseId});
    return data.map((json) => Facture.fromMap(json)).toList();
  }

  // Récupérer les factures par type
  Future<List<Facture>> getFacturesByType(String type) async {
    final List<dynamic> data = await ApiService.get('factures/type/$type');
    return data.map((json) => Facture.fromMap(json)).toList();
  }

  // Récupérer les factures par statut
  Future<List<Facture>> getFacturesByStatut(String statut) async {
    final List<dynamic> data = await ApiService.get('factures/statut/$statut');
    return data.map((json) => Facture.fromMap(json)).toList();
  }

  // Récupérer une facture par ID
  Future<Facture?> getFactureById(int id) async {
    try {
      final data = await ApiService.get('factures/$id');
      return Facture.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  // Mettre à jour une facture
  Future<Facture> updateFacture(Facture facture) async {
    final data = await ApiService.put(
      'factures/${facture.id}',
      facture.toMap(),
    );
    return Facture.fromMap(data);
  }

  // Supprimer une facture
  Future<void> deleteFacture(int id) async {
    await ApiService.delete('factures/$id');
  }

  // Rechercher des factures
  Future<List<Facture>> searchFactures(String query) async {
    final List<dynamic> data = await ApiService.post(
      'factures/search',
      {'query': query},
    );
    return data.map((json) => Facture.fromMap(json)).toList();
  }

  // Récupérer les factures en retard
  Future<List<Facture>> getFacturesEnRetard() async {
    final List<dynamic> data = await ApiService.get('factures/filter/retard');
    return data.map((json) => Facture.fromMap(json)).toList();
  }

  // Récupérer les statistiques
  Future<Map<String, dynamic>> getFacturesStats(int entrepriseId) async {
    return await ApiService.get('factures/stats/overview', queryParams: {'entreprise_id': entrepriseId});
  }

  // Générer un numéro de facture
  Future<String> genererNumeroFacture(String type) async {
    final data = await ApiService.post('factures/generer-numero', {'type': type});
    return data['numero'];
  }

  // Mettre à jour le statut d'une facture
  Future<Facture> updateStatutFacture(int id, double montantPaye) async {
    final data = await ApiService.patch(
      'factures/$id/statut',
      {'montant_paye': montantPaye},
    );
    return Facture.fromMap(data);
  }

  // Récupérer les factures par période
  Future<List<Facture>> getFacturesByPeriode(DateTime debut, DateTime fin) async {
    final debutStr = debut.toIso8601String().split('T')[0];
    final finStr = fin.toIso8601String().split('T')[0];
    
    final List<dynamic> data = await ApiService.get(
      'factures/periode/$debutStr/$finStr',
    );
    return data.map((json) => Facture.fromMap(json)).toList();
  }
}
