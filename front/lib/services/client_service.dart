import '../models/client.dart';
import 'api_service.dart';

class ClientService {
  // Récupérer tous les clients
  Future<List<Client>> getAllClients() async {
    final List<dynamic> data = await ApiService.get('clients');
    return data.map((json) => Client.fromMap(json)).toList();
  }

  // Récupérer uniquement les clients actifs
  Future<List<Client>> getClientsActifs() async {
    final List<dynamic> data = await ApiService.get('clients/actifs');
    return data.map((json) => Client.fromMap(json)).toList();
  }

  // Récupérer un client par ID
  Future<Client?> getClientById(int id) async {
    try {
      final data = await ApiService.get('clients/$id');
      return Client.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  // Créer un nouveau client
  Future<Client> createClient(Client client) async {
    final data = await ApiService.post('clients', client.toMap());
    return Client.fromMap(data);
  }

  // Mettre à jour un client
  Future<Client> updateClient(Client client) async {
    final data = await ApiService.put(
      'clients/${client.id}',
      client.toMap(),
    );
    return Client.fromMap(data);
  }

  // Supprimer un client
  Future<void> deleteClient(int id) async {
    await ApiService.delete('clients/$id');
  }

  // Activer/Désactiver un client
  Future<Client> toggleActif(int id) async {
    final data = await ApiService.patch('clients/$id/toggle-actif', {});
    return Client.fromMap(data);
  }

  // Récupérer les factures d'un client
  Future<List<dynamic>> getFacturesClient(int id) async {
    final List<dynamic> data = await ApiService.get('clients/$id/factures');
    return data;
  }

  // Récupérer les statistiques d'un client
  Future<Map<String, dynamic>> getClientStats(int id) async {
    return await ApiService.get('clients/$id/stats');
  }
}
