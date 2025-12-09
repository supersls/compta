import 'package:flutter/material.dart';
import '../../models/declaration_tva.dart';
import '../../services/tva_service.dart';
import '../../utils/formatters.dart';
import 'declaration_tva_form_screen.dart';

class CalculateurTVAScreen extends StatefulWidget {
  const CalculateurTVAScreen({super.key});

  @override
  State<CalculateurTVAScreen> createState() => _CalculateurTVAScreenState();
}

class _CalculateurTVAScreenState extends State<CalculateurTVAScreen> {
  final TVAService _tvaService = TVAService();

  DateTime _periodeDebut = DateTime.now();
  DateTime _periodeFin = DateTime.now();
  bool _isLoading = false;
  Map<String, dynamic>? _calculResult;
  List<Map<String, dynamic>>? _detailParTaux;

  @override
  void initState() {
    super.initState();
    _setMoisEnCours();
  }

  void _setMoisEnCours() {
    final now = DateTime.now();
    _periodeDebut = DateTime(now.year, now.month, 1);
    _periodeFin = DateTime(now.year, now.month + 1, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculateur TVA'),
      ),
      body: Column(
        children: [
          _buildPeriodeSelector(),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_calculResult != null)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildResultatsCard(),
                  const SizedBox(height: 16),
                  _buildDetailParTauxCard(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                  const SizedBox(height: 100),
                ],
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Text('Sélectionnez une période et calculez la TVA'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodeSelector() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période de calcul',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Début'),
                    subtitle: Text(AppFormatters.formatDate(_periodeDebut)),
                    onTap: () => _selectDate(true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: const Text('Fin'),
                    subtitle: Text(AppFormatters.formatDate(_periodeFin)),
                    onTap: () => _selectDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPeriodePresetChip('Mois en cours', _setMoisEnCours),
                _buildPeriodePresetChip('Mois dernier', _setMoisDernier),
                _buildPeriodePresetChip('Trimestre en cours', _setTrimestreEnCours),
                _buildPeriodePresetChip('Trimestre dernier', _setTrimestreDernier),
                _buildPeriodePresetChip('Année en cours', _setAnneeEnCours),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.calculate),
                label: const Text('Calculer la TVA'),
                onPressed: _calculerTVA,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodePresetChip(String label, VoidCallback onPressed) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          onPressed();
          _calculResult = null;
          _detailParTaux = null;
        });
      },
    );
  }

  Widget _buildResultatsCard() {
    final tvaCollectee = (_calculResult!['tva_collectee'] as num).toDouble();
    final tvaDeductible = (_calculResult!['tva_deductible'] as num).toDouble();
    final tvaADecaisser = (_calculResult!['tva_a_decaisser'] as num).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résultats',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            _buildMontantRow(
              'TVA Collectée',
              tvaCollectee,
              Colors.green,
              Icons.arrow_upward,
            ),
            const SizedBox(height: 16),
            _buildMontantRow(
              'TVA Déductible',
              tvaDeductible,
              Colors.blue,
              Icons.arrow_downward,
            ),
            const Divider(height: 32),
            _buildMontantRow(
              'TVA à Décaisser',
              tvaADecaisser,
              tvaADecaisser >= 0 ? Colors.orange : Colors.red,
              Icons.account_balance_wallet,
              isBold: true,
              isLarge: true,
            ),
            if (tvaADecaisser < 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Crédit de TVA : ${AppFormatters.formatMontant(tvaADecaisser.abs())}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
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

  Widget _buildDetailParTauxCard() {
    if (_detailParTaux == null || _detailParTaux!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détail par taux',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ..._detailParTaux!.map((detail) => _buildTauxDetail(detail)),
          ],
        ),
      ),
    );
  }

  Widget _buildTauxDetail(Map<String, dynamic> detail) {
    final taux = (detail['taux'] as num).toDouble();
    final collectee = (detail['tva_collectee'] as num).toDouble();
    final deductible = (detail['tva_deductible'] as num).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${taux.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.arrow_upward, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  const Text('Collectée:'),
                ],
              ),
              Text(
                AppFormatters.formatMontant(collectee),
                style: const TextStyle(color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.arrow_downward, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  const Text('Déductible:'),
                ],
              ),
              Text(
                AppFormatters.formatMontant(deductible),
                style: const TextStyle(color: Colors.blue),
              ),
            ],
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  Widget _buildMontantRow(
    String label,
    double montant,
    Color color,
    IconData icon, {
    bool isBold = false,
    bool isLarge = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: isLarge ? 32 : 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: (isLarge
                    ? Theme.of(context).textTheme.titleLarge
                    : Theme.of(context).textTheme.bodyLarge)
                ?.copyWith(
              fontWeight: isBold ? FontWeight.bold : null,
            ),
          ),
        ),
        Text(
          AppFormatters.formatMontant(montant),
          style: (isLarge
                  ? Theme.of(context).textTheme.titleLarge
                  : Theme.of(context).textTheme.bodyLarge)
              ?.copyWith(
            color: color,
            fontWeight: isBold ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          icon: const Icon(Icons.add_circle),
          label: const Text('Créer une déclaration depuis ce calcul'),
          onPressed: _creerDeclaration,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Nouveau calcul'),
          onPressed: () {
            setState(() {
              _calculResult = null;
              _detailParTaux = null;
            });
          },
        ),
      ],
    );
  }

  Future<void> _selectDate(bool isDebut) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isDebut ? _periodeDebut : _periodeFin,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        if (isDebut) {
          _periodeDebut = date;
        } else {
          _periodeFin = date;
        }
        _calculResult = null;
        _detailParTaux = null;
      });
    }
  }

  void _setMoisDernier() {
    final now = DateTime.now();
    _periodeDebut = DateTime(now.year, now.month - 1, 1);
    _periodeFin = DateTime(now.year, now.month, 0);
  }

  void _setTrimestreEnCours() {
    final now = DateTime.now();
    final trimestre = ((now.month - 1) ~/ 3) + 1;
    final debutMois = (trimestre - 1) * 3 + 1;
    _periodeDebut = DateTime(now.year, debutMois, 1);
    _periodeFin = DateTime(now.year, debutMois + 3, 0);
  }

  void _setTrimestreDernier() {
    final now = DateTime.now();
    final trimestre = ((now.month - 1) ~/ 3);
    final debutMois = trimestre == 0 ? 10 : (trimestre - 1) * 3 + 1;
    final annee = trimestre == 0 ? now.year - 1 : now.year;
    _periodeDebut = DateTime(annee, debutMois, 1);
    _periodeFin = DateTime(annee, debutMois + 3, 0);
  }

  void _setAnneeEnCours() {
    final now = DateTime.now();
    _periodeDebut = DateTime(now.year, 1, 1);
    _periodeFin = DateTime(now.year, 12, 31);
  }

  Future<void> _calculerTVA() async {
    if (_periodeDebut.isAfter(_periodeFin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La date de début doit être avant la date de fin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _tvaService.calculerTVA(_periodeDebut, _periodeFin);
      final detail = await _tvaService.getDetailParTaux(_periodeDebut, _periodeFin);

      setState(() {
        _calculResult = result;
        _detailParTaux = List<Map<String, dynamic>>.from(detail);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _creerDeclaration() async {
    if (_calculResult == null) return;

    final tvaCollectee = (_calculResult!['tva_collectee'] as num).toDouble();
    final tvaDeductible = (_calculResult!['tva_deductible'] as num).toDouble();
    final tvaADecaisser = (_calculResult!['tva_a_decaisser'] as num).toDouble();

    final declaration = DeclarationTVA(
      periodeDebut: _periodeDebut,
      periodeFin: _periodeFin,
      tvaCollectee: tvaCollectee,
      tvaDeductible: tvaDeductible,
      tvaADecaisser: tvaADecaisser,
      statut: 'en_cours',
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeclarationTVAFormScreen(declaration: declaration),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }
}
