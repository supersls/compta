import 'package:flutter/material.dart';
import '../../models/immobilisation.dart';
import '../../services/immobilisation_service.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';

class ImmobilisationFormScreen extends StatefulWidget {
  final Immobilisation? immobilisation;

  const ImmobilisationFormScreen({super.key, this.immobilisation});

  @override
  State<ImmobilisationFormScreen> createState() => _ImmobilisationFormScreenState();
}

class _ImmobilisationFormScreenState extends State<ImmobilisationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImmobilisationService _service = ImmobilisationService();

  late TextEditingController _libelleController;
  late TextEditingController _valeurController;
  late TextEditingController _dureeController;
  late TextEditingController _tauxController;
  late TextEditingController _notesController;

  String _type = 'materiel';
  String _methode = 'lineaire';
  DateTime _dateAcquisition = DateTime.now();
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isLoadingTypes = true;
  List<Map<String, dynamic>> _types = [];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.immobilisation != null;

    if (_isEditMode) {
      final immo = widget.immobilisation!;
      _libelleController = TextEditingController(text: immo.libelle);
      _valeurController = TextEditingController(text: immo.valeurAcquisition.toString());
      _dureeController = TextEditingController(text: immo.dureeAmortissement.toString());
      _tauxController = TextEditingController(
        text: immo.tauxAmortissement?.toString() ?? '',
      );
      _notesController = TextEditingController(text: immo.notes ?? '');
      _type = immo.type;
      _methode = immo.methodeAmortissement;
      _dateAcquisition = immo.dateAcquisition;
    } else {
      _libelleController = TextEditingController();
      _valeurController = TextEditingController();
      _dureeController = TextEditingController();
      _tauxController = TextEditingController();
      _notesController = TextEditingController();
    }
    
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    setState(() => _isLoadingTypes = true);
    try {
      final data = await ApiService.get('comptabilite/types-immobilisation');
      setState(() {
        _types = List<Map<String, dynamic>>.from(data);
        _isLoadingTypes = false;
        // Définir le premier type par défaut si disponible
        if (_types.isNotEmpty && !_isEditMode) {
          _type = _types.first['code'].toString().toLowerCase();
          // Préremplir la durée d'amortissement par défaut
          if (_types.first['duree_amortissement_defaut'] != null) {
            _dureeController.text = _types.first['duree_amortissement_defaut'].toString();
          }
        }
      });
    } catch (e) {
      setState(() => _isLoadingTypes = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des types: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _libelleController.dispose();
    _valeurController.dispose();
    _dureeController.dispose();
    _tauxController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modifier l\'immobilisation' : 'Nouvelle immobilisation'),
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
              onPressed: _save,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildGeneralSection(),
            const SizedBox(height: 24),
            _buildAmortissementSection(),
            const SizedBox(height: 24),
            _buildNotesSection(),
            const SizedBox(height: 24),
            if (!_isEditMode) _buildPlanAmortissement(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations générales',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _libelleController,
              decoration: const InputDecoration(
                labelText: 'Désignation',
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) => AppValidators.validateRequired(value, 'Désignation'),
            ),
            const SizedBox(height: 16),
            _isLoadingTypes
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
                    value: _types.any((t) => t['code'].toString().toLowerCase() == _type) ? _type : null,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _types.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['code'].toString().toLowerCase(),
                        child: Text(type['nom']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _type = value!;
                        // Auto-remplir la durée d'amortissement par défaut
                        final selectedType = _types.firstWhere(
                          (t) => t['code'].toString().toLowerCase() == value,
                          orElse: () => {},
                        );
                        if (selectedType['duree_amortissement_defaut'] != null && !_isEditMode) {
                          _dureeController.text = selectedType['duree_amortissement_defaut'].toString();
                        }
                      });
                    },
                  ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date d\'acquisition'),
              subtitle: Text(AppFormatters.formatDate(_dateAcquisition)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dateAcquisition,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _dateAcquisition = date);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valeurController,
              decoration: const InputDecoration(
                labelText: 'Valeur d\'acquisition',
                prefixIcon: Icon(Icons.euro),
                suffix: Text('€'),
              ),
              keyboardType: TextInputType.number,
              validator: AppValidators.validateMontantPositif,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmortissementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amortissement',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _methode,
              decoration: const InputDecoration(
                labelText: 'Méthode',
                prefixIcon: Icon(Icons.analytics),
              ),
              items: const [
                DropdownMenuItem(value: 'lineaire', child: Text('Linéaire')),
                DropdownMenuItem(value: 'degressif', child: Text('Dégressif')),
              ],
              onChanged: (value) {
                setState(() => _methode = value!);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dureeController,
              decoration: const InputDecoration(
                labelText: 'Durée d\'amortissement',
                prefixIcon: Icon(Icons.timelapse),
                suffix: Text('ans'),
                helperText: 'Nombre d\'années',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Champ requis';
                }
                final duree = int.tryParse(value);
                if (duree == null || duree <= 0) {
                  return 'Durée invalide';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tauxController,
              decoration: InputDecoration(
                labelText: 'Taux personnalisé (optionnel)',
                prefixIcon: const Icon(Icons.percent),
                suffix: const Text('%'),
                helperText: _methode == 'lineaire'
                    ? 'Calculé automatiquement si vide'
                    : 'Taux dégressif calculé si vide',
              ),
              keyboardType: TextInputType.number,
            ),
            if (_dureeController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Taux calculé: ${_calculateTaux().toStringAsFixed(2)}%',
                        style: Theme.of(context).textTheme.bodyMedium,
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

  Widget _buildPlanAmortissement() {
    if (_valeurController.text.isEmpty || _dureeController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    final valeur = AppValidators.parseMontant(_valeurController.text);
    final duree = int.tryParse(_dureeController.text);

    if (valeur == null || duree == null || duree <= 0) {
      return const SizedBox.shrink();
    }

    final immo = Immobilisation(
      libelle: 'Aperçu',
      type: _type,
      dateAcquisition: _dateAcquisition,
      valeurAcquisition: valeur,
      dureeAmortissement: duree,
      methodeAmortissement: _methode,
      tauxAmortissement: _tauxController.text.isNotEmpty
          ? double.tryParse(_tauxController.text)
          : null,
      valeurResiduelle: valeur,
    );

    final plan = _service.calculerPlanAmortissement(immo);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan d\'amortissement prévisionnel',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey[300]!),
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  children: [
                    _buildTableCell('Année', isHeader: true),
                    _buildTableCell('Dotation', isHeader: true),
                    _buildTableCell('VNC', isHeader: true),
                  ],
                ),
                ...plan.map((row) => TableRow(
                      children: [
                        _buildTableCell(row['annee'].toString()),
                        _buildTableCell(AppFormatters.formatMontant(row['dotation'])),
                        _buildTableCell(AppFormatters.formatMontant(row['vnc'])),
                      ],
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 14 : 13,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  double _calculateTaux() {
    final duree = int.tryParse(_dureeController.text);
    if (duree == null || duree <= 0) return 0;

    if (_tauxController.text.isNotEmpty) {
      return double.tryParse(_tauxController.text) ?? 0;
    }

    if (_methode == 'lineaire') {
      return 100 / duree;
    }

    // Dégressif
    final tauxLineaire = 100 / duree;
    if (duree <= 3) return tauxLineaire * 1.25;
    if (duree <= 5) return tauxLineaire * 1.75;
    return tauxLineaire * 2.25;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final valeur = AppValidators.parseMontant(_valeurController.text)!;
      final duree = int.parse(_dureeController.text);
      final taux = _tauxController.text.isNotEmpty
          ? double.tryParse(_tauxController.text)
          : null;

      final immobilisation = Immobilisation(
        id: widget.immobilisation?.id,
        libelle: _libelleController.text,
        type: _type,
        dateAcquisition: _dateAcquisition,
        valeurAcquisition: valeur,
        dureeAmortissement: duree,
        methodeAmortissement: _methode,
        tauxAmortissement: taux,
        valeurResiduelle: widget.immobilisation?.valeurResiduelle ?? valeur,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (_isEditMode) {
        await _service.updateImmobilisation(immobilisation);
      } else {
        await _service.createImmobilisation(immobilisation);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Immobilisation modifiée'
                : 'Immobilisation créée'),
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
