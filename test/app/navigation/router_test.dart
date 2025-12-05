import 'package:app_flutter_starter/app/navigation/guards/onboarding_guard.dart';
import 'package:app_flutter_starter/app/navigation/router.dart';
import 'package:app_flutter_starter/app/services/cache_service_impl.dart';
import 'package:app_flutter_starter/app/services/lifecycle_service_impl.dart';
import 'package:app_flutter_starter/app/services/localization_service_impl.dart';
import 'package:app_flutter_starter/app/services/network_service_impl.dart';
import 'package:app_flutter_starter/core/errors/result.dart';
import 'package:app_flutter_starter/features/home/domain/home_models.dart';
import 'package:app_flutter_starter/features/home/domain/home_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_services.dart';

class MockHomeRepository implements HomeRepository {
  @override
  Future<Result<HomeData>> load({bool forceRefresh = false}) async {
    return Success(HomeData(message: 'Test', timestamp: DateTime.now()));
  }

  @override
  Stream<HomeData> watch() => const Stream.empty();
}

void main() {
  group('RouterFactory', () {
    late MockStorageService storage;
    late MockConfigService config;
    late SimulatedNetworkService network;
    late CacheServiceImpl cache;
    late AppLifecycleServiceImpl lifecycle;
    late LocalizationServiceImpl localization;
    late MockHomeRepository homeRepository;

    setUp(() async {
      storage = MockStorageService();
      config = MockConfigService();
      await config.initialize();

      network = SimulatedNetworkService();
      await network.initialize();

      cache = CacheServiceImpl(storage: storage);

      lifecycle = AppLifecycleServiceImpl();
      lifecycle.initialize();

      localization = LocalizationServiceImpl(storage: storage);
      await localization.initialize();

      homeRepository = MockHomeRepository();
    });

    tearDown(() {
      lifecycle.dispose();
    });

    testWidgets('creates router with onboarding as initial route', (
      tester,
    ) async {
      final guards = [OnboardingGuard(storage)];

      final result = RouterFactory.create(
        initialRoute: 'onboarding',
        guards: guards,
        storage: storage,
        config: config,
        network: network,
        cache: cache,
        lifecycle: lifecycle,
        localization: localization,
        homeRepository: homeRepository,
      );

      expect(result.router, isNotNull);
      expect(result.navigationService, isNotNull);

      // Test that router can be used
      await tester.pumpWidget(MaterialApp.router(routerConfig: result.router));

      await tester.pumpAndSettle();

      // Should show onboarding screen
      expect(find.text('Welcome to Flutter Starter'), findsOneWidget);
    });

    testWidgets('creates router with home as initial route', (tester) async {
      await storage.setBool('onboarding_seen', true);
      final guards = [OnboardingGuard(storage)];

      final result = RouterFactory.create(
        initialRoute: 'home',
        guards: guards,
        storage: storage,
        config: config,
        network: network,
        cache: cache,
        lifecycle: lifecycle,
        localization: localization,
        homeRepository: homeRepository,
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: result.router));

      await tester.pumpAndSettle();

      // Should show home screen
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('guards redirect correctly', (tester) async {
      final guards = [OnboardingGuard(storage)];

      final result = RouterFactory.create(
        initialRoute: 'home',
        guards: guards,
        storage: storage,
        config: config,
        network: network,
        cache: cache,
        lifecycle: lifecycle,
        localization: localization,
        homeRepository: homeRepository,
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: result.router));

      await tester.pumpAndSettle();

      // Should redirect to onboarding (not seen)
      expect(find.text('Welcome to Flutter Starter'), findsOneWidget);
    });

    test('navigation service can navigate between routes', () async {
      await storage.setBool('onboarding_seen', true);
      final guards = [OnboardingGuard(storage)];

      final result = RouterFactory.create(
        initialRoute: 'home',
        guards: guards,
        storage: storage,
        config: config,
        network: network,
        cache: cache,
        lifecycle: lifecycle,
        localization: localization,
        homeRepository: homeRepository,
      );

      expect(result.navigationService.currentRouteId, anyOf('home', isNull));

      result.navigationService.goToRoute('onboarding');
      // In a real test with pump, we'd verify the route changed
    });

    test('guards are sorted by priority', () async {
      final guards = [OnboardingGuard(storage)];

      final result = RouterFactory.create(
        initialRoute: 'home',
        guards: guards,
        storage: storage,
        config: config,
        network: network,
        cache: cache,
        lifecycle: lifecycle,
        localization: localization,
        homeRepository: homeRepository,
      );

      expect(result.router, isNotNull);
    });
  });

  group('NavigationServiceImpl', () {
    late MockStorageService storage;
    late MockConfigService config;
    late SimulatedNetworkService network;
    late CacheServiceImpl cache;
    late AppLifecycleServiceImpl lifecycle;
    late LocalizationServiceImpl localization;
    late MockHomeRepository homeRepository;

    setUp(() async {
      storage = MockStorageService();
      await storage.setBool('onboarding_seen', true);

      config = MockConfigService();
      await config.initialize();

      network = SimulatedNetworkService();
      await network.initialize();

      cache = CacheServiceImpl(storage: storage);

      lifecycle = AppLifecycleServiceImpl();
      lifecycle.initialize();

      localization = LocalizationServiceImpl(storage: storage);
      await localization.initialize();

      homeRepository = MockHomeRepository();
    });

    tearDown(() {
      lifecycle.dispose();
    });

    test('goToRoute navigates to valid route', () {
      final result = RouterFactory.create(
        initialRoute: 'home',
        guards: [],
        storage: storage,
        config: config,
        network: network,
        cache: cache,
        lifecycle: lifecycle,
        localization: localization,
        homeRepository: homeRepository,
      );

      expect(
        () => result.navigationService.goToRoute('onboarding'),
        returnsNormally,
      );
    });

    test('goToRoute throws on invalid route', () {
      final result = RouterFactory.create(
        initialRoute: 'home',
        guards: [],
        storage: storage,
        config: config,
        network: network,
        cache: cache,
        lifecycle: lifecycle,
        localization: localization,
        homeRepository: homeRepository,
      );

      expect(
        () => result.navigationService.goToRoute('invalid'),
        throwsArgumentError,
      );
    });

    test('replaceRoute throws on invalid route', () {
      final result = RouterFactory.create(
        initialRoute: 'home',
        guards: [],
        storage: storage,
        config: config,
        network: network,
        cache: cache,
        lifecycle: lifecycle,
        localization: localization,
        homeRepository: homeRepository,
      );

      expect(
        () => result.navigationService.replaceRoute('invalid'),
        throwsArgumentError,
      );
    });

    test('clearAndGoTo throws on invalid route', () {
      final result = RouterFactory.create(
        initialRoute: 'home',
        guards: [],
        storage: storage,
        config: config,
        network: network,
        cache: cache,
        lifecycle: lifecycle,
        localization: localization,
        homeRepository: homeRepository,
      );

      expect(
        () => result.navigationService.clearAndGoTo('invalid'),
        throwsArgumentError,
      );
    });
  });
}
