import 'package:flutter/material.dart';

class JournauxScreen extends StatefulWidget {
  const JournauxScreen({super.key});

  @override
  State<JournauxScreen> createState() => _JournauxScreenState();
}

class _JournauxScreenState extends State<JournauxScreen> {
  final List<Map<String, dynamic>> _journaux = [
    {
      'code': 'VE',
      'nom': 'Ventes',
      'description': 'Journal des ventes de marchandises et prestations',
      'actif': true,
      'icon': Icons.shopping_cart,
      'color': Colors.green,
    },
    {
      'code': 'AC',
      'nom': 'Achats',
      'description': 'Journal des achats de marchandises et services',
      'actif': true,
      'icon': Icons.shopping_bag,
      'color': Colors.orange,
    },
    {
      'code': 'BQ',
      'nom': 'Banque',
      'description': 'Journal des opérations bancaires',
      'actif': true,
      'icon': Icons.account_balance,
      'color': Colors.blue,
    },
    {
      'code': 'CA',
      'nom': 'Caisse',
      'description': 'Journal des opérations en espèces',
      'actif': true,
      'icon': Icons.money,
      'color': Colors.purple,
    },
    {
      'code': 'OD',
      'nom': 'Opérations Diverses',
      'description': 'Journal des opérations diverses (salaires, charges, etc.)',
      'actif': true,
      'icon': Icons.more_horiz,
      'color': Colors.grey,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journaux Comptables'),
      ),
      body: Column(
        children: [
          // Info
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
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
                    'Les journaux comptables permettent de classer les écritures par type d\'opération. Chaque journal a un code unique et un type d\'opération spécifique.',
                    style: TextStyle(color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),

          // Liste des journaux
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _journaux.length,
              itemBuilder: (context, index) {
                final journal = _journaux[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (journal['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        journal['icon'] as IconData,
                        color: journal['color'] as Color,
                      ),
                    ),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (journal['color'] as Color).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            journal['code'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: journal['color'] as Color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          journal['nom'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        if (journal['actif'] as bool)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Actif',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Inactif',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(journal['description'] as String),
                    ),
                    trailing: PopupMenuButton<String>(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Modifier'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(journal['actif'] as bool
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              const SizedBox(width: 8),
                              Text(journal['actif'] as bool
                                  ? 'Désactiver'
                                  : 'Activer'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editJournal(index);
                        } else if (value == 'toggle') {
                          setState(() {
                            _journaux[index]['actif'] =
                                !(journal['actif'] as bool);
                          });
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addJournal,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un journal'),
      ),
    );
  }

  void _addJournal() {
    showDialog(
      context: context,
      builder: (context) => _JournalFormDialog(
        onSave: (journal) {
          setState(() {
            _journaux.add(journal);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Journal ajouté avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _editJournal(int index) {
    showDialog(
      context: context,
      builder: (context) => _JournalFormDialog(
        journal: _journaux[index],
        onSave: (journal) {
          setState(() {
            _journaux[index] = journal;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Journal modifié avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }
}

class _JournalFormDialog extends StatefulWidget {
  final Map<String, dynamic>? journal;
  final Function(Map<String, dynamic>) onSave;

  const _JournalFormDialog({this.journal, required this.onSave});

  @override
  State<_JournalFormDialog> createState() => _JournalFormDialogState();
}

class _JournalFormDialogState extends State<_JournalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _nomController;
  late TextEditingController _descriptionController;
  late bool _actif;
  IconData _selectedIcon = Icons.book;
  Color _selectedColor = Colors.blue;

  final List<IconData> _availableIcons = [
    Icons.book,
    Icons.shopping_cart,
    Icons.shopping_bag,
    Icons.account_balance,
    Icons.money,
    Icons.receipt,
    Icons.more_horiz,
  ];

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _codeController =
        TextEditingController(text: widget.journal?['code'] ?? '');
    _nomController = TextEditingController(text: widget.journal?['nom'] ?? '');
    _descriptionController =
        TextEditingController(text: widget.journal?['description'] ?? '');
    _actif = widget.journal?['actif'] ?? true;
    if (widget.journal != null) {
      _selectedIcon = widget.journal!['icon'] as IconData;
      _selectedColor = widget.journal!['color'] as Color;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.journal == null ? 'Nouveau Journal' : 'Modifier Journal'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Code *',
                    hintText: 'Ex: VE, AC, BQ...',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le code est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    hintText: 'Ex: Ventes',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le nom est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                // Icône
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Icône'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableIcons.map((icon) {
                        return IconButton(
                          icon: Icon(icon),
                          isSelected: _selectedIcon == icon,
                          onPressed: () {
                            setState(() => _selectedIcon = icon);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Couleur
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Couleur'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableColors.map((color) {
                        return InkWell(
                          onTap: () {
                            setState(() => _selectedColor = color);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: _selectedColor == color
                                  ? Border.all(color: Colors.black, width: 3)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Actif'),
                  value: _actif,
                  onChanged: (value) {
                    setState(() => _actif = value);
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
                'code': _codeController.text.toUpperCase(),
                'nom': _nomController.text,
                'description': _descriptionController.text,
                'actif': _actif,
                'icon': _selectedIcon,
                'color': _selectedColor,
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
