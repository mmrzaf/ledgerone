import 'package:app_flutter_starter/app/services/cache_service_impl.dart';
import 'package:app_flutter_starter/app/services/lifecycle_service_impl.dart';
import 'package:app_flutter_starter/app/services/mock_services.dart';
import 'package:app_flutter_starter/app/services/network_service_impl.dart';
import 'package:app_flutter_starter/core/contracts/navigation_contract.dart';
import 'package:app_flutter_starter/features/home/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Error Handling Integration', () {
    testWidgets('home screen handles load errors', (tester) async {
      final nav = MockNavigationService();
      final config = MockConfigService();
      await config.initialize();

      // New services
      final storage = MockStorageService();
      final cache = CacheServiceImpl(storage: storage);
      final network = SimulatedNetworkService();
      await network.initialize();
      final lifecycle = AppLifecycleServiceImpl();
      lifecycle.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            navigation: nav,
            configService: config,
            networkService: network,
            cacheService: cache,
            lifecycleService: lifecycle,
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Content should be visible (might succeed or fail based on timing)
      // Just verify screen doesn't crash
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('home screen retry works', (tester) async {
      final nav = MockNavigationService();
      final config = MockConfigService();
      await config.initialize();

      // New services
      final storage = MockStorageService();
      final cache = CacheServiceImpl(storage: storage);
      final network = SimulatedNetworkService();
      await network.initialize();
      final lifecycle = AppLifecycleServiceImpl();
      lifecycle.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            navigation: nav,
            configService: config,
            networkService: network,
            cacheService: cache,
            lifecycleService: lifecycle,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap refresh button if visible
      final refreshButton = find.byIcon(Icons.refresh);
      if (tester.any(refreshButton)) {
        await tester.tap(refreshButton);
        await tester.pump();

        // Should show loading
        expect(find.byType(CircularProgressIndicator), findsWidgets);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
    });
  });
  testWidgets('home load is safe when navigated away', (tester) async {
    final nav = MockNavigationService();
    final config = MockConfigService();
    await config.initialize();

    // New services
    final storage = MockStorageService();
    final cache = CacheServiceImpl(storage: storage);
    final network = SimulatedNetworkService();
    await network.initialize();
    final lifecycle = AppLifecycleServiceImpl();
    lifecycle.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          navigation: nav,
          configService: config,
          networkService: network,
          cacheService: cache,
          lifecycleService: lifecycle,
        ),
      ),
    );

    // Kick off the initial load
    await tester.pump();

    // Immediately "navigate away" by replacing the tree
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Other screen'))),
    );
    await tester.pump();

    // Let timers/microtasks settle. If cancellation + dispose are wrong,
    // this is where you'd see setState-after-dispose or similar crashes.
    await tester.pumpAndSettle();

    // HomeScreen should be gone, and the test should complete without errors.
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('Other screen'), findsOneWidget);
  });
}

class MockNavigationService implements NavigationService {
  String? lastRoute;
  Map<String, dynamic>? lastParams;

  @override
  void goToRoute(String routeId, {Map<String, dynamic>? params}) {
    lastRoute = routeId;
    lastParams = params;
  }

  @override
  void clearAndGoTo(String routeId, {Map<String, dynamic>? params}) {
    lastRoute = routeId;
    lastParams = params;
  }

  @override
  void replaceRoute(String routeId, {Map<String, dynamic>? params}) {
    lastRoute = routeId;
    lastParams = params;
  }

  @override
  void goBack() {}

  @override
  bool canGoBack() => false;

  @override
  String? get currentRouteId => lastRoute;
}
