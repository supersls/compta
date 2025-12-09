import 'package:flutter/material.dart';
import '../../models/facture.dart';
import '../../services/facture_service_http.dart';
import '../../utils/formatters.dart';
import 'facture_form_screen.dart';

class FactureDetailScreen extends StatefulWidget {
  final Facture facture;

  const FactureDetailScreen({super.key, required this.facture});

  @override
  State<FactureDetailScreen> createState() => _FactureDetailScreenState();
}

class _FactureDetailScreenState extends State<FactureDetailScreen> {
  final FactureService _factureService = FactureService();
  late Facture _facture;

  @override
  void initState() {
    super.initState();
    _facture = widget.facture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_facture.numero),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editFacture,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteFacture,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 16),
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildMontantsCard(),
          const SizedBox(height: 16),
          _buildDatesCard(),
          if (_facture.notes != null) ...[
            const SizedBox(height: 16),
            _buildNotesCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    Color statutColor;
    IconData statutIcon;
    String statutLabel;
    
    switch (_facture.statut) {
      case 'payee':
        statutColor = Colors.green;
        statutIcon = Icons.check_circle;
        statutLabel = 'Payée';
        break;
      case 'partiellement_payee':
        statutColor = Colors.orange;
        statutIcon = Icons.timelapse;
        statutLabel = 'Partiellement payée';
        break;
      case 'en_retard':
        statutColor = Colors.red;
        statutIcon = Icons.warning;
        statutLabel = 'En retard';
        break;
      default:
        statutColor = Colors.grey;
        statutIcon = Icons.schedule;
        statutLabel = 'En attente';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _facture.type == 'vente' ? 'VENTE' : 'ACHAT',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _facture.numero,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statutColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statutIcon, size: 20, color: statutColor),
                      const SizedBox(width: 8),
                      Text(
                        statutLabel,
                        style: TextStyle(
                          color: statutColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              AppFormatters.formatMontant(_facture.montantTTC),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _facture.type == 'vente' ? Colors.green : Colors.red,
              ),
            ),
            if (_facture.resteAPayer > 0 && _facture.statut != 'payee') ...[
              const SizedBox(height: 16),
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _facture.montantPaye / _facture.montantTTC,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _facture.estEnRetard ? Colors.red : Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payé: ${AppFormatters.formatMontant(_facture.montantPaye)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Reste: ${AppFormatters.formatMontant(_facture.resteAPayer)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _facture.estEnRetard ? Colors.red : null,
                          fontWeight: FontWeight.w600,
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

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.person,
              _facture.type == 'vente' ? 'Client' : 'Fournisseur',
              _facture.clientFournisseur,
            ),
            if (_facture.siretClient != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.business,
                'SIRET',
                AppFormatters.formatSIRET(_facture.siretClient!),
              ),
            ],
            if (_facture.categorie != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.category,
                'Catégorie',
                _getCategorieLabel(_facture.categorie!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMontantsCard() {
    final tauxTVA = _facture.montantHT > 0 
        ? (_facture.montantTVA / _facture.montantHT * 100) 
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détail des montants',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMontantRow('Montant HT', _facture.montantHT),
            const SizedBox(height: 8),
            _buildMontantRow(
              'TVA (${tauxTVA.toStringAsFixed(1)}%)',
              _facture.montantTVA,
            ),
            const Divider(height: 24),
            _buildMontantRow(
              'Montant TTC',
              _facture.montantTTC,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dates',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_today,
              'Date d\'émission',
              AppFormatters.formatDate(_facture.dateEmission),
            ),
            if (_facture.dateEcheance != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.event,
                'Date d\'échéance',
                AppFormatters.formatDate(_facture.dateEcheance!),
                color: _facture.estEnRetard ? Colors.red : null,
              ),
            ],
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.access_time,
              'Créée le',
              AppFormatters.formatDateTime(_facture.createdAt),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.update,
              'Modifiée le',
              AppFormatters.formatDateTime(_facture.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _facture.notes!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: color != null ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMontantRow(String label, double montant, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )
              : Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          AppFormatters.formatMontant(montant),
          style: isTotal
              ? Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )
              : Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  String _getCategorieLabel(String categorie) {
    switch (categorie) {
      case 'ventes_marchandises':
        return 'Ventes de marchandises';
      case 'prestations_services':
        return 'Prestations de services';
      case 'achats':
        return 'Achats';
      case 'charges':
        return 'Charges';
      default:
        return categorie;
    }
  }

  void _editFacture() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FactureFormScreen(facture: _facture),
      ),
    );
    
    if (result == true) {
      final updatedFacture = await _factureService.getFactureById(_facture.id!);
      if (updatedFacture != null && mounted) {
        setState(() => _facture = updatedFacture);
      }
    }
  }

  void _deleteFacture() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la facture'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette facture ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _factureService.deleteFacture(_facture.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Facture supprimée'),
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
