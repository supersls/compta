import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/banque.dart';
import '../../services/banque_service.dart';
import '../../utils/formatters.dart';
import '../../providers/entreprise_provider.dart';
import 'compte_bancaire_form_screen.dart';
import 'compte_bancaire_detail_screen.dart';

class BanqueListScreen extends StatefulWidget {
  const BanqueListScreen({super.key});

  @override
  State<BanqueListScreen> createState() => _BanqueListScreenState();
}

class _BanqueListScreenState extends State<BanqueListScreen> {
  final BanqueService _service = BanqueService();
  List<CompteBancaire> _comptes = [];
  Map<String, dynamic>? _statistiques;
  bool _isLoading = true;
  bool _showInactifs = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final entrepriseId = Provider.of<EntrepriseProvider>(context, listen: false).selectedEntreprise?.id;
      if (entrepriseId == null) {
        throw Exception('Aucune entreprise sélectionnée');
      }
      final comptes = await _service.getAllComptes(entrepriseId);
      final statistiques = await _service.getStatistiques(entrepriseId);

      setState(() {
        _comptes = comptes;
        _statistiques = statistiques;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _comptes.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_statistiques != null) _buildStatistiques(),
                        const SizedBox(height: 16),
                        _buildFilters(),
                        const SizedBox(height: 16),
                        ..._filteredComptes.map(_buildCompteCard),
                        const SizedBox(height: 80),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCompte,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau compte'),
      ),
    );
  }

  List<CompteBancaire> get _filteredComptes {
    if (_showInactifs) return _comptes;
    return _comptes.where((c) => c.actif).toList();
  }

  Widget _buildStatistiques() {
    final soldeTotal = _parseDouble(_statistiques!['solde_total']) ?? 
                       _parseDouble(_statistiques!['totalTresorerie']) ?? 0.0;
    final nbComptes = _parseInt(_statistiques!['nombre_comptes']) ?? 
                      _parseInt(_statistiques!['totalComptes']) ?? 0;
    final nbTransactions = _parseInt(_statistiques!['nombre_transactions']) ?? 0;

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Solde total',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  AppFormatters.formatMontant(soldeTotal),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: soldeTotal >= 0 ? Colors.green : Colors.red,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                'Comptes',
                nbComptes.toString(),
                Icons.account_balance,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniStatCard(
                'Transactions',
                nbTransactions.toString(),
                Icons.receipt_long,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.filter_list, size: 20),
            const SizedBox(width: 12),
            const Text('Afficher les comptes inactifs'),
            const Spacer(),
            Switch(
              value: _showInactifs,
              onChanged: (value) {
                setState(() => _showInactifs = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompteCard(CompteBancaire compte) {
    final isPositif = compte.soldeActuel >= 0;
    final variation = compte.variation;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewDetail(compte),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isPositif
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_balance,
                      color: isPositif ? Colors.green : Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          compte.nom,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          compte.banque,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (!compte.actif)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Inactif',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Solde actuel',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppFormatters.formatMontant(compte.soldeActuel),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isPositif ? Colors.green : Colors.red,
                            ),
                      ),
                    ],
                  ),
                  if (variation != 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: variation > 0
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            variation > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                            color: variation > 0 ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppFormatters.formatMontant(variation.abs()),
                            style: TextStyle(
                              color: variation > 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (compte.iban != null && compte.iban!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          compte.ibanFormate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun compte bancaire',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre premier compte bancaire',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _addCompte,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un compte'),
          ),
        ],
      ),
    );
  }

  Future<void> _addCompte() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompteBancaireFormScreen(),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _viewDetail(CompteBancaire compte) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompteBancaireDetailScreen(compte: compte),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }
}
