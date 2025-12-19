import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ecriture_comptable.dart';
import '../../services/documents_service.dart';
import '../../services/api_service.dart';
import '../../providers/entreprise_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/justificatifs_widget.dart';

class EcritureFormScreen extends StatefulWidget {
  const EcritureFormScreen({super.key});

  @override
  State<EcritureFormScreen> createState() => _EcritureFormScreenState();
}

class _EcritureFormScreenState extends State<EcritureFormScreen> {
  final DocumentsService _service = DocumentsService();
  final _formKey = GlobalKey<FormState>();
  final _justificatifsKey = GlobalKey<JustificatifsWidgetState>();
  bool _isLoading = false;
  bool _isLoadingData = true;

  // Controllers
  late TextEditingController _numeroPieceController;
  late TextEditingController _libelleController;
  late TextEditingController _compteController;
  late TextEditingController _debitController;
  late TextEditingController _creditController;

  DateTime _dateEcriture = DateTime.now();
  String? _journal;

  // Données chargées depuis la base
  List<Map<String, dynamic>> _journaux = [];
  List<Map<String, dynamic>> _comptes = [];

  @override
  void initState() {
    super.initState();
    _numeroPieceController = TextEditingController();
    _libelleController = TextEditingController();
    _compteController = TextEditingController();
    _debitController = TextEditingController();
    _creditController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      // Charger les comptes comptables et les journaux depuis la base de données
      final comptesData = await ApiService.get('comptabilite/plan-comptable');
      final journauxData = await ApiService.get('comptabilite/journaux');
      
      setState(() {
        _comptes = List<Map<String, dynamic>>.from(comptesData);
        _journaux = List<Map<String, dynamic>>.from(journauxData);
        _isLoadingData = false;
        
        // Définir un journal par défaut
        if (_journaux.isNotEmpty) {
          _journal = _journaux.first['nom'];
        }
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _numeroPieceController.dispose();
    _libelleController.dispose();
    _compteController.dispose();
    _debitController.dispose();
    _creditController.dispose();
    super.dispose();
  }

  Future<void> _savEcriture() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final entrepriseId = Provider.of<EntrepriseProvider>(context, listen: false)
        .selectedEntreprise
        ?.id;
    if (entrepriseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune entreprise sélectionnée'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérifier que le débit OU le crédit est rempli (mais pas les deux)
    final debit = double.tryParse(_debitController.text) ?? 0;
    final credit = double.tryParse(_creditController.text) ?? 0;

    if ((debit == 0 && credit == 0) || (debit > 0 && credit > 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Remplissez soit le débit, soit le crédit (mais pas les deux)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Vérifier que le journal est sélectionné
    if (_journal == null || _journal!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un journal'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _service.createEcriture(
        entrepriseId: entrepriseId,
        numeroPiece: _numeroPieceController.text,
        dateEcriture: _dateEcriture,
        journal: _journal!,
        compte: _compteController.text,
        libelle: _libelleController.text,
        debit: debit,
        credit: credit,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Écriture créée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retourner true pour indiquer que les données ont changé
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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ajouter une écriture comptable'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une écriture comptable'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Numéro de pièce
                TextFormField(
                  controller: _numeroPieceController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de pièce',
                    prefixIcon: Icon(Icons.receipt),
                    hintText: 'Ex: VT-2025-001',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le numéro de pièce est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date de l'écriture
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Date de l\'écriture',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  controller: TextEditingController(
                    text: AppFormatters.formatDate(_dateEcriture),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dateEcriture,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _dateEcriture = date);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Journal
                DropdownButtonFormField<String>(
                  value: _journal,
                  decoration: const InputDecoration(
                    labelText: 'Journal',
                    prefixIcon: Icon(Icons.book),
                  ),
                  items: _journaux
                      .map((j) => DropdownMenuItem(
                            value: j['nom'] as String,
                            child: Text('${j['code']} - ${j['nom']}'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _journal = value);
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le journal est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Compte
                DropdownButtonFormField<String>(
                  value: _compteController.text.isEmpty
                      ? null
                      : _compteController.text,
                  decoration: const InputDecoration(
                    labelText: 'Compte comptable',
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  items: _comptes
                      .map((c) => DropdownMenuItem(
                            value: c['numero'] as String,
                            child: Text('${c['numero']} - ${c['libelle']}'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _compteController.text = value);
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le compte est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Libellé
                TextFormField(
                  controller: _libelleController,
                  decoration: const InputDecoration(
                    labelText: 'Libellé',
                    prefixIcon: Icon(Icons.description),
                    hintText: 'Description de l\'écriture',
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le libellé est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Montants
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _debitController,
                        decoration: const InputDecoration(
                          labelText: 'Débit',
                          prefixIcon: Icon(Icons.arrow_upward),
                          suffixText: '€',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _creditController,
                        decoration: const InputDecoration(
                          labelText: 'Crédit',
                          prefixIcon: Icon(Icons.arrow_downward),
                          suffixText: '€',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Widget de gestion des justificatifs
                JustificatifsWidget(
                  key: _justificatifsKey,
                  typeDocument: 'ecriture',
                  dateDocument: _dateEcriture,
                ),
                const SizedBox(height: 24),

                // Aide et instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Comment remplir une écriture comptable ?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Numéro de pièce : Référence unique (ex: VT-2025-001 pour vente, AC-2025-001 pour achat)',
                        style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• Journal : Type d\'opération (Ventes, Achats, Banque, Caisse, OD)',
                        style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• Compte : Numéro du compte selon le plan comptable général',
                        style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• Débit/Crédit : Remplir SOIT le débit SOIT le crédit (jamais les deux)',
                        style: TextStyle(fontSize: 13, color: Colors.grey[800], fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '  → Débit : Augmentation d\'actif ou diminution de passif/produit',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '  → Crédit : Augmentation de passif/produit ou diminution d\'actif',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _savEcriture,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
