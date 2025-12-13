import 'package:flutter/material.dart';
import '../../models/declaration_tva.dart';
import '../../services/tva_service.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';

class DeclarationTVAFormScreen extends StatefulWidget {
  final DeclarationTVA? declaration;

  const DeclarationTVAFormScreen({super.key, this.declaration});

  @override
  State<DeclarationTVAFormScreen> createState() => _DeclarationTVAFormScreenState();
}

class _DeclarationTVAFormScreenState extends State<DeclarationTVAFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TVAService _tvaService = TVAService();

  late TextEditingController _tvaCollecteeController;
  late TextEditingController _tvaDeductibleController;
  late TextEditingController _notesController;

  DateTime _periodeDebut = DateTime.now();
  DateTime _periodeFin = DateTime.now();
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.declaration != null;

    if (_isEditMode) {
      final declaration = widget.declaration!;
      _tvaCollecteeController = TextEditingController(
        text: declaration.tvaCollectee.toString(),
      );
      _tvaDeductibleController = TextEditingController(
        text: declaration.tvaDeductible.toString(),
      );
      _notesController = TextEditingController(text: declaration.notes ?? '');
      _periodeDebut = declaration.periodeDebut;
      _periodeFin = declaration.periodeFin;
    } else {
      _tvaCollecteeController = TextEditingController();
      _tvaDeductibleController = TextEditingController();
      _notesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _tvaCollecteeController.dispose();
    _tvaDeductibleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modifier la déclaration' : 'Nouvelle déclaration TVA'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveDeclaration,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPeriodeSection(),
            const SizedBox(height: 24),
            _buildMontantsSection(),
            const SizedBox(height: 24),
            _buildNotesSection(),
            const SizedBox(height: 32),
            _buildRecapSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période de déclaration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date de début'),
              subtitle: Text(AppFormatters.formatDate(_periodeDebut)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _periodeDebut,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() => _periodeDebut = date);
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Date de fin'),
              subtitle: Text(AppFormatters.formatDate(_periodeFin)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _periodeFin,
                  firstDate: _periodeDebut,
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() => _periodeFin = date);
                }
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildPeriodePresetChip('Mois en cours', _getMoisEnCours),
                _buildPeriodePresetChip('Mois dernier', _getMoisDernier),
                _buildPeriodePresetChip('Trimestre en cours', _getTrimestreEnCours),
                _buildPeriodePresetChip('Trimestre dernier', _getTrimestreDernier),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodePresetChip(String label, Function() getPeriode) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        final periode = getPeriode();
        setState(() {
          _periodeDebut = periode['debut']!;
          _periodeFin = periode['fin']!;
        });
      },
    );
  }

  Map<String, DateTime> _getMoisEnCours() {
    final now = DateTime.now();
    return {
      'debut': DateTime(now.year, now.month, 1),
      'fin': DateTime(now.year, now.month + 1, 0),
    };
  }

  Map<String, DateTime> _getMoisDernier() {
    final now = DateTime.now();
    return {
      'debut': DateTime(now.year, now.month - 1, 1),
      'fin': DateTime(now.year, now.month, 0),
    };
  }

  Map<String, DateTime> _getTrimestreEnCours() {
    final now = DateTime.now();
    final trimestre = ((now.month - 1) ~/ 3) + 1;
    final debutMois = (trimestre - 1) * 3 + 1;
    return {
      'debut': DateTime(now.year, debutMois, 1),
      'fin': DateTime(now.year, debutMois + 3, 0),
    };
  }

  Map<String, DateTime> _getTrimestreDernier() {
    final now = DateTime.now();
    final trimestre = ((now.month - 1) ~/ 3);
    final debutMois = trimestre == 0 ? 10 : (trimestre - 1) * 3 + 1;
    final annee = trimestre == 0 ? now.year - 1 : now.year;
    return {
      'debut': DateTime(annee, debutMois, 1),
      'fin': DateTime(annee, debutMois + 3, 0),
    };
  }

  Widget _buildMontantsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Montants TVA',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tvaCollecteeController,
              decoration: const InputDecoration(
                labelText: 'TVA Collectée',
                prefixIcon: Icon(Icons.arrow_upward, color: Colors.green),
                suffix: Text('€'),
                helperText: 'TVA sur les ventes',
              ),
              keyboardType: TextInputType.number,
              validator: AppValidators.validateMontantPositif,
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tvaDeductibleController,
              decoration: const InputDecoration(
                labelText: 'TVA Déductible',
                prefixIcon: Icon(Icons.arrow_downward, color: Colors.blue),
                suffix: Text('€'),
                helperText: 'TVA sur les achats',
              ),
              keyboardType: TextInputType.number,
              validator: AppValidators.validateMontantPositif,
              onChanged: (value) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                hintText: 'Informations complémentaires...',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecapSection() {
    final tvaCollectee = AppValidators.parseMontant(_tvaCollecteeController.text) ?? 0;
    final tvaDeductible = AppValidators.parseMontant(_tvaDeductibleController.text) ?? 0;
    final tvaADecaisser = tvaCollectee - tvaDeductible;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TVA Collectée',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  AppFormatters.formatMontant(tvaCollectee),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TVA Déductible',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  AppFormatters.formatMontant(tvaDeductible),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TVA à Décaisser',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppFormatters.formatMontant(tvaADecaisser),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tvaADecaisser >= 0 ? Colors.orange : Colors.red,
                  ),
                ),
              ],
            ),
            if (tvaADecaisser < 0) ...[
              const SizedBox(height: 8),
              Text(
                'Crédit de TVA',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveDeclaration() async {
    if (!_formKey.currentState!.validate()) return;

    // Backend endpoints not yet implemented
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La création et modification de déclarations TVA n\'est pas encore implémentée dans l\'API backend.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}
