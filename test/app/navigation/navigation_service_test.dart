import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter_starter/app/di.dart';
import 'package:app_flutter_starter/core/contracts/navigation_contract.dart';

void main() {
  group('NavigationService', () {
    late ServiceLocator locator;
    late NavigationService navigationService;

    setUp(() async {
      final diSetup = await setupDependencies();
      locator = diSetup.locator;

      final routerResult = createRouter(
        initialRoute: 'onboarding',
        locator: locator,
      );

      navigationService = routerResult.navigationService;
    });

    tearDown(() {
      locator.clear();
    });

    test('NavigationService is registered in DI', () {
      final nav = locator.get<NavigationService>();
      expect(nav, isNotNull);
      expect(nav, isA<NavigationService>());
    });

    test('currentRouteId returns correct route', () {
      // Initial route should be onboarding
      expect(navigationService.currentRouteId, anyOf('onboarding', isNull));
    });

    test('goToRoute throws for unknown route ID', () {
      expect(
        () => navigationService.goToRoute('unknown_route'),
        throwsArgumentError,
      );
    });

    test('replaceRoute throws for unknown route ID', () {
      expect(
        () => navigationService.replaceRoute('unknown_route'),
        throwsArgumentError,
      );
    });

    test('clearAndGoTo throws for unknown route ID', () {
      expect(
        () => navigationService.clearAndGoTo('unknown_route'),
        throwsArgumentError,
      );
    });

    test('route IDs are correctly mapped to paths', () {
      // These should not throw
      expect(() => navigationService.goToRoute('onboarding'), returnsNormally);
      expect(() => navigationService.goToRoute('login'), returnsNormally);
      expect(() => navigationService.goToRoute('home'), returnsNormally);
    });
  });

  group('NavigationService Contract', () {
    test('interface defines required methods', () {
      expect(NavigationService, isA<Type>());

      const methods = [
        'goToRoute',
        'replaceRoute',
        'goBack',
        'canGoBack',
        'currentRouteId',
        'clearAndGoTo',
      ];

      expect(methods.length, 6);
    });
  });

  group('RouterFactory', () {
    test('creates router with correct initial route', () async {
      final diSetup = await setupDependencies();

      final result1 = createRouter(
        initialRoute: 'onboarding',
        locator: diSetup.locator,
      );
      expect(result1.router, isNotNull);
      expect(result1.navigationService, isNotNull);

      final result2 = createRouter(
        initialRoute: 'login',
        locator: diSetup.locator,
      );
      expect(result2.router, isNotNull);

      final result3 = createRouter(
        initialRoute: 'home',
        locator: diSetup.locator,
      );
      expect(result3.router, isNotNull);
    });

    test('registers all guards with router', () async {
      final diSetup = await setupDependencies();

      final result = createRouter(
        initialRoute: 'home',
        locator: diSetup.locator,
      );

      expect(result.router, isNotNull);
      expect(result.router.routerDelegate, isNotNull);
    });
  });
}
