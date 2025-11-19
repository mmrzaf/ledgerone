import 'package:flutter/material.dart';

import '../../../app/di.dart';
import '../../../core/contracts/auth_contract.dart';
import '../../../core/contracts/config_contract.dart';
import '../../../core/contracts/navigation_contract.dart';

class HomeScreen extends StatelessWidget {
  final AuthService authService;
  final NavigationService navigation;

  final ConfigService _config = ServiceLocator().get<ConfigService>();

  HomeScreen({required this.authService, required this.navigation, super.key});

  Future<void> _handleLogout() async {
    await authService.logout();
    navigation.clearAndGoTo('login');
  }

  @override
  Widget build(BuildContext context) {
    final showPromo = _config.getFlag('home.promo_banner.enabled');
    final variant = _config.getString('ui.theme_variant');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showPromo) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: const Text(
                    '✨ New Feature Enabled!',
                    style: TextStyle(
                      color: Colors.brown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],

              const Icon(
                Icons.check_circle_outline,
                size: 100,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Variant: $variant',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              FutureBuilder<String?>(
                future: authService.userId,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'User ID: ${snapshot.data}',
                            style: TextStyle(color: Colors.blue.shade900),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
