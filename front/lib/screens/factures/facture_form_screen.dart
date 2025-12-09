import 'package:flutter/material.dart';
import '../../models/facture.dart';
import '../../services/facture_service_http.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../utils/constants.dart';

class FactureFormScreen extends StatefulWidget {
  final Facture? facture;

  const FactureFormScreen({super.key, this.facture});

  @override
  State<FactureFormScreen> createState() => _FactureFormScreenState();
}

class _FactureFormScreenState extends State<FactureFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FactureService _factureService = FactureService();
  
  late TextEditingController _numeroController;
  late TextEditingController _clientFournisseurController;
  late TextEditingController _siretController;
  late TextEditingController _montantHTController;
  late TextEditingController _notesController;
  
  String _type = AppConstants.TYPE_VENTE;
  DateTime _dateEmission = DateTime.now();
  DateTime? _dateEcheance;
  double _tauxTVA = AppConstants.TVA_NORMALE;
  String? _categorie;
  
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.facture != null;
    
    if (_isEditMode) {
      final facture = widget.facture!;
      _numeroController = TextEditingController(text: facture.numero);
      _clientFournisseurController = TextEditingController(text: facture.clientFournisseur);
      _siretController = TextEditingController(text: facture.siretClient ?? '');
      _montantHTController = TextEditingController(text: facture.montantHT.toString());
      _notesController = TextEditingController(text: facture.notes ?? '');
      _type = facture.type;
      _dateEmission = facture.dateEmission;
      _dateEcheance = facture.dateEcheance;
      _tauxTVA = facture.montantHT > 0 ? (facture.montantTVA / facture.montantHT * 100) : AppConstants.TVA_NORMALE;
      _categorie = facture.categorie;
    } else {
      _numeroController = TextEditingController();
      _clientFournisseurController = TextEditingController();
      _siretController = TextEditingController();
      _montantHTController = TextEditingController();
      _notesController = TextEditingController();
      _genererNumero();
    }
  }

  Future<void> _genererNumero() async {
    final numero = await _factureService.genererNumeroFacture(_type);
    setState(() {
      _numeroController.text = numero;
    });
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _clientFournisseurController.dispose();
    _siretController.dispose();
    _montantHTController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modifier la facture' : 'Nouvelle facture'),
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
              onPressed: _saveFacture,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTypeSection(),
            const SizedBox(height: 24),
            _buildInformationsSection(),
            const SizedBox(height: 24),
            _buildMontantsSection(),
            const SizedBox(height: 24),
            _buildDatesSection(),
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

  Widget _buildTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type de facture',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'vente',
                  label: Text('Vente'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: 'achat',
                  label: Text('Achat'),
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _type = newSelection.first;
                  if (!_isEditMode) _genererNumero();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationsSection() {
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
            TextFormField(
              controller: _numeroController,
              decoration: const InputDecoration(
                labelText: 'Numéro de facture',
                prefixIcon: Icon(Icons.tag),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clientFournisseurController,
              decoration: InputDecoration(
                labelText: _type == 'vente' ? 'Client' : 'Fournisseur',
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (value) => AppValidators.validateRequired(
                value,
                _type == 'vente' ? 'Client' : 'Fournisseur',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _siretController,
              decoration: const InputDecoration(
                labelText: 'SIRET (optionnel)',
                prefixIcon: Icon(Icons.business),
              ),
              validator: AppValidators.validateSIRET,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categorie,
              decoration: const InputDecoration(
                labelText: 'Catégorie (optionnel)',
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Aucune')),
                DropdownMenuItem(value: 'ventes_marchandises', child: Text('Ventes de marchandises')),
                DropdownMenuItem(value: 'prestations_services', child: Text('Prestations de services')),
                DropdownMenuItem(value: 'achats', child: Text('Achats')),
                DropdownMenuItem(value: 'charges', child: Text('Charges')),
              ],
              onChanged: (value) {
                setState(() => _categorie = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMontantsSection() {
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
            TextFormField(
              controller: _montantHTController,
              decoration: const InputDecoration(
                labelText: 'Montant HT',
                prefixIcon: Icon(Icons.euro),
                suffix: Text('€'),
              ),
              keyboardType: TextInputType.number,
              validator: AppValidators.validateMontantPositif,
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<double>(
              value: _tauxTVA,
              decoration: const InputDecoration(
                labelText: 'Taux de TVA',
                prefixIcon: Icon(Icons.percent),
              ),
              items: AppConstants.TAUX_TVA.map((taux) {
                return DropdownMenuItem(
                  value: taux,
                  child: Text('${taux.toStringAsFixed(1)}%'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _tauxTVA = value!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesSection() {
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
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date d\'émission'),
              subtitle: Text(AppFormatters.formatDate(_dateEmission)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dateEmission,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() => _dateEmission = date);
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Date d\'échéance (optionnel)'),
              subtitle: Text(
                _dateEcheance != null
                    ? AppFormatters.formatDate(_dateEcheance!)
                    : 'Non définie',
              ),
              trailing: _dateEcheance != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dateEcheance = null),
                    )
                  : null,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dateEcheance ?? _dateEmission.add(const Duration(days: 30)),
                  firstDate: _dateEmission,
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() => _dateEcheance = date);
                }
              },
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
    final montantHT = AppValidators.parseMontant(_montantHTController.text) ?? 0;
    final montantTVA = montantHT * _tauxTVA / 100;
    final montantTTC = montantHT + montantTVA;

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
                  'Montant HT',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  AppFormatters.formatMontant(montantHT),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TVA (${_tauxTVA.toStringAsFixed(1)}%)',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  AppFormatters.formatMontant(montantTVA),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Montant TTC',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppFormatters.formatMontant(montantTTC),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _type == 'vente' ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveFacture() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final montantHT = AppValidators.parseMontant(_montantHTController.text)!;
      final montantTVA = AppFormatters.arrondir(montantHT * _tauxTVA / 100);
      final montantTTC = AppFormatters.arrondir(montantHT + montantTVA);

      final facture = Facture(
        id: widget.facture?.id,
        numero: _numeroController.text,
        type: _type,
        dateEmission: _dateEmission,
        dateEcheance: _dateEcheance,
        clientFournisseur: _clientFournisseurController.text,
        siretClient: _siretController.text.isEmpty ? null : AppValidators.cleanSIRET(_siretController.text),
        montantHT: montantHT,
        montantTVA: montantTVA,
        montantTTC: montantTTC,
        statut: widget.facture?.statut ?? AppConstants.STATUT_EN_ATTENTE,
        montantPaye: widget.facture?.montantPaye ?? 0,
        categorie: _categorie,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (_isEditMode) {
        await _factureService.updateFacture(facture);
      } else {
        await _factureService.createFacture(facture);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Facture modifiée' : 'Facture créée'),
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
