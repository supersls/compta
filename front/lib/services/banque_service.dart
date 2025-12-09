import '../services/api_service.dart';
import '../models/banque.dart';

class BanqueService {
  // ============ COMPTES BANCAIRES ============

  // GET tous les comptes
  Future<List<CompteBancaire>> getAllComptes() async {
    final data = await ApiService.get('banque/comptes');
    return (data as List).map((item) => CompteBancaire.fromMap(item)).toList();
  }

  // POST créer compte
  Future<CompteBancaire> createCompte(CompteBancaire compte) async {
    final data = await ApiService.post('banque/comptes', compte.toMap());
    return CompteBancaire.fromMap(data);
  }

  // PUT modifier compte
  Future<CompteBancaire> updateCompte(CompteBancaire compte) async {
    final data = await ApiService.put('banque/comptes/${compte.id}', compte.toMap());
    return CompteBancaire.fromMap(data);
  }

  // DELETE supprimer compte
  Future<void> deleteCompte(int id) async {
    await ApiService.delete('banque/comptes/$id');
  }

  // ============ TRANSACTIONS ============

  // GET toutes les transactions
  Future<List<TransactionBancaire>> getAllTransactions() async {
    final data = await ApiService.get('banque/transactions');
    return (data as List).map((item) => TransactionBancaire.fromMap(item)).toList();
  }

  // GET transactions par compte
  Future<List<TransactionBancaire>> getTransactionsByCompte(int compteId) async {
    final data = await ApiService.get('banque/comptes/$compteId/transactions');
    return (data as List).map((item) => TransactionBancaire.fromMap(item)).toList();
  }

  // POST créer transaction
  Future<TransactionBancaire> createTransaction(TransactionBancaire transaction) async {
    final data = await ApiService.post('banque/transactions', transaction.toMap());
    return TransactionBancaire.fromMap(data);
  }

  // PUT modifier transaction
  Future<TransactionBancaire> updateTransaction(TransactionBancaire transaction) async {
    final data = await ApiService.put(
      'banque/transactions/${transaction.id}',
      transaction.toMap(),
    );
    return TransactionBancaire.fromMap(data);
  }

  // DELETE supprimer transaction
  Future<void> deleteTransaction(int id) async {
    await ApiService.delete('banque/transactions/$id');
  }

  // PATCH rapprocher transaction
  Future<TransactionBancaire> rapprocherTransaction(int id) async {
    final data = await ApiService.patch('banque/transactions/$id/rapprocher', {});
    return TransactionBancaire.fromMap(data);
  }

  // ============ RAPPROCHEMENT ============

  // GET transactions non rapprochées
  Future<List<TransactionBancaire>> getTransactionsNonRapprochees(int compteId) async {
    final data = await ApiService.get('banque/comptes/$compteId/non-rapprochees');
    return (data as List).map((item) => TransactionBancaire.fromMap(item)).toList();
  }

  // POST rapprochement multiple
  Future<void> rapprocherMultiple(List<int> transactionIds) async {
    await ApiService.post('banque/rapprochement/multiple', {
      'transaction_ids': transactionIds,
    });
  }

  // ============ STATISTIQUES ============

  // GET statistiques globales
  Future<Map<String, dynamic>> getStatistiques() async {
    return await ApiService.get('banque/statistiques');
  }

  // GET statistiques par compte
  Future<Map<String, dynamic>> getStatistiquesCompte(int compteId) async {
    return await ApiService.get('banque/comptes/$compteId/statistiques');
  }

  // GET évolution du solde
  Future<List<Map<String, dynamic>>> getEvolutionSolde(
    int compteId,
    DateTime debut,
    DateTime fin,
  ) async {
    final debutStr = debut.toIso8601String().split('T')[0];
    final finStr = fin.toIso8601String().split('T')[0];
    final data = await ApiService.get('banque/comptes/$compteId/evolution/$debutStr/$finStr');
    return List<Map<String, dynamic>>.from(data);
  }

  // GET transactions par catégorie
  Future<Map<String, dynamic>> getParCategorie(int compteId, DateTime debut, DateTime fin) async {
    final debutStr = debut.toIso8601String().split('T')[0];
    final finStr = fin.toIso8601String().split('T')[0];
    return await ApiService.get('banque/comptes/$compteId/par-categorie/$debutStr/$finStr');
  }

  // ============ VIREMENT ============

  // POST créer virement entre comptes
  Future<Map<String, dynamic>> creerVirement(
    int compteSourceId,
    int compteDestinationId,
    double montant,
    DateTime date,
    String? description,
  ) async {
    return await ApiService.post('banque/virement', {
      'compte_source_id': compteSourceId,
      'compte_destination_id': compteDestinationId,
      'montant': montant,
      'date': date.toIso8601String().split('T')[0],
      'description': description,
    });
  }

  // ============ IMPORT ============

  // POST import transactions CSV
  Future<Map<String, dynamic>> importTransactions(
    int compteId,
    String csvContent,
  ) async {
    return await ApiService.post('banque/comptes/$compteId/import', {
      'csv_content': csvContent,
    });
  }
}
