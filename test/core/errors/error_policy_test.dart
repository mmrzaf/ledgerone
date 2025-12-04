import 'package:app_flutter_starter/core/errors/app_error.dart';
import 'package:app_flutter_starter/core/errors/error_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorPolicyRegistry', () {
    test('all error categories have defined policies', () {
      for (final category in ErrorCategory.values) {
        final policy = ErrorPolicyRegistry.getPolicy(category);
        expect(policy, isNotNull);
        expect(policy.category, equals(category));
      }
    });

    test('network errors allow automatic retry', () {
      final offlinePolicy = ErrorPolicyRegistry.getPolicy(
        ErrorCategory.networkOffline,
      );
      expect(offlinePolicy.retryStrategy, equals(RetryStrategy.automatic));
      expect(offlinePolicy.maxRetries, greaterThan(0));
      expect(offlinePolicy.presentation, equals(ErrorPresentation.banner));
    });

    test('timeout errors allow manual retry', () {
      final policy = ErrorPolicyRegistry.getPolicy(ErrorCategory.timeout);
      expect(policy.retryStrategy, equals(RetryStrategy.manual));
      expect(policy.presentation, equals(ErrorPresentation.inline));
    });

    test('server 5xx errors allow automatic retry with limit', () {
      final policy = ErrorPolicyRegistry.getPolicy(ErrorCategory.server5xx);
      expect(policy.retryStrategy, equals(RetryStrategy.automatic));
      expect(policy.maxRetries, equals(2));
      expect(policy.initialDelay.inSeconds, greaterThan(0));
    });

    test('bad request errors never retry', () {
      final policy = ErrorPolicyRegistry.getPolicy(ErrorCategory.badRequest);
      expect(policy.retryStrategy, equals(RetryStrategy.never));
      expect(policy.maxRetries, equals(0));
    });

    test('invalid credentials errors never retry', () {
      final policy = ErrorPolicyRegistry.getPolicy(
        ErrorCategory.invalidCredentials,
      );
      expect(policy.retryStrategy, equals(RetryStrategy.never));
      expect(policy.maxRetries, equals(0));
      expect(policy.presentation, equals(ErrorPresentation.inline));
    });

    test('token expired errors retry automatically once', () {
      final policy = ErrorPolicyRegistry.getPolicy(ErrorCategory.tokenExpired);
      expect(policy.retryStrategy, equals(RetryStrategy.automatic));
      expect(policy.maxRetries, equals(1));
      expect(policy.presentation, equals(ErrorPresentation.silent));
    });

    test('unauthorized errors shown as banner', () {
      final policy = ErrorPolicyRegistry.getPolicy(ErrorCategory.unauthorized);
      expect(policy.presentation, equals(ErrorPresentation.banner));
      expect(policy.retryStrategy, equals(RetryStrategy.never));
    });

    test('shouldRetry returns correct values', () {
      expect(
        ErrorPolicyRegistry.shouldRetry(ErrorCategory.networkOffline),
        isTrue,
      );
      expect(ErrorPolicyRegistry.shouldRetry(ErrorCategory.timeout), isTrue);
      expect(
        ErrorPolicyRegistry.shouldRetry(ErrorCategory.badRequest),
        isFalse,
      );
      expect(
        ErrorPolicyRegistry.shouldRetry(ErrorCategory.invalidCredentials),
        isFalse,
      );
    });

    test('allowsAutomaticRetry returns correct values', () {
      expect(
        ErrorPolicyRegistry.allowsAutomaticRetry(ErrorCategory.networkOffline),
        isTrue,
      );
      expect(
        ErrorPolicyRegistry.allowsAutomaticRetry(ErrorCategory.server5xx),
        isTrue,
      );
      expect(
        ErrorPolicyRegistry.allowsAutomaticRetry(ErrorCategory.timeout),
        isFalse,
      );
      expect(
        ErrorPolicyRegistry.allowsAutomaticRetry(ErrorCategory.badRequest),
        isFalse,
      );
    });

    test('getUserMessageKey returns valid keys', () {
      for (final category in ErrorCategory.values) {
        final error = AppError(category: category, message: 'test');
        final key = ErrorPolicyRegistry.getUserMessageKey(error);
        expect(key, isNotEmpty);
        expect(key, startsWith('error.'));
      }
    });

    test('max delay is always greater than or equal to initial delay', () {
      for (final category in ErrorCategory.values) {
        final policy = ErrorPolicyRegistry.getPolicy(category);
        if (policy.retryStrategy != RetryStrategy.never) {
          expect(
            policy.maxDelay.compareTo(policy.initialDelay),
            greaterThanOrEqualTo(0),
          );
        }
      }
    });
  });
}
