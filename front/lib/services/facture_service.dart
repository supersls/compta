import 'package:sqflite/sqflite.dart';
import '../models/facture.dart';
import 'database_helper.dart';

class FactureService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Créer une nouvelle facture
  Future<int> createFacture(Facture facture) async {
    final db = await _dbHelper.database;
    return await db.insert('factures', facture.toMap());
  }

  // Récupérer toutes les factures
  Future<List<Facture>> getAllFactures() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'factures',
      orderBy: 'date_emission DESC',
    );
    return List.generate(maps.length, (i) => Facture.fromMap(maps[i]));
  }

  // Récupérer les factures par type
  Future<List<Facture>> getFacturesByType(String type) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'factures',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date_emission DESC',
    );
    return List.generate(maps.length, (i) => Facture.fromMap(maps[i]));
  }

  // Récupérer les factures par statut
  Future<List<Facture>> getFacturesByStatut(String statut) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'factures',
      where: 'statut = ?',
      whereArgs: [statut],
      orderBy: 'date_emission DESC',
    );
    return List.generate(maps.length, (i) => Facture.fromMap(maps[i]));
  }

  // Récupérer une facture par ID
  Future<Facture?> getFactureById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'factures',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Facture.fromMap(maps.first);
  }

  // Récupérer une facture par numéro
  Future<Facture?> getFactureByNumero(String numero) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'factures',
      where: 'numero = ?',
      whereArgs: [numero],
    );
    if (maps.isEmpty) return null;
    return Facture.fromMap(maps.first);
  }

  // Mettre à jour une facture
  Future<int> updateFacture(Facture facture) async {
    final db = await _dbHelper.database;
    return await db.update(
      'factures',
      facture.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [facture.id],
    );
  }

  // Supprimer une facture
  Future<int> deleteFacture(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'factures',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Rechercher des factures
  Future<List<Facture>> searchFactures(String query) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'factures',
      where: 'numero LIKE ? OR client_fournisseur LIKE ? OR notes LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'date_emission DESC',
    );
    return List.generate(maps.length, (i) => Facture.fromMap(maps[i]));
  }

  // Récupérer les factures en retard
  Future<List<Facture>> getFacturesEnRetard() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> maps = await db.query(
      'factures',
      where: 'date_echeance < ? AND statut != ?',
      whereArgs: [now, 'payee'],
      orderBy: 'date_echeance ASC',
    );
    return List.generate(maps.length, (i) => Facture.fromMap(maps[i]));
  }

  // Récupérer les statistiques des factures
  Future<Map<String, dynamic>> getFacturesStats() async {
    final db = await _dbHelper.database;
    
    // Total ventes
    final ventesResult = await db.rawQuery(
      'SELECT SUM(montant_ttc) as total FROM factures WHERE type = ?',
      ['vente'],
    );
    final totalVentes = ventesResult.first['total'] ?? 0.0;

    // Total achats
    final achatsResult = await db.rawQuery(
      'SELECT SUM(montant_ttc) as total FROM factures WHERE type = ?',
      ['achat'],
    );
    final totalAchats = achatsResult.first['total'] ?? 0.0;

    // Factures impayées
    final impayeesResult = await db.rawQuery(
      'SELECT COUNT(*) as count, SUM(montant_ttc - montant_paye) as total FROM factures WHERE statut != ?',
      ['payee'],
    );
    final countImpayees = impayeesResult.first['count'] ?? 0;
    final totalImpayees = impayeesResult.first['total'] ?? 0.0;

    // Factures en retard
    final now = DateTime.now().toIso8601String();
    final retardResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM factures WHERE date_echeance < ? AND statut != ?',
      [now, 'payee'],
    );
    final countRetard = retardResult.first['count'] ?? 0;

    return {
      'totalVentes': totalVentes,
      'totalAchats': totalAchats,
      'totalImpayees': totalImpayees,
      'countImpayees': countImpayees,
      'countRetard': countRetard,
    };
  }

  // Générer le prochain numéro de facture
  Future<String> genererNumeroFacture(String type) async {
    final db = await _dbHelper.database;
    final annee = DateTime.now().year;
    final prefix = type == 'vente' ? 'FAC' : 'ACH';
    
    final result = await db.rawQuery(
      'SELECT MAX(CAST(SUBSTR(numero, -4) AS INTEGER)) as max_num FROM factures WHERE numero LIKE ?',
      ['$prefix-$annee-%'],
    );
    
    final maxNum = result.first['max_num'];
    final nextNum = maxNum != null ? (maxNum as int) + 1 : 1;
    
    return '$prefix-$annee-${nextNum.toString().padLeft(4, '0')}';
  }

  // Mettre à jour le statut d'une facture
  Future<void> updateStatutFacture(int id) async {
    final facture = await getFactureById(id);
    if (facture == null) return;

    String nouveauStatut;
    if (facture.montantPaye >= facture.montantTTC) {
      nouveauStatut = 'payee';
    } else if (facture.montantPaye > 0) {
      nouveauStatut = 'partiellement_payee';
    } else if (facture.estEnRetard) {
      nouveauStatut = 'en_retard';
    } else {
      nouveauStatut = 'en_attente';
    }

    if (nouveauStatut != facture.statut) {
      await updateFacture(facture.copyWith(statut: nouveauStatut));
    }
  }

  // Récupérer les factures par période
  Future<List<Facture>> getFacturesByPeriode(DateTime debut, DateTime fin, {String? type}) async {
    final db = await _dbHelper.database;
    
    String where = 'date_emission BETWEEN ? AND ?';
    List<dynamic> whereArgs = [debut.toIso8601String(), fin.toIso8601String()];
    
    if (type != null) {
      where += ' AND type = ?';
      whereArgs.add(type);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'factures',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date_emission DESC',
    );
    
    return List.generate(maps.length, (i) => Facture.fromMap(maps[i]));
  }
}
