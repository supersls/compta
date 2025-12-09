import 'package:flutter/material.dart';
import '../../models/immobilisation.dart';
import '../../services/immobilisation_service.dart';
import '../../utils/formatters.dart';
import 'immobilisation_form_screen.dart';

class ImmobilisationDetailScreen extends StatefulWidget {
  final Immobilisation immobilisation;

  const ImmobilisationDetailScreen({super.key, required this.immobilisation});

  @override
  State<ImmobilisationDetailScreen> createState() => _ImmobilisationDetailScreenState();
}

class _ImmobilisationDetailScreenState extends State<ImmobilisationDetailScreen> {
  final ImmobilisationService _service = ImmobilisationService();
  late Immobilisation _immobilisation;
  List<Map<String, dynamic>> _planAmortissement = [];
  List<Map<String, dynamic>> _amortissements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _immobilisation = widget.immobilisation;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final plan = _service.calculerPlanAmortissement(_immobilisation);
      final amortissements = await _service.getAmortissementsByImmobilisation(
        _immobilisation.id!,
      );

      setState(() {
        _planAmortissement = plan;
        _amortissements = amortissements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_immobilisation.libelle),
        actions: [
          if (!_immobilisation.estCedee) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _edit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _delete,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInfoCard(),
                const SizedBox(height: 16),
                _buildAmortissementCard(),
                const SizedBox(height: 16),
                _buildPlanAmortissementCard(),
                const SizedBox(height: 16),
                if (!_immobilisation.estCedee) _buildActionsCard(),
                const SizedBox(height: 100),
              ],
            ),
    );
  }

  Widget _buildInfoCard() {
    final isCedee = _immobilisation.estCedee;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: _getTypeColor(),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _immobilisation.libelle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        _getTypeLabel(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (isCedee)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'CÉDÉE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow('Date d\'acquisition', AppFormatters.formatDate(_immobilisation.dateAcquisition)),
            const SizedBox(height: 12),
            _buildInfoRow('Valeur d\'acquisition', AppFormatters.formatMontant(_immobilisation.valeurAcquisition)),
            const SizedBox(height: 12),
            _buildInfoRow('Valeur nette comptable', AppFormatters.formatMontant(_immobilisation.valeurResiduelle)),
            const SizedBox(height: 12),
            _buildInfoRow('Durée d\'amortissement', '${_immobilisation.dureeAmortissement} ans'),
            const SizedBox(height: 12),
            _buildInfoRow('Méthode', _immobilisation.methodeAmortissement == 'lineaire' ? 'Linéaire' : 'Dégressif'),
            const SizedBox(height: 12),
            _buildInfoRow('Taux', '${_immobilisation.tauxAmortissementCalcule.toStringAsFixed(2)}%'),
            if (isCedee) ...[
              const Divider(height: 32),
              _buildInfoRow('Date de cession', AppFormatters.formatDate(_immobilisation.dateCession!)),
            ],
            if (_immobilisation.notes != null && _immobilisation.notes!.isNotEmpty) ...[
              const Divider(height: 32),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(_immobilisation.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildAmortissementCard() {
    final pourcentage = _immobilisation.pourcentageAmorti;
    final totalAmorti = _immobilisation.totalAmorti;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'État d\'amortissement',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total amorti'),
                Text(
                  AppFormatters.formatMontant(totalAmorti),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Progression'),
                Text(
                  '${pourcentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: pourcentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_getTypeColor()),
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_immobilisation.anneesRestantes} année(s) restante(s)',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildPlanAmortissementCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan d\'amortissement',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  Theme.of(context).colorScheme.surfaceVariant,
                ),
                columns: const [
                  DataColumn(label: Text('Année')),
                  DataColumn(label: Text('Dotation')),
                  DataColumn(label: Text('Cumul')),
                  DataColumn(label: Text('VNC')),
                  DataColumn(label: Text('Statut')),
                ],
                rows: _planAmortissement.map((row) {
                  final annee = row['annee'] as int;
                  final isComptabilise = _amortissements.any(
                    (a) => a['annee'] == annee,
                  );

                  return DataRow(
                    cells: [
                      DataCell(Text(annee.toString())),
                      DataCell(Text(AppFormatters.formatMontant(row['dotation']))),
                      DataCell(Text(AppFormatters.formatMontant(row['cumul']))),
                      DataCell(Text(AppFormatters.formatMontant(row['vnc']))),
                      DataCell(
                        isComptabilise
                            ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                            : const Icon(Icons.pending, color: Colors.grey, size: 20),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calculate),
                label: const Text('Enregistrer un amortissement'),
                onPressed: _enregistrerAmortissement,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Céder l\'immobilisation'),
                onPressed: _ceder,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (_immobilisation.type) {
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

  IconData _getTypeIcon() {
    switch (_immobilisation.type) {
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

  String _getTypeLabel() {
    switch (_immobilisation.type) {
      case 'materiel':
        return 'Matériel';
      case 'vehicule':
        return 'Véhicule';
      case 'logiciel':
        return 'Logiciel';
      case 'immobilier':
        return 'Immobilier';
      default:
        return _immobilisation.type;
    }
  }

  Future<void> _edit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImmobilisationFormScreen(
          immobilisation: _immobilisation,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Voulez-vous vraiment supprimer cette immobilisation ? Cette action est irréversible.',
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
        await _service.deleteImmobilisation(_immobilisation.id!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Immobilisation supprimée'),
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

  Future<void> _enregistrerAmortissement() async {
    final anneeController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enregistrer un amortissement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pour quelle année souhaitez-vous enregistrer l\'amortissement ?'),
            const SizedBox(height: 16),
            TextField(
              controller: anneeController,
              decoration: const InputDecoration(
                labelText: 'Année',
                hintText: '2024',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final annee = int.tryParse(anneeController.text);
      if (annee == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Année invalide'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        final calcul = await _service.calculerAmortissement(
          _immobilisation.id!,
          annee,
        );

        await _service.createAmortissement(calcul);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Amortissement enregistré'),
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
  }

  Future<void> _ceder() async {
    final dateController = TextEditingController();
    final prixController = TextEditingController();
    DateTime dateCession = DateTime.now();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Céder l\'immobilisation'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date de cession'),
                subtitle: Text(AppFormatters.formatDate(dateCession)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: dateCession,
                    firstDate: _immobilisation.dateAcquisition,
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => dateCession = date);
                  }
                },
              ),
              TextField(
                controller: prixController,
                decoration: const InputDecoration(
                  labelText: 'Prix de cession (optionnel)',
                  suffix: Text('€'),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Céder'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final prix = prixController.text.isNotEmpty
            ? double.tryParse(prixController.text) ?? 0
            : 0;

        await _service.cederImmobilisation(
          _immobilisation.id!,
          dateCession,
          prix,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Immobilisation cédée'),
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
}
