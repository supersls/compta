import 'package:flutter/material.dart';
import '../../models/facture.dart';
import '../../services/facture_service.dart';
import '../../utils/formatters.dart';
import '../../utils/constants.dart';
import 'facture_form_screen.dart';
import 'facture_detail_screen.dart';

class FacturesListScreen extends StatefulWidget {
  const FacturesListScreen({super.key});

  @override
  State<FacturesListScreen> createState() => _FacturesListScreenState();
}

class _FacturesListScreenState extends State<FacturesListScreen> {
  final FactureService _factureService = FactureService();
  List<Facture> _factures = [];
  List<Facture> _facturesFiltered = [];
  bool _isLoading = true;
  String _typeFilter = 'tous';
  String _statutFilter = 'tous';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFactures();
  }

  Future<void> _loadFactures() async {
    setState(() => _isLoading = true);
    try {
      final factures = await _factureService.getAllFactures();
      setState(() {
        _factures = factures;
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

  void _applyFilters() {
    _facturesFiltered = _factures.where((facture) {
      // Filtre par type
      if (_typeFilter != 'tous' && facture.type != _typeFilter) {
        return false;
      }
      
      // Filtre par statut
      if (_statutFilter != 'tous' && facture.statut != _statutFilter) {
        return false;
      }
      
      // Filtre par recherche
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return facture.numero.toLowerCase().contains(query) ||
               facture.clientFournisseur.toLowerCase().contains(query) ||
               (facture.notes?.toLowerCase().contains(query) ?? false);
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _facturesFiltered.isEmpty
                    ? _buildEmptyState()
                    : _buildFacturesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFactureForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle facture'),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher une facture...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
          ),
          const SizedBox(height: 16),
          // Filtres
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _typeFilter,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'tous', child: Text('Tous')),
                    DropdownMenuItem(value: 'vente', child: Text('Ventes')),
                    DropdownMenuItem(value: 'achat', child: Text('Achats')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _typeFilter = value!;
                      _applyFilters();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _statutFilter,
                  decoration: const InputDecoration(
                    labelText: 'Statut',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'tous', child: Text('Tous')),
                    DropdownMenuItem(value: 'en_attente', child: Text('En attente')),
                    DropdownMenuItem(value: 'payee', child: Text('Payée')),
                    DropdownMenuItem(value: 'partiellement_payee', child: Text('Partiellement payée')),
                    DropdownMenuItem(value: 'en_retard', child: Text('En retard')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _statutFilter = value!;
                      _applyFilters();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Compteur
          Row(
            children: [
              Text(
                '${_facturesFiltered.length} facture(s)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _typeFilter = 'tous';
                    _statutFilter = 'tous';
                    _searchQuery = '';
                    _applyFilters();
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Réinitialiser'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFacturesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _facturesFiltered.length,
      itemBuilder: (context, index) {
        final facture = _facturesFiltered[index];
        return _buildFactureCard(facture);
      },
    );
  }

  Widget _buildFactureCard(Facture facture) {
    Color statutColor;
    IconData statutIcon;
    
    switch (facture.statut) {
      case 'payee':
        statutColor = Colors.green;
        statutIcon = Icons.check_circle;
        break;
      case 'partiellement_payee':
        statutColor = Colors.orange;
        statutIcon = Icons.timelapse;
        break;
      case 'en_retard':
        statutColor = Colors.red;
        statutIcon = Icons.warning;
        break;
      default:
        statutColor = Colors.grey;
        statutIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showFactureDetail(facture),
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
                          facture.numero,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          facture.clientFournisseur,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppFormatters.formatMontant(facture.montantTTC),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: facture.type == 'vente' 
                              ? Colors.green 
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statutIcon, size: 16, color: statutColor),
                            const SizedBox(width: 4),
                            Text(
                              _getStatutLabel(facture.statut),
                              style: TextStyle(
                                color: statutColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: statutColor.withOpacity(0.1),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    facture.type == 'vente' 
                        ? Icons.arrow_upward 
                        : Icons.arrow_downward,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    facture.type == 'vente' ? 'Vente' : 'Achat',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    AppFormatters.formatDate(facture.dateEmission),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  if (facture.dateEcheance != null) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.event, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Échéance: ${AppFormatters.formatDate(facture.dateEcheance!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: facture.estEnRetard ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
              if (facture.resteAPayer > 0 && facture.statut != 'payee') ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: facture.montantPaye / facture.montantTTC,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    facture.estEnRetard ? Colors.red : Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reste à payer: ${AppFormatters.formatMontant(facture.resteAPayer)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: facture.estEnRetard ? Colors.red : Colors.grey,
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
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune facture',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre première facture',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showFactureForm(),
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle facture'),
          ),
        ],
      ),
    );
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'payee':
        return 'Payée';
      case 'partiellement_payee':
        return 'Partielle';
      case 'en_retard':
        return 'En retard';
      default:
        return 'En attente';
    }
  }

  void _showFactureForm({Facture? facture}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FactureFormScreen(facture: facture),
      ),
    );
    
    if (result == true) {
      _loadFactures();
    }
  }

  void _showFactureDetail(Facture facture) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FactureDetailScreen(facture: facture),
      ),
    );
    
    if (result == true) {
      _loadFactures();
    }
  }
}
