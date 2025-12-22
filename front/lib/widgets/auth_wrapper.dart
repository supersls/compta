import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/entreprise_provider.dart';
import '../screens/login_screen.dart';
import '../main.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('🔍 AuthWrapper - isAuthenticated: ${authProvider.isAuthenticated}');
        
        // Show login screen if not authenticated
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // Show dashboard if authenticated
        return Consumer<EntrepriseProvider>(
          builder: (context, provider, child) {
            return AdminDashboard(
              key: ValueKey(provider.selectedEntreprise?.id ?? 0),
            );
          },
        );
      },
    );
  }
}
