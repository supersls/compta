import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/chiffre_affaire_service.dart';
import '../../providers/entreprise_provider.dart';
import '../../utils/formatters.dart';

class ChiffreAffaireScreen extends StatefulWidget {
  const ChiffreAffaireScreen({super.key});

  @override
  State<ChiffreAffaireScreen> createState() => _ChiffreAffaireScreenState();
}

class _ChiffreAffaireScreenState extends State<ChiffreAffaireScreen> {
  final ChiffreAffaireService _service = ChiffreAffaireService();
  
  List<Map<String, dynamic>> _caMensuel = [];
  Map<String, dynamic>? _statistiques;
  List<Map<String, dynamic>> _caParClient = [];
  List<int> _exercices = [];
  
  String _exerciceSelectionne = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercices();
  }

  Future<void> _loadExercices() async {
    try {
      final entrepriseId = Provider.of<EntrepriseProvider>(context, listen: false).selectedEntreprise?.id;
      if (entrepriseId == null) {
        throw Exception('Aucune entreprise sélectionnée');
      }
      
      // Générer les années de 2023 à l'année en cours
      final currentYear = DateTime.now().year;
      final generatedYears = List.generate(
        currentYear - 2023 + 1,
        (index) => 2023 + index,
      );
      
      // Fusionner avec les années du backend si disponibles
      final exercices = await _service.getExercices(entrepriseId);
      final allYears = {...generatedYears, ...exercices}.toList()..sort();
      
      setState(() {
        _exercices = allYears;
        _exerciceSelectionne = 'all';
      });
      _loadData();
    } catch (e) {
      // En cas d'erreur, utiliser au moins les années générées
      final currentYear = DateTime.now().year;
      final generatedYears = List.generate(
        currentYear - 2023 + 1,
        (index) => 2023 + index,
      );
      setState(() {
        _exercices = generatedYears;
        _exerciceSelectionne = 'all';
      });
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final entrepriseId = Provider.of<EntrepriseProvider>(context, listen: false).selectedEntreprise?.id;
      if (entrepriseId == null) {
        throw Exception('Aucune entreprise sélectionnée');
      }
      
      final exercice = _exerciceSelectionne == 'all' ? null : _exerciceSelectionne;
      
      final results = await Future.wait([
        _service.getCaMensuel(entrepriseId: entrepriseId, exercice: exercice),
        _service.getStatistiques(entrepriseId: entrepriseId, exercice: exercice),
        _service.getCaParClient(entrepriseId: entrepriseId, exercice: exercice),
      ]);

      setState(() {
        _caMensuel = results[0] as List<Map<String, dynamic>>;
        _statistiques = results[1] as Map<String, dynamic>;
        _caParClient = results[2] as List<Map<String, dynamic>>;
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

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // En-tête avec filtre
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chiffre d\'Affaires',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Évolution et statistiques du chiffre d\'affaires',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Filtre exercice
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        value: _exerciceSelectionne,
                        decoration: const InputDecoration(
                          labelText: 'Exercice',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('Toutes les périodes'),
                          ),
                          ..._exercices.map((exercice) => DropdownMenuItem(
                                value: exercice.toString(),
                                child: Text(exercice.toString()),
                              )),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _exerciceSelectionne = value);
                            _loadData();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contenu
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistiques globales
                        if (_statistiques != null) _buildStatistiquesCards(),
                        
                        const SizedBox(height: 24),

                        // Graphique d'évolution
                        if (_caMensuel.isNotEmpty) _buildEvolutionChart(),

                        const SizedBox(height: 24),

                        // Graphique cumulé
                        if (_caMensuel.isNotEmpty) _buildCumulativeChart(),

                        const SizedBox(height: 24),

                        // Top clients
                        if (_caParClient.isNotEmpty) _buildTopClients(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistiquesCards() {
    final caTotal = _parseDouble(_statistiques!['chiffre_affaire_total']);
    final nbFactures = _parseInt(_statistiques!['nombre_factures']);
    final montantMoyen = _parseDouble(_statistiques!['montant_moyen']);
    final tvaTotal = _parseDouble(_statistiques!['tva_totale']);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'CA Total TTC',
            AppFormatters.formatMontant(caTotal),
            Icons.euro,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Factures',
            nbFactures.toString(),
            Icons.receipt_long,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Montant moyen',
            AppFormatters.formatMontant(montantMoyen),
            Icons.trending_up,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'TVA collectée',
            AppFormatters.formatMontant(tvaTotal),
            Icons.account_balance,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Évolution mensuelle du CA',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: _getChartInterval(),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 80,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            AppFormatters.formatMontant(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _caMensuel.length) {
                            final annee = _parseInt(_caMensuel[index]['annee']);
                            final mois = _parseInt(_caMensuel[index]['mois']);
                            final moisLabels = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jui', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
                            
                            // Afficher l'année uniquement pour janvier ou si c'est le premier point
                            if (mois == 1 || index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      moisLabels[mois - 1],
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      annee.toString().substring(2),
                                      style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            return Text(
                              moisLabels[mois - 1],
                              style: const TextStyle(fontSize: 11),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _caMensuel.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          _parseDouble(entry.value['chiffre_affaire']),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          if (index >= 0 && index < _caMensuel.length) {
                            final data = _caMensuel[index];
                            return LineTooltipItem(
                              '${data['periode_libelle']}\n${AppFormatters.formatMontant(_parseDouble(data['chiffre_affaire']))}',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            );
                          }
                          return null;
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCumulativeChart() {
    // Calculer le CA cumulé
    final cumulativeData = <Map<String, dynamic>>[];
    double cumulative = 0.0;
    
    for (var data in _caMensuel) {
      cumulative += _parseDouble(data['chiffre_affaire']);
      cumulativeData.add({
        ...data,
        'ca_cumule': cumulative,
      });
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CA Cumulé',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: _getCumulativeChartInterval(cumulative),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 80,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            AppFormatters.formatMontant(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < cumulativeData.length) {
                            final annee = _parseInt(cumulativeData[index]['annee']);
                            final mois = _parseInt(cumulativeData[index]['mois']);
                            final moisLabels = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jui', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
                            
                            // Afficher l'année uniquement pour janvier ou si c'est le premier point
                            if (mois == 1 || index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      moisLabels[mois - 1],
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      annee.toString().substring(2),
                                      style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            return Text(
                              moisLabels[mois - 1],
                              style: const TextStyle(fontSize: 11),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: cumulativeData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          _parseDouble(entry.value['ca_cumule']),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          if (index >= 0 && index < cumulativeData.length) {
                            final data = cumulativeData[index];
                            return LineTooltipItem(
                              '${data['periode_libelle']}\nCumulé: ${AppFormatters.formatMontant(_parseDouble(data['ca_cumule']))}\nMois: ${AppFormatters.formatMontant(_parseDouble(data['chiffre_affaire']))}',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            );
                          }
                          return null;
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getChartInterval() {
    if (_caMensuel.isEmpty) return 1000;
    
    final maxCa = _caMensuel
        .map((e) => _parseDouble(e['chiffre_affaire']))
        .reduce((a, b) => a > b ? a : b);
    
    if (maxCa < 1000) return 100;
    if (maxCa < 10000) return 1000;
    if (maxCa < 100000) return 10000;
    return 50000;
  }

  double _getCumulativeChartInterval(double maxValue) {
    if (maxValue < 1000) return 100;
    if (maxValue < 10000) return 1000;
    if (maxValue < 100000) return 10000;
    if (maxValue < 500000) return 50000;
    return 100000;
  }

  Widget _buildTopClients() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top 10 Clients',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _caParClient.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final client = _caParClient[index];
                final ca = _parseDouble(client['chiffre_affaire']);
                final nbFactures = _parseInt(client['nombre_factures']);
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  title: Text(
                    client['nom'] ?? 'Client inconnu',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('$nbFactures facture${nbFactures > 1 ? 's' : ''}'),
                  trailing: Text(
                    AppFormatters.formatMontant(ca),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
