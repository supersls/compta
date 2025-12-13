import 'package:flutter/material.dart';
import '../services/facture_service_http.dart';
import '../services/banque_service.dart';
import '../services/tva_service.dart';
import '../services/immobilisation_service.dart';
import '../utils/formatters.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FactureService _factureService = FactureService();
  final BanqueService _banqueService = BanqueService();
  final TVAService _tvaService = TVAService();
  final ImmobilisationService _immobilisationService = ImmobilisationService();

  bool _isLoading = true;
  Map<String, dynamic>? _factureStats;
  Map<String, dynamic>? _banqueStats;
  Map<String, dynamic>? _tvaStats;
  List<Map<String, dynamic>> _immobilisationStats = [];

  // KPI values
  double _chiffreAffaires = 0;
  double _charges = 0;
  double _tresorerie = 0;
  double _benefice = 0;
  int _facteuresEnRetard = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // Load factures stats
      final factureStats = await _factureService.getFacturesStats();
      
      // Load banque stats
      final banqueStats = await _banqueService.getStatistiques();
      
      // Load TVA stats
      final tvaStats = await _tvaService.getTVAStats();
      
      // Load immobilisations
      final immobilisations = await _immobilisationService.getAllImmobilisations();

      // Calculate KPIs
      _chiffreAffaires = (factureStats['totalVentes'] as num?)?.toDouble() ?? 0;
      _facteuresEnRetard = (factureStats['countRetard'] as num?)?.toInt() ?? 0;
      _tresorerie = (banqueStats['totalTresorerie'] as num?)?.toDouble() ?? 0;
      
      // Calculate charges (achats + TVA à payer)
      _charges = (factureStats['totalAchats'] as num?)?.toDouble() ?? 0;
      _benefice = _chiffreAffaires - _charges;

      setState(() {
        _factureStats = factureStats;
        _banqueStats = banqueStats;
        _tvaStats = tvaStats;
        _immobilisationStats = immobilisations.map((e) => e.toMap()).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement dashboard: $e');
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
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildKPICards(),
                const SizedBox(height: 24),
                _buildAlertes(),
                const SizedBox(height: 24),
                _buildResume(),
                const SizedBox(height: 100),
              ],
            ),
          );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tableau de Bord',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Bienvenue dans votre tableau de bord comptable',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildKPICards() {
    return Column(
      children: [
        // Row 1: CA et Charges
        Row(
          children: [
            Expanded(
              child: _KPICard(
                title: 'Chiffre d\'affaires',
                value: AppFormatters.formatMontant(_chiffreAffaires),
                icon: Icons.trending_up,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _KPICard(
                title: 'Charges',
                value: AppFormatters.formatMontant(_charges),
                icon: Icons.trending_down,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Row 2: Bénéfice et Trésorerie
        Row(
          children: [
            Expanded(
              child: _KPICard(
                title: 'Bénéfice',
                value: AppFormatters.formatMontant(_benefice),
                icon: Icons.account_balance,
                color: _benefice >= 0 ? Colors.blue : Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _KPICard(
                title: 'Trésorerie',
                value: AppFormatters.formatMontant(_tresorerie),
                icon: Icons.euro,
                color: _tresorerie >= 0 ? Colors.purple : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Alertes (${_facteuresEnRetard})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_facteuresEnRetard > 0)
              _AlertItem(
                title: '$_facteuresEnRetard facture(s) en retard',
                subtitle: 'Vérifiez vos factures impayées',
                icon: Icons.warning_amber,
                color: Colors.red,
              )
            else
              _AlertItem(
                title: 'Toutes les factures à jour',
                subtitle: 'Aucune facture en retard',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            if (_factureStats != null && 
                ((_factureStats!['countImpayees'] as int?) ?? 0) > 0) ...[
              const SizedBox(height: 12),
              _AlertItem(
                title: '${_factureStats!['countImpayees']} facture(s) impayée(s)',
                subtitle: 'Montant: ${AppFormatters.formatMontant(_factureStats!['totalImpayees'] ?? 0)}',
                icon: Icons.money_off,
                color: Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResume() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (_factureStats != null)
              _ResumeItem(
                label: 'Factures de vente',
                value: '${_factureStats!['countVentes'] ?? 0}',
                subtitle: 'Total: ${AppFormatters.formatMontant(_chiffreAffaires)}',
              ),
            const SizedBox(height: 12),
            if (_banqueStats != null)
              _ResumeItem(
                label: 'Comptes bancaires',
                value: '${_banqueStats!['totalComptes'] ?? 0}',
                subtitle: 'Solde total: ${AppFormatters.formatMontant(_tresorerie)}',
              ),
            const SizedBox(height: 12),
            _ResumeItem(
              label: 'Immobilisations',
              value: '${_immobilisationStats.length}',
              subtitle: 'Actifs en service',
            ),
          ],
        ),
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _AlertItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
    );
  }
}

class _ResumeItem extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;

  const _ResumeItem({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
