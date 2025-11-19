import '../../core/contracts/auth_contract.dart';
import '../../core/contracts/config_contract.dart';
import '../../core/contracts/storage_contract.dart';
import '../../core/runtime/launch_state.dart';

class LaunchStateMachineImpl implements LaunchStateResolver {
  final ConfigService _config;
  final StorageService _storage;
  final AuthService _auth;

  LaunchStateMachineImpl({
    required ConfigService config,
    required StorageService storage,
    required AuthService auth,
  }) : _config = config,
       _storage = storage,
       _auth = auth;

  @override
  Future<LaunchState> resolve() async {
    // 1. Initialize configuration (loads cached, then refreshes)
    await _config.initialize();

    // 2. Check onboarding status
    final onboardingSeen = await _storage.getBool('onboarding_seen') ?? false;

    // 3. Check authentication and attempt silent refresh
    bool isAuthenticated = await _auth.isAuthenticated;

    if (isAuthenticated) {
      try {
        await _auth.refreshSession();
        isAuthenticated = await _auth.isAuthenticated;
      } catch (_) {
        isAuthenticated = false;
      }
    }

    // 4. TODO: Capture deep link intent (platform-specific)
    const String? initialDeepLink = null;

    return LaunchState(
      onboardingSeen: onboardingSeen,
      isAuthenticated: isAuthenticated,
      initialDeepLink: initialDeepLink,
    );
  }
}
