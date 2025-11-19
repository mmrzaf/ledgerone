import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app_flutter_starter/core/contracts/storage_contract.dart';
import 'package:app_flutter_starter/core/contracts/auth_contract.dart';
import 'package:app_flutter_starter/core/contracts/guard_contract.dart';
import 'package:app_flutter_starter/app/navigation/guards/onboarding_guard.dart';
import 'package:app_flutter_starter/app/navigation/guards/auth_guard.dart';
import 'package:app_flutter_starter/app/navigation/guards/no_auth_guard.dart';

class MockStorageService extends Mock implements StorageService {}

class MockAuthService extends Mock implements AuthService {}

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

  group('AuthGuard', () {
    late MockAuthService auth;
    late AuthGuard guard;

    setUp(() {
      auth = MockAuthService();
      guard = AuthGuard(auth);
    });

    test('has correct priority', () {
      expect(guard.priority, 10);
    });

    test('allows navigation to login screen', () async {
      final result = await guard.evaluate('login', null);
      expect(result, isA<GuardAllow>());
    });

    test('allows navigation to onboarding screen', () async {
      final result = await guard.evaluate('onboarding', null);
      expect(result, isA<GuardAllow>());
    });

    test('redirects to login when not authenticated', () async {
      when(() => auth.isAuthenticated).thenAnswer((_) async => false);
      when(() => auth.refreshSession()).thenThrow(Exception('No session'));

      final result = await guard.evaluate('home', null);

      expect(result, isA<GuardRedirect>());
      expect((result as GuardRedirect).targetRouteId, 'login');
    });

    test('allows navigation when authenticated', () async {
      when(() => auth.isAuthenticated).thenAnswer((_) async => true);

      final result = await guard.evaluate('home', null);

      expect(result, isA<GuardAllow>());
    });

    test('attempts silent refresh before redirecting', () async {
      when(() => auth.isAuthenticated).thenAnswer((_) async => false);
      when(() => auth.refreshSession()).thenAnswer((_) async {});

      await guard.evaluate('home', null);

      verify(() => auth.refreshSession()).called(1);
    });

    test('allows navigation if refresh succeeds', () async {
      var callCount = 0;
      when(() => auth.isAuthenticated).thenAnswer((_) async {
        callCount++;
        return callCount > 1; // First false, then true after refresh
      });
      when(() => auth.refreshSession()).thenAnswer((_) async {});

      final result = await guard.evaluate('home', null);

      expect(result, isA<GuardAllow>());
      verify(() => auth.refreshSession()).called(1);
    });
  });

  group('NoAuthGuard', () {
    late MockAuthService auth;
    late NoAuthGuard guard;

    setUp(() {
      auth = MockAuthService();
      guard = NoAuthGuard(auth);
    });

    test('has correct priority', () {
      expect(guard.priority, 20);
    });

    test('allows navigation to non-login screens', () async {
      final result = await guard.evaluate('home', null);
      expect(result, isA<GuardAllow>());
    });

    test('redirects to home when authenticated user tries login', () async {
      when(() => auth.isAuthenticated).thenAnswer((_) async => true);

      final result = await guard.evaluate('login', null);

      expect(result, isA<GuardRedirect>());
      expect((result as GuardRedirect).targetRouteId, 'home');
    });

    test('allows login when not authenticated', () async {
      when(() => auth.isAuthenticated).thenAnswer((_) async => false);

      final result = await guard.evaluate('login', null);

      expect(result, isA<GuardAllow>());
    });
  });

  group('Guard Priority Order', () {
    test('guards are ordered by priority', () {
      final storage = MockStorageService();
      final auth = MockAuthService();

      final guards = [
        NoAuthGuard(auth),
        AuthGuard(auth),
        OnboardingGuard(storage),
      ];

      guards.sort((a, b) => a.priority.compareTo(b.priority));

      expect(guards[0], isA<OnboardingGuard>());
      expect(guards[1], isA<AuthGuard>());
      expect(guards[2], isA<NoAuthGuard>());
    });
  });
}
