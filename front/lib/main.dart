import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/entreprise_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/clients/clients_list_screen.dart';
import 'screens/chiffre_affaire/chiffre_affaire_screen.dart';
import 'screens/factures/factures_list_screen.dart';
import 'screens/tva/tva_list_screen.dart';
import 'screens/tva/calculateur_tva_screen.dart';
import 'screens/immobilisations/immobilisations_list_screen.dart';
import 'screens/banque/banque_list_screen.dart';
import 'screens/documents/documents_list_screen.dart';
import 'screens/administration/administration_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(
    ChangeNotifierProvider(
      create: (_) => EntrepriseProvider()..loadEntreprises(),
      child: const ComptaApp(),
    ),
  );
}

class ComptaApp extends StatelessWidget {
  const ComptaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Compta EI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: Consumer<EntrepriseProvider>(
        builder: (context, provider, child) {
          // Utiliser l'ID de l'entreprise comme clé pour forcer le rebuild complet
          return AdminDashboard(
            key: ValueKey(provider.selectedEntreprise?.id ?? 0),
          );
        },
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  bool _isDrawerExpanded = true;
  final Set<int> _expandedMenuItems = {};

  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.dashboard_outlined,
      'selectedIcon': Icons.dashboard,
      'label': 'Tableau de bord',
      'screen': const DashboardScreen(),
    },
    {
      'icon': Icons.people_outlined,
      'selectedIcon': Icons.people,
      'label': 'Clients',
      'screen': const ClientsListScreen(),
    },
    {
      'icon': Icons.trending_up_outlined,
      'selectedIcon': Icons.trending_up,
      'label': 'Chiffre d\'Affaires',
      'screen': const ChiffreAffaireScreen(),
    },
    {
      'icon': Icons.receipt_long_outlined,
      'selectedIcon': Icons.receipt_long,
      'label': 'Factures',
      'screen': const FacturesListScreen(),
    },
    {
      'icon': Icons.money_outlined,
      'selectedIcon': Icons.money,
      'label': 'TVA',
      'screen': const TVAListScreen(),
      'children': [
        {
          'icon': Icons.list_alt_outlined,
          'selectedIcon': Icons.list_alt,
          'label': 'Déclarations',
          'screen': const TVAListScreen(),
        },
        {
          'icon': Icons.calculate_outlined,
          'selectedIcon': Icons.calculate,
          'label': 'Calculateur',
          'screen': const CalculateurTVAScreen(),
        },
      ],
    },
    {
      'icon': Icons.account_balance_wallet_outlined,
      'selectedIcon': Icons.account_balance_wallet,
      'label': 'Banque',
      'screen': const BanqueListScreen(),
    },
    {
      'icon': Icons.business_center_outlined,
      'selectedIcon': Icons.business_center,
      'label': 'Immobilisations',
      'screen': const ImmobilisationsListScreen(),
    },
    {
      'icon': Icons.description_outlined,
      'selectedIcon': Icons.description,
      'label': 'Documents',
      'screen': const DocumentsListScreen(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar navigation (desktop/tablet)
          if (isTablet)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isDrawerExpanded ? 260 : 80,
              child: _buildSidebar(),
            ),
          
          // Main content area
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, isTablet),
                Expanded(
                  child: _getScreenForIndex(_selectedIndex),
                ),
              ],
            ),
          ),
        ],
      ),
      // Mobile drawer
      drawer: !isTablet ? _buildMobileDrawer() : null,
    );
  }

  Widget _buildTopBar(BuildContext context, bool isTablet) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (!isTablet)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          const SizedBox(width: 8),
          Text(
            _getScreenTitle(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Dropdown pour sélectionner l'entreprise
          Consumer<EntrepriseProvider>(
            builder: (context, provider, child) {
              if (provider.entreprises.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.business,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: provider.selectedEntreprise?.id,
                      underline: const SizedBox(),
                      isDense: true,
                      items: provider.entreprises.map((entreprise) {
                        return DropdownMenuItem<int>(
                          value: entreprise.id,
                          child: Text(
                            entreprise.nom,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (int? newId) {
                        if (newId != null) {
                          final entreprise = provider.entreprises
                              .firstWhere((e) => e.id == newId);
                          provider.selectEntreprise(entreprise);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const Spacer(),
          // Search bar (desktop only)
          if (MediaQuery.of(context).size.width >= 1200)
            Container(
              width: 300,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          const SizedBox(width: 16),
          // Notifications
          Badge(
            label: const Text('3'),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 8),
          // User profile
          PopupMenuButton<String>(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.person, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 8),
                if (MediaQuery.of(context).size.width >= 1200)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'admin@compta.fr',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Profil'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'administration',
                child: ListTile(
                  leading: Icon(Icons.admin_panel_settings_outlined),
                  title: Text('Administration'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Déconnexion'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'administration') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdministrationScreen(),
                  ),
                );
              }
              // Handle other menu selections
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo/Brand
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                if (_isDrawerExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Compta EI',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(
                    _isDrawerExpanded ? Icons.chevron_left : Icons.chevron_right,
                  ),
                  onPressed: () {
                    setState(() => _isDrawerExpanded = !_isDrawerExpanded);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) => _buildMenuItem(index),
            ),
          ),
          
          // Settings at bottom
          const Divider(height: 1),
          if (_isDrawerExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exercice 2024',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: 0.75,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '9 mois sur 12',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index) {
    final item = _menuItems[index];
    final hasChildren = item['children'] != null && (item['children'] as List).isNotEmpty;
    final isExpanded = _expandedMenuItems.contains(index);
    final isSelected = _selectedIndex == index;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Material(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () {
                if (hasChildren && _isDrawerExpanded) {
                  setState(() {
                    if (isExpanded) {
                      _expandedMenuItems.remove(index);
                    } else {
                      _expandedMenuItems.add(index);
                    }
                  });
                } else {
                  setState(() => _selectedIndex = index);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? item['selectedIcon'] : item['icon'],
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    if (_isDrawerExpanded) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item['label'],
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasChildren)
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasChildren && isExpanded && _isDrawerExpanded)
          ...((item['children'] as List).asMap().entries.map((entry) {
            final childIndex = entry.key;
            final child = entry.value as Map<String, dynamic>;
            final childGlobalIndex = index * 100 + childIndex + 1;
            final isChildSelected = _selectedIndex == childGlobalIndex;
            
            return Padding(
              padding: const EdgeInsets.only(left: 24, right: 8, top: 2, bottom: 2),
              child: Material(
                color: isChildSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => setState(() => _selectedIndex = childGlobalIndex),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isChildSelected ? child['selectedIcon'] : child['icon'],
                          size: 20,
                          color: isChildSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            child['label'],
                            style: TextStyle(
                              fontSize: 13,
                              color: isChildSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: isChildSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          })),
      ],
    );
  }

  Widget _getScreenForIndex(int index) {
    if (index > 100) {
      final parentIndex = index ~/ 100;
      final childIndex = (index % 100) - 1;
      final parent = _menuItems[parentIndex];
      if (parent['children'] != null) {
        final children = parent['children'] as List;
        if (childIndex < children.length) {
          return children[childIndex]['screen'] as Widget;
        }
      }
    }
    
    if (index < _menuItems.length) {
      return _menuItems[index]['screen'] as Widget;
    }
    
    return _menuItems[0]['screen'] as Widget;
  }

  String _getScreenTitle() {
    if (_selectedIndex > 100) {
      final parentIndex = _selectedIndex ~/ 100;
      final childIndex = (_selectedIndex % 100) - 1;
      final parent = _menuItems[parentIndex];
      if (parent['children'] != null) {
        final children = parent['children'] as List;
        if (childIndex < children.length) {
          return children[childIndex]['label'] as String;
        }
      }
    }
    
    if (_selectedIndex < _menuItems.length) {
      return _menuItems[_selectedIndex]['label'] as String;
    }
    
    return _menuItems[0]['label'] as String;
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.account_balance,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  'Compta EI',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Comptabilité simplifiée',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(_menuItems.length, (index) {
            final item = _menuItems[index];
            return ListTile(
              leading: Icon(
                _selectedIndex == index ? item['selectedIcon'] : item['icon'],
              ),
              title: Text(item['label']),
              selected: _selectedIndex == index,
              onTap: () {
                setState(() => _selectedIndex = index);
                Navigator.pop(context);
              },
            );
          }),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Paramètres'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// Placeholders pour les écrans
class DashboardPlaceholder extends StatelessWidget {
  const DashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Tableau de Bord',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _KPICard(
                title: 'Chiffre d\'affaires',
                value: '45 000 €',
                icon: Icons.trending_up,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _KPICard(
                title: 'Charges',
                value: '25 000 €',
                icon: Icons.trending_down,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _KPICard(
                title: 'Bénéfice',
                value: '20 000 €',
                icon: Icons.account_balance,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _KPICard(
                title: 'Trésorerie',
                value: '12 000 €',
                icon: Icons.euro,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Alertes (3)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _AlertItem(
                  title: 'Facture #123 en retard',
                  subtitle: 'Échéance dépassée de 5 jours',
                ),
                _AlertItem(
                  title: 'Déclaration TVA',
                  subtitle: 'À faire avant le 15/12/2024',
                ),
                _AlertItem(
                  title: 'Paiement fournisseur',
                  subtitle: 'Échéance le 20/12/2024',
                ),
              ],
            ),
          ),
        ),
      ],
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
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

  const _AlertItem({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        child: Icon(Icons.warning_amber),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class TVAPlaceholder extends StatelessWidget {
  const TVAPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.money, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Gestion de la TVA',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'À implémenter',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class ImmobilisationsPlaceholder extends StatelessWidget {
  const ImmobilisationsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_center, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Gestion des Immobilisations',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'À implémenter',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentsPlaceholder extends StatelessWidget {
  const DocumentsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Documents Comptables',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'À implémenter',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
