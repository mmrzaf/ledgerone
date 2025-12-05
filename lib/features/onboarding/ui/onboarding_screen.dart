import 'package:flutter/material.dart';

import '../../../app/di.dart';
import '../../../core/contracts/analytics_contract.dart';
import '../../../core/contracts/i18n_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/contracts/storage_contract.dart';
import '../../../core/i18n/string_keys.dart';
import '../../../core/observability/analytics_allowlist.dart';

class OnboardingScreen extends StatefulWidget {
  final StorageService storage;
  final NavigationService navigation;

  const OnboardingScreen({
    required this.storage,
    required this.navigation,
    super.key,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  AnalyticsService? _analytics;

  @override
  void initState() {
    super.initState();

    try {
      _analytics = ServiceLocator().get<AnalyticsService>();
    } catch (_) {
      _analytics = null;
    }

    _analytics?.logScreenView('onboarding');
    _analytics?.logEvent(AnalyticsAllowlist.onboardingView.name);
  }

  Future<void> _handleComplete() async {
    await widget.storage.setBool('onboarding_seen', true);
    await _analytics?.logEvent(AnalyticsAllowlist.onboardingComplete.name);
    widget.navigation.replaceRoute('home');
  }

  Future<void> _handleSkip() async {
    await widget.storage.setBool('onboarding_seen', true);
    await _analytics?.logEvent(AnalyticsAllowlist.onboardingSkip.name);
    widget.navigation.replaceRoute('home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
              Text(
                l10n.get(L10nKeys.onboardingTitle),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.get(L10nKeys.onboardingSubtitle),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _handleComplete,
                child: Text(l10n.get(L10nKeys.onboardingGetStarted)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _handleSkip,
                child: Text(l10n.get(L10nKeys.onboardingSkip)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
