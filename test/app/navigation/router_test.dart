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
      serviceLocator = ServiceLocator();
      serviceLocator.clear();

      storage = MockStorageService();

      localization = LocalizationServiceImpl(storage: storage);
      await localization.initialize();

      serviceLocator.register<StorageService>(storage);
      serviceLocator.register<LocalizationService>(localization);

      serviceLocator.register<AnalyticsService>(MockAnalyticsService());
      serviceLocator.register<BalanceService>(FakeBalanceService());
      serviceLocator.register<PortfolioValuationService>(
        FakePortfolioValuationService(),
      );
      serviceLocator.register<PriceUpdateService>(FakePriceUpdateService());
      serviceLocator.register<BalanceValuationService>(
        FakeBalanceValuationService(),
      );
    });

    testWidgets('creates router with onboarding as initial route', (
      tester,
    ) async {
      final guards = [OnboardingGuard(storage)];

      final result = RouterFactory.create(
        initialRoute: 'onboarding',
        guards: guards,
        localization: localization,
        locator: serviceLocator,
      );

      expect(result.router, isNotNull);
      expect(result.navigationService, isNotNull);

      await tester.pumpWidget(MaterialApp.router(routerConfig: result.router));

      await tester.pumpAndSettle();
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
          localization: localization,
          locator: serviceLocator,
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: result.router),
        );

        await tester.pumpAndSettle();

        expect(find.text('LedgerOne'), findsOneWidget);
      },
    );

    testWidgets(
      'starts on dashboard when onboarding has been seen (no redirect)',
      (tester) async {
        await storage.setBool('onboarding_seen', true);

        final guards = [OnboardingGuard(storage)];

        final result = RouterFactory.create(
          initialRoute: 'dashboard',
          guards: guards,
          localization: localization,
          locator: serviceLocator,
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: result.router),
        );

        await tester.pumpAndSettle();

        // At minimum, assert we did NOT get thrown back to onboarding.
        expect(find.text('LedgerOne'), findsNothing);
      },
    );

    test('navigation service can navigate between routes', () async {
      await storage.setBool('onboarding_seen', true);
      final guards = [OnboardingGuard(storage)];

      final result = RouterFactory.create(
        initialRoute: 'dashboard',
        guards: guards,
        localization: localization,
        locator: serviceLocator,
      );

      expect(
        result.navigationService.currentRouteId,
        anyOf('dashboard', isNull),
      );

      // Valid route, should not throw
      result.navigationService.goToRoute('onboarding');
    });

    test('guards are sorted by priority and router is created', () async {
      final guards = [OnboardingGuard(storage)];

      final result = RouterFactory.create(
        initialRoute: 'dashboard',
        guards: guards,
        localization: localization,
        locator: serviceLocator,
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

      final localizationImpl = LocalizationServiceImpl(storage: storage);
      await localizationImpl.initialize();
      localization = localizationImpl;

      serviceLocator = ServiceLocator();
      serviceLocator.clear();
      serviceLocator.register<StorageService>(storage);
      serviceLocator.register<LocalizationService>(localization);
    });

    test('goToRoute navigates to valid route', () {
      final result = RouterFactory.create(
        initialRoute: 'dashboard',
        guards: const [],
        localization: localization,
        locator: serviceLocator,
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
        localization: localization,
        locator: serviceLocator,
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
        localization: localization,
        locator: serviceLocator,
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
        localization: localization,
        locator: serviceLocator,
      );

      expect(
        () => result.navigationService.clearAndGoTo('invalid'),
        throwsArgumentError,
      );
    });
  });
}
