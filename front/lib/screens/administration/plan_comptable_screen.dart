import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class PlanComptableScreen extends StatefulWidget {
  const PlanComptableScreen({super.key});

  @override
  State<PlanComptableScreen> createState() => _PlanComptableScreenState();
}

class _PlanComptableScreenState extends State<PlanComptableScreen> {
  List<Map<String, dynamic>> _comptes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int? _classeFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.get('comptabilite/plan-comptable');
      setState(() {
        _comptes = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _comptesFiltered {
    var filtered = _comptes;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((c) =>
              c['numero'].toString().contains(_searchQuery) ||
              c['libelle']
                  .toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_classeFilter != null) {
      filtered = filtered.where((c) => c['classe'] == _classeFilter).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Comptable Général'),
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.3),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Rechercher',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Tous',
                        isSelected: _classeFilter == null,
                        onSelected: () {
                          setState(() => _classeFilter = null);
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Classe 1 - Capitaux',
                        isSelected: _classeFilter == 1,
                        onSelected: () {
                          setState(() => _classeFilter = 1);
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Classe 2 - Immobilisations',
                        isSelected: _classeFilter == 2,
                        onSelected: () {
                          setState(() => _classeFilter = 2);
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Classe 4 - Tiers',
                        isSelected: _classeFilter == 4,
                        onSelected: () {
                          setState(() => _classeFilter = 4);
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Classe 5 - Financiers',
                        isSelected: _classeFilter == 5,
                        onSelected: () {
                          setState(() => _classeFilter = 5);
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Classe 6 - Charges',
                        isSelected: _classeFilter == 6,
                        onSelected: () {
                          setState(() => _classeFilter = 6);
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Classe 7 - Produits',
                        isSelected: _classeFilter == 7,
                        onSelected: () {
                          setState(() => _classeFilter = 7);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Résumé
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '${_comptesFiltered.length} compte(s)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),

          // Liste des comptes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comptesFiltered.isEmpty
                    ? const Center(child: Text('Aucun compte trouvé'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _comptesFiltered.length,
                        itemBuilder: (context, index) {
                          final compte = _comptesFiltered[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getClasseColor(compte['classe']),
                                child: Text(
                                  compte['classe'].toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                '${compte['numero']} - ${compte['libelle']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(_getTypeLabel(compte['type'])),
                              trailing: Chip(
                                label: Text('Classe ${compte['classe']}'),
                                backgroundColor:
                                    _getClasseColor(compte['classe'])
                                        .withOpacity(0.2),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCompte,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un compte'),
      ),
    );
  }

  Color _getClasseColor(int classe) {
    switch (classe) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.purple;
      case 6:
        return Colors.red;
      case 7:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'actif':
        return 'Actif';
      case 'passif':
        return 'Passif';
      case 'charge':
        return 'Charge';
      case 'produit':
        return 'Produit';
      default:
        return type;
    }
  }

  void _addCompte() {
    showDialog(
      context: context,
      builder: (context) => _CompteFormDialog(
        onSave: (compte) async {
          try {
            await ApiService.post('comptabilite/plan-comptable', compte);
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Compte ajouté avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
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
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _CompteFormDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const _CompteFormDialog({required this.onSave});

  @override
  State<_CompteFormDialog> createState() => _CompteFormDialogState();
}

class _CompteFormDialogState extends State<_CompteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numeroController = TextEditingController();
  final _libelleController = TextEditingController();
  int _classe = 1;
  String _type = 'actif';

  @override
  void dispose() {
    _numeroController.dispose();
    _libelleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouveau Compte'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _numeroController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de compte *',
                    hintText: 'Ex: 411001',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le numéro est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _libelleController,
                  decoration: const InputDecoration(
                    labelText: 'Libellé *',
                    hintText: 'Ex: Client ABC',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le libellé est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _classe,
                  decoration: const InputDecoration(labelText: 'Classe'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 - Capitaux')),
                    DropdownMenuItem(
                        value: 2, child: Text('2 - Immobilisations')),
                    DropdownMenuItem(value: 4, child: Text('4 - Tiers')),
                    DropdownMenuItem(value: 5, child: Text('5 - Financiers')),
                    DropdownMenuItem(value: 6, child: Text('6 - Charges')),
                    DropdownMenuItem(value: 7, child: Text('7 - Produits')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _classe = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'actif', child: Text('Actif')),
                    DropdownMenuItem(value: 'passif', child: Text('Passif')),
                    DropdownMenuItem(value: 'charge', child: Text('Charge')),
                    DropdownMenuItem(value: 'produit', child: Text('Produit')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _type = value);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave({
                'numero': _numeroController.text,
                'libelle': _libelleController.text,
                'classe': _classe,
                'type': _type,
              });
              Navigator.pop(context);
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
