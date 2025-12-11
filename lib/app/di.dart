import 'package:ledgerone/app/services/analytics_service_impl.dart';
import 'package:ledgerone/app/services/cache_service_impl.dart';
import 'package:ledgerone/app/services/crash_service_impl.dart';
import 'package:ledgerone/app/services/dev/dev_http_client.dart';
import 'package:ledgerone/app/services/http_client_impl.dart';
import 'package:ledgerone/app/services/lifecycle_service_impl.dart';
import 'package:ledgerone/app/services/localization_service_impl.dart';
import 'package:ledgerone/app/services/logging_service_impl.dart';
import 'package:ledgerone/app/services/network_service_impl.dart';
import 'package:ledgerone/app/services/theme_service_impl.dart';
import 'package:ledgerone/core/config/environment.dart';
import 'package:ledgerone/core/contracts/cache_contract.dart';
import 'package:ledgerone/core/contracts/config_provider.dart';
import 'package:ledgerone/core/contracts/i18n_contract.dart';
import 'package:ledgerone/core/contracts/lifecycle_contract.dart';
import 'package:ledgerone/core/contracts/logging_contract.dart';
import 'package:ledgerone/core/contracts/network_contract.dart';
import 'package:ledgerone/core/contracts/theme_contract.dart';
import 'package:ledgerone/core/network/http_client_contract.dart';
import 'package:ledgerone/core/observability/analytics_allowlist.dart';
import 'package:ledgerone/core/observability/performance_tracker.dart';
import 'package:ledgerone/features/ledger/di.dart';

import '../core/contracts/analytics_contract.dart';
import '../core/contracts/config_contract.dart';
import '../core/contracts/crash_contract.dart';
import '../core/contracts/guard_contract.dart';
import '../core/contracts/navigation_contract.dart';
import '../core/contracts/storage_contract.dart';
import '../core/runtime/launch_state.dart';
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

  final storage = await SharedPrefsStorageService.create();
  locator.register<StorageService>(storage);

  final localization = LocalizationServiceImpl(storage: storage);
  await localization.initialize();
  locator.register<LocalizationService>(localization);

  final themeService = ThemeServiceImpl(storage: storage);
  await themeService.initialize();
  locator.register<ThemeService>(themeService);

  late final NetworkService network;
  switch (appConfig.environment) {
    case Environment.prod:
      network = NetworkServiceImpl();
      break;
    case Environment.dev:
    case Environment.test:
      network = NetworkServiceImpl();
      break;
    case Environment.stage:
      throw UnimplementedError();
  }

  await network.initialize();
  locator.register<NetworkService>(network);

  final cache = CacheServiceImpl(storage: storage);
  locator.register<CacheService>(cache);

  final lifecycle = AppLifecycleServiceImpl();
  lifecycle.initialize();
  locator.register<AppLifecycleService>(lifecycle);

  final analyticsImpl = AnalyticsServiceImpl(storage: storage, vendor: null);
  await analyticsImpl.initialize();

  final crashImpl = CrashServiceImpl(storage: storage, vendor: null);
  await crashImpl.initialize();

  locator.register<AnalyticsService>(analyticsImpl);
  locator.register<CrashService>(crashImpl);

  final loggingService = LoggingServiceImpl(storage: storage);
  await loggingService.initialize();
  locator.register<LoggingService>(loggingService);

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
    effectiveRemoteProvider = remoteConfigProvider ?? SimulatedRemoteConfig();
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

  final baseHttpClient = HttpClientImpl(config: appConfig);

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

  final launchStateResolver = LaunchStateMachineImpl(
    config: config,
    storage: storage,
  );

  await LedgerModule.register(locator);

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
  final localization = locator.get<LocalizationService>();

  final guards = <NavigationGuard>[OnboardingGuard(storage)];

  final result = RouterFactory.create(
    initialRoute: initialRoute,
    guards: guards,
    locator: locator,
    localization: localization,
  );

  locator.register<NavigationService>(result.navigationService);

  if (crash is CrashServiceImpl) {
    crash.recordNavigation('(launch)', initialRoute);
  }

  return result;
}
