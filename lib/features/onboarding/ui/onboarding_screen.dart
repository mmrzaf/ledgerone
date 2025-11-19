import 'package:flutter/material.dart';
import '../../../core/contracts/storage_contract.dart';
import '../../../core/contracts/navigation_contract.dart';

class OnboardingScreen extends StatelessWidget {
  final StorageService storage;
  final NavigationService navigation;

  const OnboardingScreen({
    required this.storage,
    required this.navigation,
    super.key,
  });

  Future<void> _handleComplete() async {
    await storage.setBool('onboarding_seen', true);
    navigation.replaceRoute('home');
  }

  Future<void> _handleSkip() async {
    await storage.setBool('onboarding_seen', true);
    navigation.replaceRoute('login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.rocket_launch, size: 120, color: Colors.blue),
              const SizedBox(height: 32),
              const Text(
                'Welcome to Flutter Starter',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'A production-ready template with navigation, guards, and clean architecture.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _handleComplete,
                child: const Text('Get Started'),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _handleSkip, child: const Text('Skip')),
            ],
          ),
        ),
      ),
    );
  }
}
