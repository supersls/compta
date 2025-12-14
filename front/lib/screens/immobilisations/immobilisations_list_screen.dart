import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/immobilisation.dart';
import '../../services/immobilisation_service.dart';
import '../../utils/formatters.dart';
import '../../providers/entreprise_provider.dart';
import 'immobilisation_form_screen.dart';
import 'immobilisation_detail_screen.dart';

class ImmobilisationsListScreen extends StatefulWidget {
  const ImmobilisationsListScreen({super.key});

  @override
  State<ImmobilisationsListScreen> createState() => _ImmobilisationsListScreenState();
}

class _ImmobilisationsListScreenState extends State<ImmobilisationsListScreen> {
  final ImmobilisationService _service = ImmobilisationService();
  List<Immobilisation> _immobilisations = [];
  Map<String, dynamic>? _statistiques;
  bool _isLoading = true;
  String _categorieFilter = 'toutes';

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
      final immobilisations = await _service.getAllImmobilisations(entrepriseId);
      final statistiques = await _service.getStatistiques(entrepriseId);

      setState(() {
        _immobilisations = immobilisations;
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _immobilisations.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_statistiques != null) _buildStatistiques(),
                        const SizedBox(height: 16),
                        _buildFilters(),
                        const SizedBox(height: 16),
                        ..._filteredImmobilisations.map(_buildImmobilisationCard),
                        const SizedBox(height: 80),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addImmobilisation,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle immobilisation'),
      ),
    );
  }

  List<Immobilisation> get _filteredImmobilisations {
    if (_categorieFilter == 'toutes') return _immobilisations;
    if (_categorieFilter == 'cedees') {
      return _immobilisations.where((i) => i.dateCession != null).toList();
    }
    if (_categorieFilter == 'actives') {
      return _immobilisations.where((i) => i.dateCession == null).toList();
    }
    return _immobilisations.where((i) => i.type == _categorieFilter).toList();
  }

  Widget _buildStatistiques() {
    final totalAcquisition = (_statistiques!['total_acquisition'] as num?)?.toDouble() ?? 0;
    final totalVnc = (_statistiques!['total_vnc'] as num?)?.toDouble() ?? 0;
    final totalAmorti = (_statistiques!['total_amorti'] as num?)?.toDouble() ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Valeur d\'acquisition',
                AppFormatters.formatMontant(totalAcquisition),
                Icons.shopping_cart,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Valeur nette',
                AppFormatters.formatMontant(totalVnc),
                Icons.account_balance,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Total amorti',
          AppFormatters.formatMontant(totalAmorti),
          Icons.trending_down,
          Colors.orange,
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
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.filter_list, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<String>(
                value: _categorieFilter,
                isExpanded: true,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'toutes', child: Text('Toutes')),
                  DropdownMenuItem(value: 'actives', child: Text('Actives')),
                  DropdownMenuItem(value: 'cedees', child: Text('Cédées')),
                  DropdownMenuItem(value: 'materiel', child: Text('Matériel')),
                  DropdownMenuItem(value: 'vehicule', child: Text('Véhicules')),
                  DropdownMenuItem(value: 'logiciel', child: Text('Logiciels')),
                  DropdownMenuItem(value: 'immobilier', child: Text('Immobilier')),
                ],
                onChanged: (value) {
                  setState(() => _categorieFilter = value!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImmobilisationCard(Immobilisation immo) {
    final pourcentageAmorti = immo.pourcentageAmorti;
    final isCedee = immo.dateCession != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewDetail(immo),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getTypeColor(immo.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(immo.type),
                      color: _getTypeColor(immo.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          immo.libelle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          _getTypeLabel(immo.type),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (isCedee)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Cédée',
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
                children: [
                  Expanded(
                    child: _buildInfoColumn(
                      'Acquisition',
                      AppFormatters.formatMontant(immo.valeurAcquisition),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      'VNC',
                      AppFormatters.formatMontant(immo.valeurResiduelle),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      'Durée',
                      '${immo.dureeAmortissement} ans',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amortissement',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${pourcentageAmorti.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: pourcentageAmorti / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getTypeColor(immo.type),
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

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
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
          Icon(
            Icons.business_center_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune immobilisation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre première immobilisation',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _addImmobilisation,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une immobilisation'),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'materiel':
        return Colors.blue;
      case 'vehicule':
        return Colors.green;
      case 'logiciel':
        return Colors.purple;
      case 'immobilier':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'materiel':
        return Icons.computer;
      case 'vehicule':
        return Icons.directions_car;
      case 'logiciel':
        return Icons.code;
      case 'immobilier':
        return Icons.home;
      default:
        return Icons.business_center;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'materiel':
        return 'Matériel';
      case 'vehicule':
        return 'Véhicule';
      case 'logiciel':
        return 'Logiciel';
      case 'immobilier':
        return 'Immobilier';
      default:
        return type;
    }
  }

  Future<void> _addImmobilisation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ImmobilisationFormScreen(),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _viewDetail(Immobilisation immo) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImmobilisationDetailScreen(immobilisation: immo),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }
}
