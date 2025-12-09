import 'package:flutter/material.dart';
import '../../models/banque.dart';
import '../../services/banque_service.dart';
import '../../utils/validators.dart';

class CompteBancaireFormScreen extends StatefulWidget {
  final CompteBancaire? compte;

  const CompteBancaireFormScreen({super.key, this.compte});

  @override
  State<CompteBancaireFormScreen> createState() => _CompteBancaireFormScreenState();
}

class _CompteBancaireFormScreenState extends State<CompteBancaireFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final BanqueService _service = BanqueService();

  late TextEditingController _nomController;
  late TextEditingController _banqueController;
  late TextEditingController _numeroCompteController;
  late TextEditingController _ibanController;
  late TextEditingController _soldeInitialController;

  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.compte != null;

    if (_isEditMode) {
      final compte = widget.compte!;
      _nomController = TextEditingController(text: compte.nom);
      _banqueController = TextEditingController(text: compte.banque);
      _numeroCompteController = TextEditingController(text: compte.numeroCompte ?? '');
      _ibanController = TextEditingController(text: compte.iban ?? '');
      _soldeInitialController = TextEditingController(
        text: compte.soldeInitial.toString(),
      );
    } else {
      _nomController = TextEditingController();
      _banqueController = TextEditingController();
      _numeroCompteController = TextEditingController();
      _ibanController = TextEditingController();
      _soldeInitialController = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _banqueController.dispose();
    _numeroCompteController.dispose();
    _ibanController.dispose();
    _soldeInitialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modifier le compte' : 'Nouveau compte bancaire'),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations du compte',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du compte',
                        prefixIcon: Icon(Icons.label),
                        helperText: 'Ex: Compte courant principal',
                      ),
                      validator: (value) => AppValidators.validateRequired(value, 'Nom'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _banqueController,
                      decoration: const InputDecoration(
                        labelText: 'Banque',
                        prefixIcon: Icon(Icons.account_balance),
                        helperText: 'Ex: Crédit Agricole',
                      ),
                      validator: (value) => AppValidators.validateRequired(value, 'Banque'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _numeroCompteController,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de compte (optionnel)',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ibanController,
                      decoration: const InputDecoration(
                        labelText: 'IBAN (optionnel)',
                        prefixIcon: Icon(Icons.credit_card),
                        helperText: 'Ex: FR76 1234 5678 9012 3456 7890 123',
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _soldeInitialController,
                      decoration: const InputDecoration(
                        labelText: 'Solde initial',
                        prefixIcon: Icon(Icons.euro),
                        suffix: Text('€'),
                        helperText: 'Solde au moment de la création du compte',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Champ requis';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Montant invalide';
                        }
                        return null;
                      },
                      enabled: !_isEditMode,
                    ),
                  ],
                ),
              ),
            ),
            if (_isEditMode) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Le solde initial ne peut pas être modifié après la création',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange[900],
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final soldeInitial = double.parse(_soldeInitialController.text);

      final compte = CompteBancaire(
        id: widget.compte?.id,
        nom: _nomController.text,
        banque: _banqueController.text,
        numeroCompte: _numeroCompteController.text.isEmpty
            ? null
            : _numeroCompteController.text,
        iban: _ibanController.text.isEmpty ? null : _ibanController.text.toUpperCase(),
        soldeInitial: soldeInitial,
        soldeActuel: widget.compte?.soldeActuel ?? soldeInitial,
        actif: widget.compte?.actif ?? true,
      );

      if (_isEditMode) {
        await _service.updateCompte(compte);
      } else {
        await _service.createCompte(compte);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Compte modifié' : 'Compte créé'),
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
