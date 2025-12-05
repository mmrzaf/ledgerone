import 'package:app_flutter_starter/app/services/analytics_service_impl.dart';
import 'package:app_flutter_starter/app/services/cache_service_impl.dart';
import 'package:app_flutter_starter/app/services/crash_service_impl.dart';
import 'package:app_flutter_starter/app/services/lifecycle_service_impl.dart';
import 'package:app_flutter_starter/app/services/localization_service_impl.dart';
import 'package:app_flutter_starter/app/services/network_service_impl.dart';
import 'package:app_flutter_starter/app/services/theme_service_impl.dart';
import 'package:app_flutter_starter/core/config/environment.dart';
import 'package:app_flutter_starter/core/contracts/cache_contract.dart';
import 'package:app_flutter_starter/core/contracts/config_provider.dart';
import 'package:app_flutter_starter/core/contracts/i18n_contract.dart';
import 'package:app_flutter_starter/core/contracts/lifecycle_contract.dart';
import 'package:app_flutter_starter/core/contracts/network_contract.dart';
import 'package:app_flutter_starter/core/contracts/theme_contract.dart';
import 'package:app_flutter_starter/core/observability/analytics_allowlist.dart';
import 'package:app_flutter_starter/core/observability/performance_tracker.dart';

import '../core/contracts/analytics_contract.dart';
import '../core/contracts/auth_contract.dart';
import '../core/contracts/config_contract.dart';
import '../core/contracts/crash_contract.dart';
import '../core/contracts/navigation_contract.dart';
import '../core/contracts/storage_contract.dart';
import '../core/runtime/launch_state.dart';
import 'boot/launch_state_machine.dart';
import 'navigation/guards/auth_guard.dart';
import 'navigation/guards/no_auth_guard.dart';
import 'navigation/guards/onboarding_guard.dart';
import 'navigation/router.dart';
import 'services/config_service_impl.dart';
import 'services/mock_services.dart';
import 'services/simulated_remote_config.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();
  final Map<Type, dynamic> _services = {};

  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service $T not registered');
    }
    return service as T;
  }

  void register<T>(T service) {
    _services[T] = service;
  }

  void clear() {
    _services.clear();
  }
}

class DISetupResult {
  final LaunchStateResolver launchStateResolver;
  final ServiceLocator locator;
  DISetupResult({required this.launchStateResolver, required this.locator});
}

Future<DISetupResult> setupDependencies(
  AppConfig appConfig, {
  RemoteConfigProvider? remoteConfigProvider,
}) async {
  final locator = ServiceLocator();
  locator.register<AppConfig>(appConfig);

  // Core services
  final storage = MockStorageService();
  final auth = MockAuthService();

  locator.register<StorageService>(storage);
  locator.register<AuthService>(auth);

  // Localization service (must initialize early)
  final localization = LocalizationServiceImpl(storage: storage);
  await localization.initialize();
  locator.register<LocalizationService>(localization);

  // Theme service (must initialize early)
  final themeService = ThemeServiceImpl(storage: storage);
  await themeService.initialize();
  locator.register<ThemeService>(themeService);

  // Network monitoring
  final network = SimulatedNetworkService();
  await network.initialize();
  locator.register<NetworkService>(network);

  // Cache service
  final cache = CacheServiceImpl(storage: storage);
  locator.register<CacheService>(cache);

  // Lifecycle monitoring
  final lifecycle = AppLifecycleServiceImpl();
  lifecycle.initialize();
  locator.register<AppLifecycleService>(lifecycle);

  // Observability services - initialize with consent management
  final analyticsImpl = AnalyticsServiceImpl(
    storage: storage,
    vendor: null, // Replace with real vendor in production
  );
  await analyticsImpl.initialize();

  final crashImpl = CrashServiceImpl(
    storage: storage,
    vendor: null, // Replace with real vendor in production
  );
  await crashImpl.initialize();

  locator.register<AnalyticsService>(analyticsImpl);
  locator.register<CrashService>(crashImpl);

  // Config service with performance tracking
  PerformanceTracker().start(PerformanceMetrics.configLoad);

  final config = ConfigServiceImpl(
    storage: storage,
    remoteProvider: remoteConfigProvider ?? SimulatedRemoteConfig(),
  );

  await config.initialize();

  final configMetric = PerformanceTracker().stop(PerformanceMetrics.configLoad);
  if (configMetric != null) {
    await analyticsImpl.logEvent(
      AnalyticsAllowlist.configLoaded.name,
      parameters: {'source': 'remote', 'duration_ms': configMetric.durationMs},
    );
  }

  locator.register<ConfigService>(config);

  final launchStateResolver = LaunchStateMachineImpl(
    config: config,
    storage: storage,
    auth: auth,
  );

  return DISetupResult(
    launchStateResolver: launchStateResolver,
    locator: locator,
  );
}

RouterFactoryResult createRouter({
  required String initialRoute,
  required ServiceLocator locator,
}) {
  final storage = locator.get<StorageService>();
  final auth = locator.get<AuthService>();
  final crash = locator.get<CrashService>() as CrashServiceImpl;

  final guards = [OnboardingGuard(storage), AuthGuard(auth), NoAuthGuard(auth)];

  final result = RouterFactory.create(
    initialRoute: initialRoute,
    guards: guards,
    storage: storage,
    auth: auth,
    config: locator.get<ConfigService>(),
    network: locator.get<NetworkService>(),
    cache: locator.get<CacheService>(),
    lifecycle: locator.get<AppLifecycleService>(),
    localization: locator.get<LocalizationService>(),
  );

  locator.register<NavigationService>(result.navigationService);

  // Record initial navigation
  crash.recordNavigation('(launch)', initialRoute);

  return result;
}
