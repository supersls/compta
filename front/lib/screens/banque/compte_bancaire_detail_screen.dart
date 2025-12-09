import 'package:flutter/material.dart';
import '../../models/banque.dart';
import '../../services/banque_service.dart';
import '../../utils/formatters.dart';
import 'compte_bancaire_form_screen.dart';
import 'transaction_form_screen.dart';

class CompteBancaireDetailScreen extends StatefulWidget {
  final CompteBancaire compte;

  const CompteBancaireDetailScreen({super.key, required this.compte});

  @override
  State<CompteBancaireDetailScreen> createState() => _CompteBancaireDetailScreenState();
}

class _CompteBancaireDetailScreenState extends State<CompteBancaireDetailScreen> with SingleTickerProviderStateMixin {
  final BanqueService _service = BanqueService();
  late CompteBancaire _compte;
  List<TransactionBancaire> _transactions = [];
  Map<String, dynamic>? _statistiques;
  bool _isLoading = true;
  late TabController _tabController;
  String _filterType = 'toutes';

  @override
  void initState() {
    super.initState();
    _compte = widget.compte;
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final transactions = await _service.getTransactionsByCompte(_compte.id!);
      final statistiques = await _service.getStatistiquesCompte(_compte.id!);
      
      // Recharger le compte pour avoir le solde à jour
      final comptes = await _service.getAllComptes();
      final compteUpdated = comptes.firstWhere((c) => c.id == _compte.id);

      setState(() {
        _compte = compteUpdated;
        _transactions = transactions;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_compte.nom),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editCompte,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'toggle_actif') _toggleActif();
              if (value == 'delete') _deleteCompte();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_actif',
                child: Row(
                  children: [
                    Icon(_compte.actif ? Icons.visibility_off : Icons.visibility),
                    const SizedBox(width: 12),
                    Text(_compte.actif ? 'Désactiver' : 'Activer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Transactions', icon: Icon(Icons.list)),
            Tab(text: 'Statistiques', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCompteHeader(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTransactionsList(),
                      _buildStatistiques(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTransaction,
        icon: const Icon(Icons.add),
        label: const Text('Transaction'),
      ),
    );
  }

  Widget _buildCompteHeader() {
    final isPositif = _compte.soldeActuel >= 0;
    final variation = _compte.variation;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPositif
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: isPositif ? Colors.green : Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _compte.banque,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_compte.numeroCompte != null)
                        Text(
                          _compte.numeroCompte!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Solde actuel'),
                Text(
                  AppFormatters.formatMontant(_compte.soldeActuel),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPositif ? Colors.green : Colors.red,
                      ),
                ),
              ],
            ),
            if (variation != 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Variation'),
                  Row(
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
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Aucune transaction',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _addTransaction,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une transaction'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildTransactionFilters(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredTransactions.length,
            itemBuilder: (context, index) {
              return _buildTransactionCard(_filteredTransactions[index]);
            },
          ),
        ),
      ],
    );
  }

  List<TransactionBancaire> get _filteredTransactions {
    if (_filterType == 'toutes') return _transactions;
    if (_filterType == 'credits') {
      return _transactions.where((t) => t.type == 'credit').toList();
    }
    if (_filterType == 'debits') {
      return _transactions.where((t) => t.type == 'debit').toList();
    }
    if (_filterType == 'non_rapprochees') {
      return _transactions.where((t) => !t.rapproche).toList();
    }
    return _transactions;
  }

  Widget _buildTransactionFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.filter_list, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<String>(
                value: _filterType,
                isExpanded: true,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'toutes', child: Text('Toutes')),
                  DropdownMenuItem(value: 'credits', child: Text('Crédits')),
                  DropdownMenuItem(value: 'debits', child: Text('Débits')),
                  DropdownMenuItem(value: 'non_rapprochees', child: Text('Non rapprochées')),
                ],
                onChanged: (value) {
                  setState(() => _filterType = value!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(TransactionBancaire transaction) {
    final isCredit = transaction.type == 'credit';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editTransaction(transaction),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCredit
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isCredit ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description ?? transaction.libelleCategorie,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          AppFormatters.formatDate(transaction.dateTransaction),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (transaction.categorie != null) ...[
                          const Text(' • ', style: TextStyle(fontSize: 12)),
                          Text(
                            transaction.libelleCategorie,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.formatMontant(transaction.montant),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCredit ? Colors.green : Colors.red,
                      fontSize: 16,
                    ),
                  ),
                  if (transaction.rapproche)
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatistiques() {
    if (_statistiques == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalCredits = (_statistiques!['total_credits'] as num?)?.toDouble() ?? 0;
    final totalDebits = (_statistiques!['total_debits'] as num?)?.toDouble() ?? 0;
    final nbTransactions = (_statistiques!['nombre_transactions'] as num?)?.toInt() ?? 0;
    final nbRapprochees = (_statistiques!['nombre_rapprochees'] as num?)?.toInt() ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total crédits',
                AppFormatters.formatMontant(totalCredits),
                Icons.arrow_downward,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total débits',
                AppFormatters.formatMontant(totalDebits),
                Icons.arrow_upward,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Transactions',
                nbTransactions.toString(),
                Icons.receipt_long,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Rapprochées',
                '$nbRapprochees / $nbTransactions',
                Icons.check_circle,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editCompte() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompteBancaireFormScreen(compte: _compte),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _toggleActif() async {
    try {
      final compteUpdated = _compte.copyWith(actif: !_compte.actif);
      await _service.updateCompte(compteUpdated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_compte.actif ? 'Compte désactivé' : 'Compte activé'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
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

  Future<void> _deleteCompte() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Voulez-vous vraiment supprimer ce compte ? Toutes les transactions seront également supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _service.deleteCompte(_compte.id!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compte supprimé'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
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
  }

  Future<void> _addTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(compteId: _compte.id!),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _editTransaction(TransactionBancaire transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(
          compteId: _compte.id!,
          transaction: transaction,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }
}
