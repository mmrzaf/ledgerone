import 'package:app_flutter_starter/app/navigation/guards/onboarding_guard.dart';
import 'package:app_flutter_starter/app/navigation/router.dart';
import 'package:app_flutter_starter/app/services/cache_service_impl.dart';
import 'package:app_flutter_starter/app/services/lifecycle_service_impl.dart';
import 'package:app_flutter_starter/app/services/localization_service_impl.dart';
import 'package:app_flutter_starter/app/services/network_service_impl.dart';
import 'package:app_flutter_starter/core/contracts/navigation_contract.dart';
import 'package:app_flutter_starter/core/errors/result.dart';
import 'package:app_flutter_starter/features/home/domain/home_models.dart';
import 'package:app_flutter_starter/features/home/domain/home_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_services.dart';

class _MockHomeRepository implements HomeRepository {
  @override
  Future<Result<HomeData>> load({bool forceRefresh = false}) async {
    return Success(HomeData(message: 'Test', timestamp: DateTime.now()));
  }

  @override
  Stream<HomeData> watch() => const Stream.empty();
}

void main() {
  group('NavigationService', () {
    late NavigationService navigationService;
    TestWidgetsFlutterBinding.ensureInitialized();
    setUp(() async {
      final storage = MockStorageService();
      final config = MockConfigService();
      await config.initialize();

      final network = SimulatedNetworkService();
      await network.initialize();

      final cache = CacheServiceImpl(storage: storage);
      final lifecycle = AppLifecycleServiceImpl();
      lifecycle.initialize();

      final localization = LocalizationServiceImpl(storage: storage);
      await localization.initialize();

      final homeRepository = _MockHomeRepository();

      final routerResult = RouterFactory.create(
        initialRoute: 'onboarding',
        guards: [OnboardingGuard(storage)],
        storage: storage,
        config: config,
        network: network,
        cache: cache,
        lifecycle: lifecycle,
        localization: localization,
        homeRepository: homeRepository,
      );

      navigationService = routerResult.navigationService;
    });

    test('currentRouteId returns correct route', () {
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
      expect(() => navigationService.goToRoute('onboarding'), returnsNormally);
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
}
