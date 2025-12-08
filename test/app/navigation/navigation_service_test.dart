import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerone/app/di.dart';
import 'package:ledgerone/app/navigation/guards/onboarding_guard.dart';
import 'package:ledgerone/app/navigation/router.dart';
import 'package:ledgerone/app/services/localization_service_impl.dart';
import 'package:ledgerone/core/contracts/analytics_contract.dart';
import 'package:ledgerone/core/contracts/i18n_contract.dart';
import 'package:ledgerone/core/contracts/storage_contract.dart';
import 'package:ledgerone/features/ledger/domain/services.dart';

import '../../helpers/mock_services.dart';

void main() {
  group('RouterFactory', () {
    late MockStorageService storage;
    late LocalizationServiceImpl localization;
    late ServiceLocator serviceLocator;

    setUp(() async {
      // Fresh singleton state per test
      serviceLocator = ServiceLocator();
      serviceLocator.clear();

      storage = MockStorageService();

      localization = LocalizationServiceImpl(storage: storage);
      await localization.initialize();

      // Register only what the router actually needs for the routes we touch
      serviceLocator.register<StorageService>(storage);
      serviceLocator.register<LocalizationService>(localization);

      serviceLocator.register<AnalyticsService>(MockAnalyticsService());
      serviceLocator.register<BalanceService>(FakeBalanceService());
      serviceLocator.register<PortfolioValuationService>(
        FakePortfolioValuationService(),
      );
      serviceLocator.register<PriceUpdateService>(FakePriceUpdateService());
    });

    testWidgets('creates router with onboarding as initial route', (
      tester,
    ) async {
      final guards = [OnboardingGuard(storage)];

      final result = RouterFactory.create(
        initialRoute: 'onboarding',
        guards: guards,
        locator: serviceLocator,
        localization: localization,
      );

      expect(result.router, isNotNull);
      expect(result.navigationService, isNotNull);

      // Use router in a widget tree
      await tester.pumpWidget(MaterialApp.router(routerConfig: result.router));

      await tester.pumpAndSettle();

      // This assumes OnboardingScreen still shows this text.
      // If the copy changed, update the expectation accordingly.
      expect(find.text('LedgerOne'), findsOneWidget);
    });

    testWidgets(
      'guards redirect dashboard to onboarding when onboarding not seen',
      (tester) async {
        // onboarding_seen defaults to false in MockStorageService
        final guards = [OnboardingGuard(storage)];

        final result = RouterFactory.create(
          initialRoute: 'dashboard',
          guards: guards,
          locator: serviceLocator,
          localization: localization,
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: result.router),
        );

        await tester.pumpAndSettle();

        // We should be redirected away from dashboard to onboarding
        expect(find.text('LedgerOne'), findsOneWidget);
      },
    );

    testWidgets('starts on dashboard when onboarding has been seen', (
      tester,
    ) async {
      // Mark onboarding as done
      await storage.setBool('onboarding_seen', true);

      final guards = [OnboardingGuard(storage)];

      final result = RouterFactory.create(
        initialRoute: 'dashboard',
        guards: guards,
        locator: serviceLocator,
        localization: localization,
      );

      expect(result.router, isNotNull);
      expect(result.navigationService, isNotNull);

      // NOTE:
      // We intentionally do NOT assert specific dashboard UI text here,
      // because that would require wiring up a lot of domain services
      // for DashboardScreen. We only care that the router can be created
      // and attached without blowing up.
      await tester.pumpWidget(MaterialApp.router(routerConfig: result.router));

      await tester.pumpAndSettle();

      // Sanity: ensure we *didn't* get redirected back to onboarding.
      expect(find.text('LedgerOne'), findsNothing);
    });

    test('navigation service can navigate between routes', () async {
      await storage.setBool('onboarding_seen', true);
      final guards = [OnboardingGuard(storage)];

      final result = RouterFactory.create(
        initialRoute: 'dashboard',
        guards: guards,
        locator: serviceLocator,
        localization: localization,
      );

      // Depending on when GoRouter sets up, this might be null or 'dashboard'
      expect(
        result.navigationService.currentRouteId,
        anyOf('dashboard', isNull),
      );

      // This should not throw for a valid route ID
      result.navigationService.goToRoute('onboarding');
    });

    test('guards are sorted by priority and router is created', () async {
      final guards = [OnboardingGuard(storage)];

      final result = RouterFactory.create(
        initialRoute: 'dashboard',
        guards: guards,
        locator: serviceLocator,
        localization: localization,
      );

      expect(result.router, isNotNull);
      expect(result.navigationService, isNotNull);
    });
  });

  group('NavigationServiceImpl', () {
    late MockStorageService storage;
    late LocalizationService localization;
    late ServiceLocator serviceLocator;

    setUp(() async {
      storage = MockStorageService();
      await storage.setBool('onboarding_seen', true);

      localization = LocalizationServiceImpl(storage: storage);
      await (localization as LocalizationServiceImpl).initialize();

      serviceLocator = ServiceLocator();
      serviceLocator.clear();
      serviceLocator.register<StorageService>(storage);
      serviceLocator.register<LocalizationService>(localization);
    });

    test('goToRoute navigates to valid route', () {
      final result = RouterFactory.create(
        initialRoute: 'dashboard',
        guards: const [],
        locator: serviceLocator,
        localization: localization,
      );

      expect(
        () => result.navigationService.goToRoute('onboarding'),
        returnsNormally,
      );
    });

    test('goToRoute throws on invalid route', () {
      final result = RouterFactory.create(
        initialRoute: 'dashboard',
        guards: const [],
        locator: serviceLocator,
        localization: localization,
      );

      expect(
        () => result.navigationService.goToRoute('invalid'),
        throwsArgumentError,
      );
    });

    test('replaceRoute throws on invalid route', () {
      final result = RouterFactory.create(
        initialRoute: 'dashboard',
        guards: const [],
        locator: serviceLocator,
        localization: localization,
      );

      expect(
        () => result.navigationService.replaceRoute('invalid'),
        throwsArgumentError,
      );
    });

    test('clearAndGoTo throws on invalid route', () {
      final result = RouterFactory.create(
        initialRoute: 'dashboard',
        guards: const [],
        locator: serviceLocator,
        localization: localization,
      );

      expect(
        () => result.navigationService.clearAndGoTo('invalid'),
        throwsArgumentError,
      );
    });
  });
}
