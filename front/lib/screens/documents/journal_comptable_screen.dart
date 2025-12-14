import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ecriture_comptable.dart';
import '../../services/documents_service.dart';
import '../../providers/entreprise_provider.dart';
import '../../utils/formatters.dart';
import 'ecriture_form_screen.dart';

class JournalComptableScreen extends StatefulWidget {
  const JournalComptableScreen({super.key});

  @override
  State<JournalComptableScreen> createState() => _JournalComptableScreenState();
}

class _JournalComptableScreenState extends State<JournalComptableScreen> {
  final DocumentsService _service = DocumentsService();
  List<EcritureComptable> _ecritures = [];
  bool _isLoading = true;
  
  DateTime _dateDebut = DateTime(DateTime.now().year, 1, 1);
  DateTime _dateFin = DateTime.now();
  String? _journalFilter;

  final List<String> _journaux = [
    'Ventes',
    'Achats',
    'Banque',
    'Caisse',
    'OD (Opérations Diverses)',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final entrepriseId = Provider.of<EntrepriseProvider>(context, listen: false).selectedEntreprise?.id;
      if (entrepriseId == null) {
        throw Exception('Aucune entreprise sélectionnée');
      }
      
      final ecritures = await _service.getJournalComptable(
        entrepriseId: entrepriseId,
        debut: _dateDebut,
        fin: _dateFin,
        journal: _journalFilter,
      );
      setState(() {
        _ecritures = ecritures;
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
      await _service.exportPDF('journal', {
        'debut': _dateDebut.toIso8601String(),
        'fin': _dateFin.toIso8601String(),
        if (_journalFilter != null) 'journal': _journalFilter,
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
      await _service.exportExcel('journal', {
        'debut': _dateDebut.toIso8601String(),
        'fin': _dateFin.toIso8601String(),
        if (_journalFilter != null) 'journal': _journalFilter,
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
    final totalDebit = _ecritures.fold<double>(0, (sum, e) => sum + e.debit);
    final totalCredit = _ecritures.fold<double>(0, (sum, e) => sum + e.credit);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Comptable'),
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
            child: Column(
              children: [
                Row(
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
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Journal',
                          prefixIcon: Icon(Icons.filter_list),
                        ),
                        value: _journalFilter,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Tous les journaux'),
                          ),
                          ..._journaux.map((j) => DropdownMenuItem(
                                value: j,
                                child: Text(j),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _journalFilter = value);
                          _loadData();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Résumé
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Débit',
                    value: AppFormatters.formatMontant(totalDebit),
                    icon: Icons.arrow_upward,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Total Crédit',
                    value: AppFormatters.formatMontant(totalCredit),
                    icon: Icons.arrow_downward,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Écritures',
                    value: '${_ecritures.length}',
                    icon: Icons.receipt_long,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          // Liste des écritures
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _ecritures.isEmpty
                    ? const Center(
                        child: Text('Aucune écriture pour cette période'))
                    : ListView.builder(
                        itemCount: _ecritures.length,
                        itemBuilder: (context, index) {
                          final ecriture = _ecritures[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: ecriture.isDebit
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                child: Icon(
                                  ecriture.isDebit
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: ecriture.isDebit
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                              title: Text(ecriture.libelle),
                              subtitle: Text(
                                '${ecriture.compte} - ${AppFormatters.formatDate(ecriture.dateEcriture)}',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    AppFormatters.formatMontant(
                                        ecriture.isDebit
                                            ? ecriture.debit
                                            : ecriture.credit),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: ecriture.isDebit
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                  Text(
                                    ecriture.journal,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EcritureFormScreen(),
            ),
          );
          // Si l'écriture a été créée avec succès, recharger les données
          if (result == true && mounted) {
            _loadData();
          }
        },
        tooltip: 'Ajouter une écriture',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
