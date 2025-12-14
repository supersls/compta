import 'package:flutter/material.dart';
import '../../models/client.dart';
import '../../services/client_service.dart';
import '../../utils/validators.dart';

class ClientFormScreen extends StatefulWidget {
  final Client? client;

  const ClientFormScreen({super.key, this.client});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ClientService _clientService = ClientService();
  
  late TextEditingController _nomController;
  late TextEditingController _siretController;
  late TextEditingController _adresseController;
  late TextEditingController _codePostalController;
  late TextEditingController _villeController;
  late TextEditingController _paysController;
  late TextEditingController _emailController;
  late TextEditingController _telephoneController;
  late TextEditingController _contactController;
  late TextEditingController _tvaController;
  late TextEditingController _conditionsController;
  late TextEditingController _notesController;
  
  bool _actif = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final client = widget.client;
    
    _nomController = TextEditingController(text: client?.nom ?? '');
    _siretController = TextEditingController(text: client?.siret ?? '');
    _adresseController = TextEditingController(text: client?.adresse ?? '');
    _codePostalController = TextEditingController(text: client?.codePostal ?? '');
    _villeController = TextEditingController(text: client?.ville ?? '');
    _paysController = TextEditingController(text: client?.pays ?? 'France');
    _emailController = TextEditingController(text: client?.email ?? '');
    _telephoneController = TextEditingController(text: client?.telephone ?? '');
    _contactController = TextEditingController(text: client?.contactPrincipal ?? '');
    _tvaController = TextEditingController(text: client?.tvaIntracommunautaire ?? '');
    _conditionsController = TextEditingController(text: client?.conditionsPaiement ?? '');
    _notesController = TextEditingController(text: client?.notes ?? '');
    _actif = client?.actif ?? true;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _siretController.dispose();
    _adresseController.dispose();
    _codePostalController.dispose();
    _villeController.dispose();
    _paysController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _contactController.dispose();
    _tvaController.dispose();
    _conditionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = Client(
        id: widget.client?.id,
        nom: _nomController.text.trim(),
        siret: _siretController.text.trim().isEmpty ? null : _siretController.text.trim(),
        adresse: _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
        codePostal: _codePostalController.text.trim().isEmpty ? null : _codePostalController.text.trim(),
        ville: _villeController.text.trim().isEmpty ? null : _villeController.text.trim(),
        pays: _paysController.text.trim().isEmpty ? 'France' : _paysController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        telephone: _telephoneController.text.trim().isEmpty ? null : _telephoneController.text.trim(),
        contactPrincipal: _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
        tvaIntracommunautaire: _tvaController.text.trim().isEmpty ? null : _tvaController.text.trim(),
        conditionsPaiement: _conditionsController.text.trim().isEmpty ? null : _conditionsController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        actif: _actif,
      );

      if (widget.client == null) {
        await _clientService.createClient(client);
      } else {
        await _clientService.updateClient(client);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.client == null
                  ? 'Client créé avec succès'
                  : 'Client modifié avec succès',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client == null ? 'Nouveau client' : 'Modifier le client'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Informations principales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations principales',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du client *',
                        hintText: 'Société ABC',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: Validators.required,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _siretController,
                      decoration: const InputDecoration(
                        labelText: 'SIRET',
                        hintText: '12345678901234',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          return Validators.siret(value);
                        }
                        return null;
                      },
                      keyboardType: TextInputType.number,
                      maxLength: 14,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(
                        labelText: 'Contact principal',
                        hintText: 'Jean Dupont',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Coordonnées
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coordonnées',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _adresseController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse',
                        hintText: '123 Rue de la Paix',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home),
                      ),
                      textCapitalization: TextCapitalization.words,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _codePostalController,
                            decoration: const InputDecoration(
                              labelText: 'Code postal',
                              hintText: '75001',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _villeController,
                            decoration: const InputDecoration(
                              labelText: 'Ville',
                              hintText: 'Paris',
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _paysController,
                      decoration: const InputDecoration(
                        labelText: 'Pays',
                        hintText: 'France',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'contact@client.com',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          return Validators.email(value);
                        }
                        return null;
                      },
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telephoneController,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        hintText: '01 23 45 67 89',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Informations complémentaires
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations complémentaires',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tvaController,
                      decoration: const InputDecoration(
                        labelText: 'N° TVA intracommunautaire',
                        hintText: 'FR12345678901',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.euro),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _conditionsController,
                      decoration: const InputDecoration(
                        labelText: 'Conditions de paiement',
                        hintText: '30 jours fin de mois',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Informations supplémentaires...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Statut
            Card(
              child: SwitchListTile(
                title: const Text('Client actif'),
                subtitle: Text(
                  _actif 
                    ? 'Ce client est actif' 
                    : 'Ce client est désactivé',
                ),
                value: _actif,
                onChanged: (value) {
                  setState(() => _actif = value);
                },
                secondary: Icon(
                  _actif ? Icons.check_circle : Icons.cancel,
                  color: _actif ? Colors.green : Colors.red,
                ),
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
                  child: FilledButton(
                    onPressed: _isLoading ? null : _submitForm,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.client == null ? 'Créer' : 'Modifier'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
