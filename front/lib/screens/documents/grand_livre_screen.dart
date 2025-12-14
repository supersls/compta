import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/documents_service.dart';
import '../../providers/entreprise_provider.dart';
import '../../utils/formatters.dart';

class GrandLivreScreen extends StatefulWidget {
  const GrandLivreScreen({super.key});

  @override
  State<GrandLivreScreen> createState() => _GrandLivreScreenState();
}

class _GrandLivreScreenState extends State<GrandLivreScreen> {
  final DocumentsService _service = DocumentsService();
  List<Map<String, dynamic>> _comptes = [];
  bool _isLoading = true;
  
  DateTime _dateDebut = DateTime(DateTime.now().year, 1, 1);
  DateTime _dateFin = DateTime.now();
  String? _compteFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final entrepriseId = Provider.of<EntrepriseProvider>(context, listen: false).selectedEntreprise?.id;
      if (entrepriseId == null) {
        throw Exception('Aucune entreprise sélectionnée');
      }
      
      final comptes = await _service.getGrandLivre(
        entrepriseId: entrepriseId,
        debut: _dateDebut,
        fin: _dateFin,
        compte: _compteFilter,
      );
      setState(() {
        _comptes = comptes;
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

  Future<void> _exportPDF() async {
    try {
      await _service.exportPDF('grand-livre', {
        'debut': _dateDebut.toIso8601String(),
        'fin': _dateFin.toIso8601String(),
        if (_compteFilter != null) 'compte': _compteFilter,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export PDF en cours...'),
            backgroundColor: Colors.green,
          ),
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

  Future<void> _exportExcel() async {
    try {
      await _service.exportExcel('grand-livre', {
        'debut': _dateDebut.toIso8601String(),
        'fin': _dateFin.toIso8601String(),
        if (_compteFilter != null) 'compte': _compteFilter,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export Excel en cours...'),
            backgroundColor: Colors.green,
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grand Livre'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPDF,
            tooltip: 'Export PDF',
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: _exportExcel,
            tooltip: 'Export Excel',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Date début',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    controller: TextEditingController(
                      text: AppFormatters.formatDate(_dateDebut),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dateDebut,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _dateDebut = date);
                        _loadData();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Date fin',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    controller: TextEditingController(
                      text: AppFormatters.formatDate(_dateFin),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dateFin,
                        firstDate: _dateDebut,
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _dateFin = date);
                        _loadData();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Numéro de compte (optionnel)',
                      prefixIcon: Icon(Icons.filter_list),
                    ),
                    onChanged: (value) {
                      _compteFilter = value.isEmpty ? null : value;
                    },
                    onFieldSubmitted: (_) => _loadData(),
                  ),
                ),
              ],
            ),
          ),

          // Liste des comptes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comptes.isEmpty
                    ? const Center(child: Text('Aucun compte trouvé'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _comptes.length,
                        itemBuilder: (context, index) {
                          final compte = _comptes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ExpansionTile(
                              leading: const Icon(Icons.account_balance_wallet),
                              title: Text(
                                '${compte['numero_compte']} - ${compte['nom_compte']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Solde: ${AppFormatters.formatMontant(_parseDouble(compte['solde_final']))}',
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          _SoldeItem(
                                            label: 'Solde initial',
                                            value: _parseDouble(compte['solde_initial']),
                                          ),
                                          _SoldeItem(
                                            label: 'Total débit',
                                            value: _parseDouble(compte['total_debit']),
                                            color: Colors.red,
                                          ),
                                          _SoldeItem(
                                            label: 'Total crédit',
                                            value: _parseDouble(compte['total_credit']),
                                            color: Colors.green,
                                          ),
                                          _SoldeItem(
                                            label: 'Solde final',
                                            value: _parseDouble(compte['solde_final']),
                                            color: Colors.blue,
                                          ),
                                        ],
                                      ),
                                      if (compte['ecritures'] != null &&
                                          (compte['ecritures'] as List)
                                              .isNotEmpty) ...[
                                        const Divider(height: 32),
                                        const Text(
                                          'Écritures',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...(compte['ecritures'] as List).map(
                                          (ecriture) => ListTile(
                                            dense: true,
                                            leading: Icon(
                                              ecriture['debit'] > 0
                                                  ? Icons.arrow_upward
                                                  : Icons.arrow_downward,
                                              color: ecriture['debit'] > 0
                                                  ? Colors.red
                                                  : Colors.green,
                                              size: 16,
                                            ),
                                            title: Text(ecriture['libelle']),
                                            subtitle: Text(AppFormatters
                                                .formatDate(DateTime.parse(
                                                    ecriture['date_ecriture']))),
                                            trailing: Text(
                                              AppFormatters.formatMontant(
                                                  ecriture['debit'] > 0
                                                      ? ecriture['debit']
                                                      : ecriture['credit']),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: ecriture['debit'] > 0
                                                    ? Colors.red
                                                    : Colors.green,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SoldeItem extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;

  const _SoldeItem({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 4),
        Text(
          AppFormatters.formatMontant(value),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
