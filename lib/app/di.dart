import 'package:app_flutter_starter/core/config/environment.dart';
import 'package:app_flutter_starter/core/contracts/config_provider.dart';

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

  final storage = MockStorageService();
  final analytics = MockAnalyticsService();
  final crash = MockCrashService();
  final auth = MockAuthService();

  final config = ConfigServiceImpl(
    storage: storage,
    remoteProvider: remoteConfigProvider ?? SimulatedRemoteConfig(),
  );

  locator.register<StorageService>(storage);
  locator.register<AnalyticsService>(analytics);
  locator.register<CrashService>(crash);
  locator.register<AuthService>(auth);

  await config.initialize();
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
  final guards = [OnboardingGuard(storage), AuthGuard(auth), NoAuthGuard(auth)];

  final result = RouterFactory.create(
    initialRoute: initialRoute,
    guards: guards,
    storage: storage,
    auth: auth,
  );
  locator.register<NavigationService>(result.navigationService);

  return result;
}
