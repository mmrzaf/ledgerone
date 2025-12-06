import 'package:flutter/material.dart';
import '../../../app/di.dart';
import '../../../core/contracts/analytics_contract.dart';
import '../../../core/contracts/i18n_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/contracts/storage_contract.dart';
import '../../../core/i18n/string_keys.dart';
import '../../../core/observability/analytics_allowlist.dart';

class OnboardingPage {
  final String titleKey;
  final String descriptionKey;
  final IconData icon;
  final Color color;

  const OnboardingPage({
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    required this.color,
  });
}

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
  final PageController _pageController = PageController();
  int _currentPage = 0;
  AnalyticsService? _analytics;

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      titleKey: L10nKeys.ledgerOnboardingFeature1Title,
      descriptionKey: L10nKeys.ledgerOnboardingFeature1Desc,
      icon: Icons.account_balance_wallet,
      color: Color(0xFF2563EB),
    ),
    const OnboardingPage(
      titleKey: L10nKeys.ledgerOnboardingFeature2Title,
      descriptionKey: L10nKeys.ledgerOnboardingFeature2Desc,
      icon: Icons.cloud_off,
      color: Color(0xFF7C3AED),
    ),
    const OnboardingPage(
      titleKey: L10nKeys.ledgerOnboardingFeature3Title,
      descriptionKey: L10nKeys.ledgerOnboardingFeature3Desc,
      icon: Icons.security,
      color: Color(0xFF16A34A),
    ),
  ];

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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    await widget.storage.setBool('onboarding_seen', true);
    await _analytics?.logEvent(AnalyticsAllowlist.onboardingComplete.name);

    if (mounted) {
      widget.navigation.replaceRoute('dashboard');
    }
  }

  Future<void> _skip() async {
    await widget.storage.setBool('onboarding_seen', true);
    await _analytics?.logEvent(AnalyticsAllowlist.onboardingSkip.name);

    if (mounted) {
      widget.navigation.replaceRoute('dashboard');
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.get(L10nKeys.ledgerAppTitle),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _skip,
                    child: Text(l10n.get(L10nKeys.onboardingSkip)),
                  ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(context, _pages[index], l10n);
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildPageIndicator(index, theme),
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        child: Text(
                          l10n.get(L10nKeys.ledgerOnboardingPrevious),
                        ),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: _currentPage == 0 ? 1 : 2,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? l10n.get(L10nKeys.ledgerOnboardingGetStarted)
                            : l10n.get(L10nKeys.ledgerOnboardingNext),
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

  Widget _buildPage(
    BuildContext context,
    OnboardingPage page,
    LocalizationService l10n,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with animated container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 64, color: page.color),
          ),

          const SizedBox(height: 40),

          // Title
          Text(
            l10n.get(page.titleKey),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: page.color,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            l10n.get(page.descriptionKey),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index, ThemeData theme) {
    final isActive = index == _currentPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
