import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/entreprise_provider.dart';
import '../../models/entreprise.dart';
import '../../services/entreprise_service.dart';

class EntrepriseAdminScreen extends StatefulWidget {
  const EntrepriseAdminScreen({super.key});

  @override
  State<EntrepriseAdminScreen> createState() => _EntrepriseAdminScreenState();
}

class _EntrepriseAdminScreenState extends State<EntrepriseAdminScreen> {
  final EntrepriseService _service = EntrepriseService();
  List<Entreprise> _entreprises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final entreprises = await _service.getEntreprises();
      setState(() {
        _entreprises = entreprises;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Entreprises'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entreprises.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune entreprise',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajoutez votre première entreprise',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _entreprises.length,
                  itemBuilder: (context, index) {
                    final entreprise = _entreprises[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            entreprise.nom[0].toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          entreprise.nom,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (entreprise.siret != null)
                              Text('SIRET: ${entreprise.siret}'),
                            if (entreprise.email != null)
                              Text('Email: ${entreprise.email}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editEntreprise(entreprise),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntreprise,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  void _addEntreprise() {
    showDialog(
      context: context,
      builder: (context) => _EntrepriseFormDialog(
        onSave: (entreprise) async {
          try {
            await _service.createEntreprise(entreprise.toJson());
            _loadData();
            if (mounted) {
              Provider.of<EntrepriseProvider>(context, listen: false)
                  .loadEntreprises();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entreprise créée avec succès'),
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

  void _editEntreprise(Entreprise entreprise) {
    showDialog(
      context: context,
      builder: (context) => _EntrepriseFormDialog(
        entreprise: entreprise,
        onSave: (updated) async {
          try {
            await _service.updateEntreprise(updated.id, updated.toJson());
            _loadData();
            if (mounted) {
              Provider.of<EntrepriseProvider>(context, listen: false)
                  .loadEntreprises();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entreprise mise à jour'),
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

class _EntrepriseFormDialog extends StatefulWidget {
  final Entreprise? entreprise;
  final Function(Entreprise) onSave;

  const _EntrepriseFormDialog({this.entreprise, required this.onSave});

  @override
  State<_EntrepriseFormDialog> createState() => _EntrepriseFormDialogState();
}

class _EntrepriseFormDialogState extends State<_EntrepriseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _siretController;
  late TextEditingController _emailController;
  late TextEditingController _telephoneController;
  late TextEditingController _adresseController;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.entreprise?.nom ?? '');
    _siretController =
        TextEditingController(text: widget.entreprise?.siret ?? '');
    _emailController =
        TextEditingController(text: widget.entreprise?.email ?? '');
    _telephoneController =
        TextEditingController(text: widget.entreprise?.telephone ?? '');
    _adresseController =
        TextEditingController(text: widget.entreprise?.adresse ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _siretController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.entreprise == null
          ? 'Nouvelle Entreprise'
          : 'Modifier Entreprise'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    prefixIcon: Icon(Icons.business),
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
                  controller: _siretController,
                  decoration: const InputDecoration(
                    labelText: 'SIRET',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telephoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _adresseController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
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
              final entreprise = Entreprise(
                id: widget.entreprise?.id ?? 0,
                nom: _nomController.text,
                siret: _siretController.text.isEmpty
                    ? null
                    : _siretController.text,
                email: _emailController.text.isEmpty
                    ? null
                    : _emailController.text,
                telephone: _telephoneController.text.isEmpty
                    ? null
                    : _telephoneController.text,
                adresse: _adresseController.text.isEmpty
                    ? null
                    : _adresseController.text,
                regimeTva: widget.entreprise?.regimeTva ?? 'reel_normal',
                dateClotureExercice:
                    widget.entreprise?.dateClotureExercice ?? DateTime(2025, 12, 31),
              );
              widget.onSave(entreprise);
              Navigator.pop(context);
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
