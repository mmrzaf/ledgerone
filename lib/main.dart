import 'package:app_flutter_starter/core/contracts/analytics_contract.dart';
import 'package:app_flutter_starter/core/contracts/i18n_contract.dart';
import 'package:app_flutter_starter/core/contracts/theme_contract.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'core/config/environment.dart';
import 'core/observability/analytics_allowlist.dart';
import 'core/observability/performance_tracker.dart';

void main() async {
  // Mark app start
  PerformanceTracker().start(PerformanceMetrics.coldStart);

  WidgetsFlutterBinding.ensureInitialized();

  const config = AppConfig.dev;

  // Phase 1: Setup dependencies (includes i18n and theme initialization)
  PerformanceTracker().mark('di_start');
  final diSetup = await setupDependencies(config);
  PerformanceTracker().mark('di_complete');

  // Phase 2: Resolve launch state
  PerformanceTracker().mark('launch_state_start');
  final launchState = await diSetup.launchStateResolver.resolve();
  final initialRoute = launchState.determineInitialRoute();
  PerformanceTracker().mark('launch_state_complete');

  debugPrint('Launch state: $launchState');
  debugPrint('Initial route: $initialRoute');

  // Phase 3: Create router with determined initial route
  PerformanceTracker().mark('router_start');
  final routerResult = createRouter(
    initialRoute: initialRoute,
    locator: diSetup.locator,
  );
  PerformanceTracker().mark('router_complete');

  // Measure DI and launch phases
  PerformanceTracker().measure('di_setup', 'di_start', 'di_complete');
  PerformanceTracker().measure(
    'launch_state_resolution',
    'launch_state_start',
    'launch_state_complete',
  );

  // Get services for app widget
  final localization = diSetup.locator.get<LocalizationService>();
  final themeService = diSetup.locator.get<ThemeService>();

  // Phase 4: Run app with i18n and theme support
  runApp(
    App(
      router: routerResult.router,
      localization: localization,
      themeService: themeService,
    ),
  );

  // Record cold start completion after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final coldStartMetric = PerformanceTracker().stop(
      PerformanceMetrics.coldStart,
      metadata: {'cold_start': true},
    );

    // Log to analytics
    if (coldStartMetric != null) {
      final analytics = diSetup.locator.get<AnalyticsService>();
      analytics.logEvent(
        AnalyticsAllowlist.appLaunch.name,
        parameters: {
          'cold_start': true,
          'duration_ms': coldStartMetric.durationMs,
        },
      );
    }
  });
}
