import 'package:flutter/material.dart';
import '../../models/declaration_tva.dart';
import '../../services/tva_service.dart';
import '../../utils/formatters.dart';
import 'declaration_tva_form_screen.dart';

class DeclarationTVADetailScreen extends StatefulWidget {
  final DeclarationTVA declaration;

  const DeclarationTVADetailScreen({super.key, required this.declaration});

  @override
  State<DeclarationTVADetailScreen> createState() => _DeclarationTVADetailScreenState();
}

class _DeclarationTVADetailScreenState extends State<DeclarationTVADetailScreen> {
  final TVAService _tvaService = TVAService();
  late DeclarationTVA _declaration;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _declaration = widget.declaration;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Déclaration ${_declaration.libellePeriode}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatutCard(),
                const SizedBox(height: 16),
                _buildPeriodeCard(),
                const SizedBox(height: 16),
                _buildMontantsCard(),
                const SizedBox(height: 16),
                if (_declaration.notes != null && _declaration.notes!.isNotEmpty)
                  _buildNotesCard(),
                const SizedBox(height: 16),
                _buildDatesCard(),
                const SizedBox(height: 16),
                _buildActionsCard(),
                const SizedBox(height: 100),
              ],
            ),
    );
  }

  Widget _buildStatutCard() {
    Color statutColor;
    IconData statutIcon;
    String statutLabel;

    switch (_declaration.statut) {
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
      case 'brouillon':
        statutColor = Colors.grey;
        statutIcon = Icons.edit;
        statutLabel = 'Brouillon';
        break;
      default:
        statutColor = Colors.grey;
        statutIcon = Icons.pending;
        statutLabel = _declaration.statut;
    }

    return Card(
      color: statutColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statutIcon, color: statutColor, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statut',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    statutLabel,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: statutColor,
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

  Widget _buildPeriodeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Du ${AppFormatters.formatDate(_declaration.periodeDebut)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Au ${AppFormatters.formatDate(_declaration.periodeFin)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMontantsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Montants',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildMontantRow(
              'TVA Collectée',
              _declaration.tvaCollectee,
              Colors.green,
              Icons.arrow_upward,
            ),
            const Divider(height: 24),
            _buildMontantRow(
              'TVA Déductible',
              _declaration.tvaDeductible,
              Colors.blue,
              Icons.arrow_downward,
            ),
            const Divider(height: 24),
            _buildMontantRow(
              'TVA à Décaisser',
              _declaration.tvaADecaisser,
              _declaration.tvaADecaisser >= 0 ? Colors.orange : Colors.red,
              Icons.account_balance_wallet,
              isBold: true,
            ),
            if (_declaration.tvaADecaisser < 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Crédit de TVA - À reporter ou se faire rembourser',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                              fontStyle: FontStyle.italic,
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
    );
  }

  Widget _buildMontantRow(
    String label,
    double montant,
    Color color,
    IconData icon, {
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : null,
                ),
          ),
        ),
        Text(
          AppFormatters.formatMontant(montant),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: color,
                fontWeight: isBold ? FontWeight.bold : null,
              ),
        ),
      ],
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
            const SizedBox(height: 12),
            Text(
              _declaration.notes!,
              style: Theme.of(context).textTheme.bodyMedium,
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
              'Historique',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildDateRow(
              'Créée le',
              _declaration.createdAt,
              Icons.add_circle,
            ),
            if (_declaration.dateTransmission != null) ...[
              const SizedBox(height: 12),
              _buildDateRow(
                'Transmise le',
                _declaration.dateTransmission!,
                Icons.send,
              ),
            ],
            if (_declaration.datePaiement != null) ...[
              const SizedBox(height: 12),
              _buildDateRow(
                'Payée le',
                _declaration.datePaiement!,
                Icons.check_circle,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow(String label, DateTime date, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 8),
        Text(
          AppFormatters.formatDate(date),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cette déclaration est en lecture seule. La modification des déclarations n\'est pas encore implémentée dans l\'API.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue[900],
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
}
