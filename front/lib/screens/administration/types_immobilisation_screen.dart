import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class TypesImmobilisationScreen extends StatefulWidget {
  const TypesImmobilisationScreen({super.key});

  @override
  State<TypesImmobilisationScreen> createState() => _TypesImmobilisationScreenState();
}

class _TypesImmobilisationScreenState extends State<TypesImmobilisationScreen> {
  List<Map<String, dynamic>> _types = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.get('comptabilite/types-immobilisation');
      setState(() {
        _types = List<Map<String, dynamic>>.from(data);
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

  Future<void> _showTypeDialog([Map<String, dynamic>? type]) async {
    final codeController = TextEditingController(text: type?['code']);
    final nomController = TextEditingController(text: type?['nom']);
    final descriptionController = TextEditingController(text: type?['description']);
    final dureeController = TextEditingController(
      text: type?['duree_amortissement_defaut']?.toString() ?? ''
    );
    final compteImmoController = TextEditingController(
      text: type?['compte_immobilisation_defaut']
    );
    final compteAmortController = TextEditingController(
      text: type?['compte_amortissement_defaut']
    );
    bool actif = type?['actif'] ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(type == null ? 'Nouveau type d\'immobilisation' : 'Modifier le type'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Code*',
                      hintText: 'Ex: MATERIEL',
                    ),
                    enabled: type == null,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom*',
                      hintText: 'Ex: Matériel et outillage',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Description du type d\'immobilisation',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dureeController,
                    decoration: const InputDecoration(
                      labelText: 'Durée d\'amortissement par défaut (années)',
                      hintText: 'Ex: 5',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: compteImmoController,
                    decoration: const InputDecoration(
                      labelText: 'Compte immobilisation par défaut',
                      hintText: 'Ex: 2154',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: compteAmortController,
                    decoration: const InputDecoration(
                      labelText: 'Compte amortissement par défaut',
                      hintText: 'Ex: 28154',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Actif'),
                    value: actif,
                    onChanged: (value) {
                      setDialogState(() => actif = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                if (codeController.text.isEmpty || nomController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le code et le nom sont obligatoires'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final data = {
                    'code': codeController.text.toUpperCase(),
                    'nom': nomController.text,
                    'description': descriptionController.text.isEmpty ? null : descriptionController.text,
                    'duree_amortissement_defaut': dureeController.text.isEmpty ? null : int.parse(dureeController.text),
                    'compte_immobilisation_defaut': compteImmoController.text.isEmpty ? null : compteImmoController.text,
                    'compte_amortissement_defaut': compteAmortController.text.isEmpty ? null : compteAmortController.text,
                    'actif': actif,
                  };

                  if (type == null) {
                    await ApiService.post('comptabilite/types-immobilisation', data);
                  } else {
                    await ApiService.put('comptabilite/types-immobilisation/${type['id']}', data);
                  }
                  
                  Navigator.pop(context, true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _loadTypes();
    }
  }

  Future<void> _deleteType(Map<String, dynamic> type) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer le type "${type['nom']}" ?'),
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

    if (confirm == true) {
      try {
        await ApiService.delete('comptabilite/types-immobilisation/${type['id']}');
        _loadTypes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Type supprimé avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Types d\'immobilisation'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _types.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Aucun type d\'immobilisation'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _showTypeDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un type'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _types.length,
                  itemBuilder: (context, index) {
                    final type = _types[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(type['code'].toString().substring(0, 2)),
                        ),
                        title: Text(
                          type['nom'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Code: ${type['code']}'),
                            if (type['description'] != null && type['description'].toString().isNotEmpty)
                              Text(type['description'], style: const TextStyle(fontStyle: FontStyle.italic)),
                            if (type['duree_amortissement_defaut'] != null)
                              Text('Durée: ${type['duree_amortissement_defaut']} ans'),
                            if (type['compte_immobilisation_defaut'] != null)
                              Text('Comptes: ${type['compte_immobilisation_defaut']} / ${type['compte_amortissement_defaut'] ?? ''}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (type['actif'] == false)
                              const Chip(
                                label: Text('Inactif'),
                                backgroundColor: Colors.grey,
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showTypeDialog(type),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteType(type),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTypeDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
