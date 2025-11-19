import '../core/contracts/config_contract.dart';
import '../core/contracts/storage_contract.dart';
import '../core/contracts/auth_contract.dart';
import '../core/contracts/analytics_contract.dart';
import '../core/contracts/crash_contract.dart';
import '../core/contracts/navigation_contract.dart';
import '../core/runtime/launch_state.dart';
import 'services/mock_services.dart';
import 'boot/launch_state_machine.dart';
import 'navigation/router.dart';
import 'navigation/guards/onboarding_guard.dart';
import 'navigation/guards/auth_guard.dart';
import 'navigation/guards/no_auth_guard.dart';

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

Future<DISetupResult> setupDependencies() async {
  final locator = ServiceLocator();

  final config = MockConfigService();
  final storage = MockStorageService();
  final auth = MockAuthService();
  final analytics = MockAnalyticsService();
  final crash = MockCrashService();

  locator.register<ConfigService>(config);
  locator.register<StorageService>(storage);
  locator.register<AuthService>(auth);
  locator.register<AnalyticsService>(analytics);
  locator.register<CrashService>(crash);

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
