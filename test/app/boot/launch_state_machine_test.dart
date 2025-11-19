import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app_flutter_starter/core/contracts/config_contract.dart';
import 'package:app_flutter_starter/core/contracts/storage_contract.dart';
import 'package:app_flutter_starter/core/contracts/auth_contract.dart';
import 'package:app_flutter_starter/core/runtime/launch_state.dart';
import 'package:app_flutter_starter/app/boot/launch_state_machine.dart';

class MockConfigService extends Mock implements ConfigService {}

class MockStorageService extends Mock implements StorageService {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('LaunchState', () {
    test('determineInitialRoute returns onboarding when not seen', () {
      const state = LaunchState(onboardingSeen: false, isAuthenticated: false);

      expect(state.determineInitialRoute(), 'onboarding');
    });

    test('determineInitialRoute returns home when authenticated', () {
      const state = LaunchState(onboardingSeen: true, isAuthenticated: true);

      expect(state.determineInitialRoute(), 'home');
    });

    test('determineInitialRoute returns login when not authenticated', () {
      const state = LaunchState(onboardingSeen: true, isAuthenticated: false);

      expect(state.determineInitialRoute(), 'login');
    });

    test('onboarding takes precedence over authentication', () {
      const state = LaunchState(onboardingSeen: false, isAuthenticated: true);

      expect(state.determineInitialRoute(), 'onboarding');
    });

    test('toString provides useful debug info', () {
      const state = LaunchState(
        onboardingSeen: true,
        isAuthenticated: false,
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
    late MockAuthService auth;
    late LaunchStateMachineImpl stateMachine;

    setUp(() {
      config = MockConfigService();
      storage = MockStorageService();
      auth = MockAuthService();
      stateMachine = LaunchStateMachineImpl(
        config: config,
        storage: storage,
        auth: auth,
      );

      // Default setup
      when(() => config.initialize()).thenAnswer((_) async {});
      when(
        () => storage.getBool('onboarding_seen'),
      ).thenAnswer((_) async => false);
      when(() => auth.isAuthenticated).thenAnswer((_) async => false);
    });

    test('initializes config service first', () async {
      await stateMachine.resolve();

      verify(() => config.initialize()).called(1);
    });

    test('checks onboarding status', () async {
      await stateMachine.resolve();

      verify(() => storage.getBool('onboarding_seen')).called(1);
    });

    test('checks authentication status', () async {
      await stateMachine.resolve();

      verify(() => auth.isAuthenticated).called(greaterThanOrEqualTo(1));
    });

    test('returns correct state for first-time user', () async {
      when(
        () => storage.getBool('onboarding_seen'),
      ).thenAnswer((_) async => false);
      when(() => auth.isAuthenticated).thenAnswer((_) async => false);

      final state = await stateMachine.resolve();

      expect(state.onboardingSeen, false);
      expect(state.isAuthenticated, false);
      expect(state.determineInitialRoute(), 'onboarding');
    });

    test('returns correct state for returning authenticated user', () async {
      when(
        () => storage.getBool('onboarding_seen'),
      ).thenAnswer((_) async => true);
      when(() => auth.isAuthenticated).thenAnswer((_) async => true);
      when(() => auth.refreshSession()).thenAnswer((_) async {});

      final state = await stateMachine.resolve();

      expect(state.onboardingSeen, true);
      expect(state.isAuthenticated, true);
      expect(state.determineInitialRoute(), 'home');
    });

    test('returns correct state for returning unauthenticated user', () async {
      when(
        () => storage.getBool('onboarding_seen'),
      ).thenAnswer((_) async => true);
      when(() => auth.isAuthenticated).thenAnswer((_) async => false);

      final state = await stateMachine.resolve();

      expect(state.onboardingSeen, true);
      expect(state.isAuthenticated, false);
      expect(state.determineInitialRoute(), 'login');
    });

    test('attempts silent refresh for authenticated users', () async {
      when(
        () => storage.getBool('onboarding_seen'),
      ).thenAnswer((_) async => true);
      when(() => auth.isAuthenticated).thenAnswer((_) async => true);
      when(() => auth.refreshSession()).thenAnswer((_) async {});

      await stateMachine.resolve();

      verify(() => auth.refreshSession()).called(1);
    });

    test('handles failed refresh gracefully', () async {
      var callCount = 0;
      when(
        () => storage.getBool('onboarding_seen'),
      ).thenAnswer((_) async => true);
      when(() => auth.isAuthenticated).thenAnswer((_) async {
        callCount++;
        return callCount == 1;
      });
      when(() => auth.refreshSession()).thenThrow(Exception('Refresh failed'));

      final state = await stateMachine.resolve();

      expect(state.isAuthenticated, false);
      expect(state.determineInitialRoute(), 'login');
    });

    test('handles missing onboarding flag as false', () async {
      when(
        () => storage.getBool('onboarding_seen'),
      ).thenAnswer((_) async => null);
      when(() => auth.isAuthenticated).thenAnswer((_) async => false);

      final state = await stateMachine.resolve();

      expect(state.onboardingSeen, false);
    });
  });
}
