import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/client.dart';
import '../../services/client_service.dart';
import '../../providers/entreprise_provider.dart';
import 'client_form_screen.dart';
import 'client_detail_screen.dart';

class ClientsListScreen extends StatefulWidget {
  const ClientsListScreen({super.key});

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  final ClientService _clientService = ClientService();
  List<Client> _clients = [];
  List<Client> _clientsFiltered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showOnlyActifs = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    try {
      final entrepriseId = Provider.of<EntrepriseProvider>(context, listen: false).selectedEntreprise?.id;
      if (entrepriseId == null) {
        throw Exception('Aucune entreprise sélectionnée');
      }
      final clients = await _clientService.getAllClients(entrepriseId);
      setState(() {
        _clients = clients;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    _clientsFiltered = _clients.where((client) {
      // Filtre actif/inactif
      if (_showOnlyActifs && !client.actif) {
        return false;
      }
      
      // Filtre par recherche
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return client.nom.toLowerCase().contains(query) ||
               (client.email?.toLowerCase().contains(query) ?? false) ||
               (client.siret?.toLowerCase().contains(query) ?? false) ||
               (client.ville?.toLowerCase().contains(query) ?? false);
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _clientsFiltered.isEmpty
                    ? _buildEmptyState()
                    : _buildClientsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClientForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau client'),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un client...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.background,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilterChip(
                  label: Text(_showOnlyActifs ? 'Clients actifs' : 'Tous les clients'),
                  selected: _showOnlyActifs,
                  onSelected: (value) {
                    setState(() {
                      _showOnlyActifs = value;
                      _applyFilters();
                    });
                  },
                  avatar: Icon(
                    _showOnlyActifs ? Icons.check_circle : Icons.all_inclusive,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_clientsFiltered.length} client${_clientsFiltered.length > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientsList() {
    return RefreshIndicator(
      onRefresh: _loadClients,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _clientsFiltered.length,
        itemBuilder: (context, index) {
          final client = _clientsFiltered[index];
          return _buildClientCard(client);
        },
      ),
    );
  }

  Widget _buildClientCard(Client client) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showClientDetail(client),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: client.actif 
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.errorContainer,
                child: Text(
                  client.nom.isNotEmpty ? client.nom[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: client.actif 
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            client.nom,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!client.actif)
                          Chip(
                            label: const Text('Inactif'),
                            backgroundColor: Theme.of(context).colorScheme.errorContainer,
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              fontSize: 12,
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (client.email != null || client.telephone != null)
                      Row(
                        children: [
                          if (client.email != null) ...[
                            Icon(
                              Icons.email_outlined,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                client.email!,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (client.email != null && client.telephone != null)
                            const SizedBox(width: 12),
                          if (client.telephone != null) ...[
                            Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              client.telephone!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    if (client.ville != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            client.ville!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Aucun client trouvé'
                : 'Aucun client',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Essayez de modifier votre recherche'
                : 'Commencez par ajouter votre premier client',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showClientForm(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un client'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showClientForm({Client? client}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ClientFormScreen(client: client),
      ),
    );
    if (result == true) {
      _loadClients();
    }
  }

  Future<void> _showClientDetail(Client client) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ClientDetailScreen(client: client),
      ),
    );
    if (result == true) {
      _loadClients();
    }
  }
}
