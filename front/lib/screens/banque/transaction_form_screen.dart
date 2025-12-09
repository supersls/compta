import 'package:flutter/material.dart';
import '../../models/banque.dart';
import '../../services/banque_service.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';

class TransactionFormScreen extends StatefulWidget {
  final int compteId;
  final TransactionBancaire? transaction;

  const TransactionFormScreen({
    super.key,
    required this.compteId,
    this.transaction,
  });

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final BanqueService _service = BanqueService();

  late TextEditingController _montantController;
  late TextEditingController _descriptionController;
  late TextEditingController _referenceController;

  String _type = 'debit';
  String? _categorie;
  DateTime _dateTransaction = DateTime.now();
  bool _isLoading = false;
  bool _isEditMode = false;

  final List<Map<String, String>> _categories = [
    {'value': 'vente', 'label': 'Vente'},
    {'value': 'achat', 'label': 'Achat'},
    {'value': 'salaire', 'label': 'Salaire'},
    {'value': 'charge', 'label': 'Charge'},
    {'value': 'investissement', 'label': 'Investissement'},
    {'value': 'remboursement', 'label': 'Remboursement'},
    {'value': 'taxe', 'label': 'Taxe'},
    {'value': 'virement', 'label': 'Virement'},
    {'value': 'autre', 'label': 'Autre'},
  ];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.transaction != null;

    if (_isEditMode) {
      final transaction = widget.transaction!;
      _montantController = TextEditingController(text: transaction.montant.toString());
      _descriptionController = TextEditingController(text: transaction.description ?? '');
      _referenceController = TextEditingController(text: transaction.reference ?? '');
      _type = transaction.type;
      _categorie = transaction.categorie;
      _dateTransaction = transaction.dateTransaction;
    } else {
      _montantController = TextEditingController();
      _descriptionController = TextEditingController();
      _referenceController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _montantController.dispose();
    _descriptionController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modifier la transaction' : 'Nouvelle transaction'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _delete,
            ),
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
                      'Type de transaction',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'credit',
                          label: Text('Crédit'),
                          icon: Icon(Icons.arrow_downward),
                        ),
                        ButtonSegment(
                          value: 'debit',
                          label: Text('Débit'),
                          icon: Icon(Icons.arrow_upward),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (Set<String> selection) {
                        setState(() => _type = selection.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Détails de la transaction',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Date'),
                      subtitle: Text(AppFormatters.formatDate(_dateTransaction)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dateTransaction,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _dateTransaction = date);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _montantController,
                      decoration: InputDecoration(
                        labelText: 'Montant',
                        prefixIcon: Icon(
                          _type == 'credit' ? Icons.arrow_downward : Icons.arrow_upward,
                          color: _type == 'credit' ? Colors.green : Colors.red,
                        ),
                        suffix: const Text('€'),
                      ),
                      keyboardType: TextInputType.number,
                      validator: AppValidators.validateMontantPositif,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _categorie,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat['value'],
                          child: Text(cat['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _categorie = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Référence (optionnel)',
                        prefixIcon: Icon(Icons.tag),
                        helperText: 'Ex: numéro de chèque, référence virement',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: _type == 'credit'
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _type == 'credit' ? 'Crédit' : 'Débit',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      _montantController.text.isNotEmpty
                          ? AppFormatters.formatMontant(
                              AppValidators.parseMontant(_montantController.text) ?? 0,
                            )
                          : '0,00 €',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _type == 'credit' ? Colors.green : Colors.red,
                          ),
                    ),
                  ],
                ),
              ),
            ),
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
      final montant = AppValidators.parseMontant(_montantController.text)!;

      final transaction = TransactionBancaire(
        id: widget.transaction?.id,
        compteId: widget.compteId,
        dateTransaction: _dateTransaction,
        type: _type,
        montant: montant,
        categorie: _categorie,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        reference: _referenceController.text.isEmpty
            ? null
            : _referenceController.text,
        rapproche: widget.transaction?.rapproche ?? false,
      );

      if (_isEditMode) {
        await _service.updateTransaction(transaction);
      } else {
        await _service.createTransaction(transaction);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Transaction modifiée' : 'Transaction créée'),
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette transaction ?'),
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
      setState(() => _isLoading = true);

      try {
        await _service.deleteTransaction(widget.transaction!.id!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction supprimée'),
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
}
