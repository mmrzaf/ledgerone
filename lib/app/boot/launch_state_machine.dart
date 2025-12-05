import '../../core/contracts/config_contract.dart';
import '../../core/contracts/storage_contract.dart';
import '../../core/runtime/launch_state.dart';

class LaunchStateMachineImpl implements LaunchStateResolver {
  final ConfigService _config;
  final StorageService _storage;

  LaunchStateMachineImpl({
    required ConfigService config,
    required StorageService storage,
  }) : _config = config,
       _storage = storage;

  @override
  Future<LaunchState> resolve() async {
    //  Initialize configuration (loads cached, then refreshes)
    await _config.initialize();

    //  Check onboarding status
    final onboardingSeen = await _storage.getBool('onboarding_seen') ?? false;

    //  TODO: Capture deep link intent (platform-specific)
    const String? initialDeepLink = null;

    return LaunchState(
      onboardingSeen: onboardingSeen,
      initialDeepLink: initialDeepLink,
    );
  }
}
