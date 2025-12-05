import 'package:app_flutter_starter/app/services/analytics_service_impl.dart';
import 'package:app_flutter_starter/app/services/cache_service_impl.dart';
import 'package:app_flutter_starter/app/services/crash_service_impl.dart';
import 'package:app_flutter_starter/app/services/dev/dev_http_client.dart';
import 'package:app_flutter_starter/app/services/http_client_impl.dart';
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
import 'package:app_flutter_starter/core/network/http_client_contract.dart';
import 'package:app_flutter_starter/core/observability/analytics_allowlist.dart';
import 'package:app_flutter_starter/core/observability/performance_tracker.dart';

import '../core/contracts/analytics_contract.dart';
import '../core/contracts/config_contract.dart';
import '../core/contracts/crash_contract.dart';
import '../core/contracts/guard_contract.dart';
import '../core/contracts/navigation_contract.dart';
import '../core/contracts/storage_contract.dart';
import '../core/runtime/launch_state.dart';
import '../features/home/data/home_local_data_source.dart';
import '../features/home/data/home_remote_data_source.dart';
import '../features/home/data/home_repository_impl.dart';
import '../features/home/domain/home_repository.dart';
import 'boot/launch_state_machine.dart';
import 'navigation/guards/onboarding_guard.dart';
import 'navigation/router.dart';
import 'services/config_service_impl.dart';
import 'services/shared_prefs_storage_service.dart';
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

  // ---------------------------------------------------------------------------
  // Storage (real implementation, no mocks in app DI)
  // ---------------------------------------------------------------------------
  // You implement SharedPrefsStorageService (or whatever name you chose)
  final storage = await SharedPrefsStorageService.create();
  locator.register<StorageService>(storage);

  // ---------------------------------------------------------------------------
  // Localization – must be ready before MaterialApp
  // ---------------------------------------------------------------------------
  final localization = LocalizationServiceImpl(storage: storage);
  await localization.initialize();
  locator.register<LocalizationService>(localization);

  // ---------------------------------------------------------------------------
  // Theme – must also be ready before MaterialApp
  // ---------------------------------------------------------------------------
  final themeService = ThemeServiceImpl(storage: storage);
  await themeService.initialize();
  locator.register<ThemeService>(themeService);

  // ---------------------------------------------------------------------------
  // Network – real impl in v0.8 (connectivity_plus etc.)
  // SimulatedNetworkService should move to test/dev-only.
  // ---------------------------------------------------------------------------
  late final NetworkService network;
  switch (appConfig.environment) {
    case Environment.prod:
      network = NetworkServiceImpl(); // real connectivity-backed impl
      break;
    case Environment.dev:
    case Environment.test:
      network = NetworkServiceImpl(); // still real; tests can use a fake
      break;
    case Environment.stage:
      // TODO: Handle this case.
      throw UnimplementedError();
  }

  await network.initialize();
  locator.register<NetworkService>(network);

  // ---------------------------------------------------------------------------
  // Cache (in-memory + persistent via StorageService)
  // ---------------------------------------------------------------------------
  final cache = CacheServiceImpl(storage: storage);
  locator.register<CacheService>(cache);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  final lifecycle = AppLifecycleServiceImpl();
  lifecycle.initialize();
  locator.register<AppLifecycleService>(lifecycle);

  // ---------------------------------------------------------------------------
  // Observability (Analytics + Crash)
  // Vendor integrations are still TODO – DI is ready for them.
  // ---------------------------------------------------------------------------
  final analyticsImpl = AnalyticsServiceImpl(
    storage: storage,
    vendor: null, // wire your real vendor here
  );
  await analyticsImpl.initialize();

  final crashImpl = CrashServiceImpl(
    storage: storage,
    vendor: null, // wire your real crash vendor here
  );
  await crashImpl.initialize();

  locator.register<AnalyticsService>(analyticsImpl);
  locator.register<CrashService>(crashImpl);

  // ---------------------------------------------------------------------------
  // Config (defaults + cache + remote provider)
  // In prod we *require* a real RemoteConfigProvider.
  // In dev/test we fall back to SimulatedRemoteConfig if none provided.
  // ---------------------------------------------------------------------------
  PerformanceTracker().start(PerformanceMetrics.configLoad);

  final RemoteConfigProvider effectiveRemoteProvider;
  if (appConfig.environment == Environment.prod) {
    if (remoteConfigProvider == null) {
      throw StateError(
        'RemoteConfigProvider must be provided in production. '
        'Wire your real remote config implementation into setupDependencies().',
      );
    }
    effectiveRemoteProvider = remoteConfigProvider;
  } else {
    effectiveRemoteProvider =
        remoteConfigProvider ?? SimulatedRemoteConfig(); // dev-only default
  }

  final config = ConfigServiceImpl(
    storage: storage,
    remoteProvider: effectiveRemoteProvider,
  );

  await config.initialize();

  final configMetric = PerformanceTracker().stop(PerformanceMetrics.configLoad);
  if (configMetric != null) {
    await analyticsImpl.logEvent(
      AnalyticsAllowlist.configLoaded.name,
      parameters: {
        'source': effectiveRemoteProvider.runtimeType.toString(),
        'duration_ms': configMetric.durationMs,
      },
    );
  }

  locator.register<ConfigService>(config);
  // ---------------------------------------------------------------------------
  // HTTP client
  // ---------------------------------------------------------------------------
  // Base HTTP client (real implementation)
  final baseHttpClient = HttpClientImpl(config: appConfig);

  // Wrap in dev client for logging / artificial delay in non-prod
  late final HttpClient httpClient;
  if (appConfig.environment == Environment.dev ||
      appConfig.environment == Environment.test) {
    httpClient =
        DevHttpClient(
              inner: baseHttpClient,
              artificialDelay: const Duration(milliseconds: 300),
            )
            as HttpClient;
  } else {
    httpClient = baseHttpClient as HttpClient;
  }

  locator.register<HttpClient>(httpClient);

  // ---------------------------------------------------------------------------
  // Home feature data layer
  // ---------------------------------------------------------------------------
  final homeLocal = HomeLocalDataSourceImpl(cache);
  final homeRemote = HomeRemoteDataSourceImpl(httpClient);

  final homeRepository = HomeRepositoryImpl(
    remote: homeRemote,
    local: homeLocal,
  );

  locator.register<HomeRepository>(homeRepository);

  // ---------------------------------------------------------------------------
  // Launch state – v0.8 has NO auth; only onboarding & config matter.
  // ---------------------------------------------------------------------------
  final launchStateResolver = LaunchStateMachineImpl(
    config: config,
    storage: storage,
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
  final crash = locator.get<CrashService>();
  final config = locator.get<ConfigService>();
  final network = locator.get<NetworkService>();
  final cache = locator.get<CacheService>();
  final lifecycle = locator.get<AppLifecycleService>();
  final localization = locator.get<LocalizationService>();
  final homeRepository = locator.get<HomeRepository>();
  // Only onboarding guard in v0.8 baseline (no auth).
  final guards = <NavigationGuard>[OnboardingGuard(storage)];

  final result = RouterFactory.create(
    initialRoute: initialRoute,
    guards: guards,
    storage: storage,
    config: config,
    network: network,
    cache: cache,
    lifecycle: lifecycle,
    localization: localization,
    homeRepository: homeRepository,
  );

  locator.register<NavigationService>(result.navigationService);

  // Record initial navigation if crash impl supports it
  if (crash is CrashServiceImpl) {
    crash.recordNavigation('(launch)', initialRoute);
  } else {
    // If you later change CrashServiceImpl, prefer adding a navigation
    // method to the CrashService contract instead of downcasting.
  }

  return result;
}
