import 'package:flutter/material.dart';
import '../../models/declaration_tva.dart';
import '../../services/tva_service.dart';
import '../../utils/formatters.dart';
import 'declaration_tva_form_screen.dart';
import 'declaration_tva_detail_screen.dart';
import 'calculateur_tva_screen.dart';

class TVAListScreen extends StatefulWidget {
  const TVAListScreen({super.key});

  @override
  State<TVAListScreen> createState() => _TVAListScreenState();
}

class _TVAListScreenState extends State<TVAListScreen> {
  final TVAService _tvaService = TVAService();
  List<DeclarationTVA> _declarations = [];
  List<DeclarationTVA> _declarationsFiltered = [];
  bool _isLoading = true;
  String _statutFilter = 'tous';
  Map<String, dynamic>? _statistiques;

  @override
  void initState() {
    super.initState();
    _loadDeclarations();
    _loadStatistiques();
  }

  Future<void> _loadDeclarations() async {
    setState(() => _isLoading = true);
    try {
      final declarations = await _tvaService.getAllDeclarations();
      setState(() {
        _declarations = declarations;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _loadStatistiques() async {
    try {
      final stats = await _tvaService.getStatistiquesTVA();
      setState(() => _statistiques = stats);
    } catch (e) {
      // Ignorer les erreurs de stats
    }
  }

  void _applyFilters() {
    _declarationsFiltered = _declarations.where((declaration) {
      if (_statutFilter != 'tous' && declaration.statut != _statutFilter) {
        return false;
      }
      return true;
    }).toList();

    _declarationsFiltered.sort((a, b) => b.periodeFin.compareTo(a.periodeFin));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion de la TVA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate),
            onPressed: () => _showCalculateur(),
            tooltip: 'Calculateur TVA',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeclarations,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_statistiques != null) _buildStatistiques(),
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _declarationsFiltered.isEmpty
                    ? _buildEmptyState()
                    : _buildDeclarationsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDeclarationForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle déclaration'),
      ),
    );
  }

  Widget _buildStatistiques() {
    final stats = _statistiques!;
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'TVA Collectée',
              AppFormatters.formatMontant(stats['tva_collectee_annee'] ?? 0),
              Icons.arrow_upward,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'TVA Déductible',
              AppFormatters.formatMontant(stats['tva_deductible_annee'] ?? 0),
              Icons.arrow_downward,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'À Décaisser',
              AppFormatters.formatMontant(stats['tva_a_decaisser_annee'] ?? 0),
              Icons.payment,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 20),
          const SizedBox(width: 8),
          const Text('Statut:'),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _statutFilter,
            items: const [
              DropdownMenuItem(value: 'tous', child: Text('Tous')),
              DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
              DropdownMenuItem(value: 'validee', child: Text('Validée')),
              DropdownMenuItem(value: 'transmise', child: Text('Transmise')),
              DropdownMenuItem(value: 'payee', child: Text('Payée')),
            ],
            onChanged: (value) {
              setState(() {
                _statutFilter = value!;
                _applyFilters();
              });
            },
          ),
          const Spacer(),
          Text(
            '${_declarationsFiltered.length} déclaration(s)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildDeclarationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _declarationsFiltered.length,
      itemBuilder: (context, index) {
        return _buildDeclarationCard(_declarationsFiltered[index]);
      },
    );
  }

  Widget _buildDeclarationCard(DeclarationTVA declaration) {
    Color statutColor;
    IconData statutIcon;
    String statutLabel;

    switch (declaration.statut) {
      case 'payee':
        statutColor = Colors.green;
        statutIcon = Icons.check_circle;
        statutLabel = 'Payée';
        break;
      case 'transmise':
        statutColor = Colors.blue;
        statutIcon = Icons.send;
        statutLabel = 'Transmise';
        break;
      case 'validee':
        statutColor = Colors.orange;
        statutIcon = Icons.verified;
        statutLabel = 'Validée';
        break;
      default:
        statutColor = Colors.grey;
        statutIcon = Icons.pending;
        statutLabel = 'En cours';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDeclarationDetail(declaration),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          declaration.libellePeriode,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Créée le ${AppFormatters.formatDate(declaration.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statutColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statutColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statutIcon, size: 16, color: statutColor),
                        const SizedBox(width: 4),
                        Text(
                          statutLabel,
                          style: TextStyle(
                            color: statutColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildMontantInfo(
                      'TVA Collectée',
                      declaration.tvaCollectee,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildMontantInfo(
                      'TVA Déductible',
                      declaration.tvaDeductible,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildMontantInfo(
                      'À Décaisser',
                      declaration.tvaADecaisser,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMontantInfo(String label, double montant, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppFormatters.formatMontant(montant),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune déclaration TVA',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre première déclaration',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCalculateur(),
            icon: const Icon(Icons.calculate),
            label: const Text('Calculer la TVA'),
          ),
        ],
      ),
    );
  }

  void _showDeclarationForm({DeclarationTVA? declaration}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeclarationTVAFormScreen(declaration: declaration),
      ),
    );

    if (result == true) {
      _loadDeclarations();
      _loadStatistiques();
    }
  }

  void _showDeclarationDetail(DeclarationTVA declaration) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeclarationTVADetailScreen(declaration: declaration),
      ),
    );

    if (result == true) {
      _loadDeclarations();
      _loadStatistiques();
    }
  }

  void _showCalculateur() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CalculateurTVAScreen(),
      ),
    );

    if (result == true) {
      _loadDeclarations();
      _loadStatistiques();
    }
  }
}
