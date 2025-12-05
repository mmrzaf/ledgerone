import 'package:app_flutter_starter/app/boot/launch_state_machine.dart';
import 'package:app_flutter_starter/core/contracts/config_contract.dart';
import 'package:app_flutter_starter/core/contracts/storage_contract.dart';
import 'package:app_flutter_starter/core/runtime/launch_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockConfigService extends Mock implements ConfigService {}

class MockStorageService extends Mock implements StorageService {}

void main() {
  group('LaunchState', () {
    test('determineInitialRoute returns onboarding when not seen', () {
      const state = LaunchState(onboardingSeen: false);

      expect(state.determineInitialRoute(), 'onboarding');
    });

    test('determineInitialRoute returns home when authenticated', () {
      const state = LaunchState(onboardingSeen: true);

      expect(state.determineInitialRoute(), 'home');
    });

    test('determineInitialRoute returns login when not authenticated', () {
      const state = LaunchState(onboardingSeen: true);

      expect(state.determineInitialRoute(), 'login');
    });

    test('onboarding takes precedence over authentication', () {
      const state = LaunchState(onboardingSeen: false);

      expect(state.determineInitialRoute(), 'onboarding');
    });

    test('toString provides useful debug info', () {
      const state = LaunchState(
        onboardingSeen: true,
        initialDeepLink: '/some/path',
      );

      final str = state.toString();
      expect(str, contains('onboarded: true'));
      expect(str, contains('authenticated: false'));
      expect(str, contains('deepLink: /some/path'));
    });
  });

  group('LaunchStateMachineImpl', () {
    late MockConfigService config;
    late MockStorageService storage;
    late LaunchStateMachineImpl stateMachine;

    setUp(() {
      config = MockConfigService();
      storage = MockStorageService();
      stateMachine = LaunchStateMachineImpl(config: config, storage: storage);

      // Default setup
      when(() => config.initialize()).thenAnswer((_) async {});
      when(
        () => storage.getBool('onboarding_seen'),
      ).thenAnswer((_) async => false);
    });

    test('initializes config service first', () async {
      await stateMachine.resolve();

      verify(() => config.initialize()).called(1);
    });

    test('checks onboarding status', () async {
      await stateMachine.resolve();

      verify(() => storage.getBool('onboarding_seen')).called(1);
    });

    test('returns correct state for first-time user', () async {
      when(
        () => storage.getBool('onboarding_seen'),
      ).thenAnswer((_) async => false);

      final state = await stateMachine.resolve();

      expect(state.onboardingSeen, false);
      expect(state.determineInitialRoute(), 'onboarding');
    });

    test('handles missing onboarding flag as false', () async {
      when(
        () => storage.getBool('onboarding_seen'),
      ).thenAnswer((_) async => null);

      final state = await stateMachine.resolve();

      expect(state.onboardingSeen, false);
    });
  });
}
