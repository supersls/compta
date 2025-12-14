import 'package:flutter/material.dart';
import 'journal_comptable_screen.dart';
import 'grand_livre_screen.dart';
import 'bilan_comptable_screen.dart';
import 'compte_resultat_screen.dart';

class DocumentsListScreen extends StatelessWidget {
  const DocumentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documents Comptables',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Consultez et exportez vos documents comptables',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 1200
                    ? 4
                    : MediaQuery.of(context).size.width > 768
                        ? 2
                        : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _DocumentCard(
                    title: 'Journal Comptable',
                    description: 'Enregistrement chronologique des écritures',
                    helpText: 'Le journal comptable est un document obligatoire qui enregistre chronologiquement toutes les opérations comptables de l\'entreprise. Chaque écriture contient une date, un compte débité, un compte crédité, un libellé et un montant. Il permet de suivre l\'historique de toutes les transactions et sert de base pour l\'établissement des autres documents comptables.',
                    icon: Icons.book,
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const JournalComptableScreen(),
                      ),
                    ),
                  ),
                  _DocumentCard(
                    title: 'Grand Livre',
                    description: 'Synthèse des écritures par compte',
                    helpText: 'Le grand livre regroupe toutes les écritures comptables du journal, classées par compte. Pour chaque compte, il présente le solde initial, l\'ensemble des mouvements (débits et crédits) et le solde final. C\'est un outil essentiel pour analyser l\'évolution de chaque compte et vérifier la cohérence de la comptabilité.',
                    icon: Icons.library_books,
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GrandLivreScreen(),
                      ),
                    ),
                  ),
                  _DocumentCard(
                    title: 'Bilan Comptable',
                    description: 'Patrimoine de l\'entreprise',
                    helpText: 'Le bilan comptable est une photographie du patrimoine de l\'entreprise à un instant T. Il présente l\'actif (ce que possède l\'entreprise : immobilisations, stocks, créances, trésorerie) et le passif (ce que doit l\'entreprise : capitaux propres, dettes). L\'actif et le passif doivent toujours être équilibrés.',
                    icon: Icons.account_balance,
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BilanComptableScreen(),
                      ),
                    ),
                  ),
                  _DocumentCard(
                    title: 'Compte de Résultat',
                    description: 'Performance de l\'exercice',
                    helpText: 'Le compte de résultat présente la performance économique de l\'entreprise sur une période donnée (généralement un exercice). Il liste tous les produits (ventes, prestations) et toutes les charges (achats, salaires, impôts, amortissements) pour calculer le résultat net (bénéfice ou perte). Contrairement au bilan qui est une photo à un instant T, le compte de résultat est un film de l\'activité.',
                    icon: Icons.trending_up,
                    color: Colors.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CompteResultatScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final String title;
  final String description;
  final String helpText;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DocumentCard({
    required this.title,
    required this.description,
    required this.helpText,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 48,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  Icons.help_outline,
                  color: color,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(icon, color: color),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(title),
                          ),
                        ],
                      ),
                      content: SingleChildScrollView(
                        child: Text(
                          helpText,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fermer'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onTap();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Consulter'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
