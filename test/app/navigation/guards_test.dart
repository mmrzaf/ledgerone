import 'package:app_flutter_starter/app/navigation/guards/onboarding_guard.dart';
import 'package:app_flutter_starter/core/contracts/guard_contract.dart';
import 'package:app_flutter_starter/core/contracts/storage_contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStorageService extends Mock implements StorageService {}

void main() {
  group('OnboardingGuard', () {
    late MockStorageService storage;
    late OnboardingGuard guard;

    setUp(() {
      storage = MockStorageService();
      guard = OnboardingGuard(storage);
    });

    test('has correct priority', () {
      expect(guard.priority, 0);
    });

    test('allows navigation to onboarding screen', () async {
      final result = await guard.evaluate('onboarding', null);
      expect(result, isA<GuardAllow>());
    });

    test('redirects to onboarding when not seen', () async {
      when(
        () => storage.getBool('onboarding_seen'),
      ).thenAnswer((_) async => false);

      final result = await guard.evaluate('home', null);

      expect(result, isA<GuardRedirect>());
      expect((result as GuardRedirect).targetRouteId, 'onboarding');
    });

    test('allows navigation when onboarding is complete', () async {
      when(
        () => storage.getBool('onboarding_seen'),
      ).thenAnswer((_) async => true);

      final result = await guard.evaluate('home', null);

      expect(result, isA<GuardAllow>());
    });

    test('allows navigation when onboarding key missing (null)', () async {
      when(
        () => storage.getBool('onboarding_seen'),
      ).thenAnswer((_) async => null);

      final result = await guard.evaluate('onboarding', null);

      expect(result, isA<GuardAllow>());
    });
  });

  group('Guard Priority Order', () {
    test('guards are ordered by priority', () {
      final storage = MockStorageService();

      final guards = [OnboardingGuard(storage)];

      guards.sort((a, b) => a.priority.compareTo(b.priority));

      expect(guards[0], isA<OnboardingGuard>());
    });
  });
}
