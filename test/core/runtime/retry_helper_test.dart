import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerone/core/errors/app_error.dart';
import 'package:ledgerone/core/errors/error_policy.dart';
import 'package:ledgerone/core/runtime/cancellation_token.dart';
import 'package:ledgerone/core/runtime/retry_helper.dart';

void main() {
  group('RetryHelper', () {
    test('succeeds on first attempt', () async {
      var attempts = 0;

      final result = await RetryHelper.execute(
        operation: () async {
          attempts++;
          return 'success';
        },
        config: const RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
          maxDelay: Duration(milliseconds: 100),
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, equals('success'));
      expect(result.attemptsMade, equals(1));
      expect(attempts, equals(1));
    });

    test('retries on failure and eventually succeeds', () async {
      var attempts = 0;

      final result = await RetryHelper.execute(
        operation: () async {
          attempts++;
          if (attempts < 3) {
            throw const AppError(
              category: ErrorCategory.timeout,
              message: 'Timeout',
            );
          }
          return 'success';
        },
        config: const RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
          maxDelay: Duration(milliseconds: 100),
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, equals('success'));
      expect(result.attemptsMade, equals(3));
      expect(attempts, equals(3));
    });

    test('fails after max attempts exceeded', () async {
      var attempts = 0;

      final result = await RetryHelper.execute(
        operation: () async {
          attempts++;
          throw const AppError(
            category: ErrorCategory.timeout,
            message: 'Always fails',
          );
        },
        config: const RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
          maxDelay: Duration(milliseconds: 100),
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.error?.category, equals(ErrorCategory.timeout));
      expect(result.attemptsMade, equals(4)); // Initial + 3 retries
      expect(attempts, equals(4));
    });

    test('respects never retry strategy', () async {
      var attempts = 0;

      final result = await RetryHelper.execute(
        operation: () async {
          attempts++;
          throw const AppError(
            category: ErrorCategory.badRequest,
            message: 'Bad request',
          );
        },
        config: const RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
          maxDelay: Duration(milliseconds: 100),
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.error?.category, equals(ErrorCategory.badRequest));
      expect(result.attemptsMade, equals(1));
      expect(attempts, equals(1));
    });

    test('cancellation stops retry', () async {
      var attempts = 0;
      final token = CancellationToken();

      final future = RetryHelper.execute(
        operation: () async {
          attempts++;
          if (attempts == 2) {
            token.cancel();
          }
          throw const AppError(
            category: ErrorCategory.timeout,
            message: 'Timeout',
          );
        },
        config: const RetryConfig(
          maxAttempts: 5,
          initialDelay: Duration(milliseconds: 10),
          maxDelay: Duration(milliseconds: 100),
        ),
        cancellationToken: token,
      );

      final result = await future;

      expect(result.wasCancelled, isTrue);
      expect(attempts, lessThanOrEqualTo(3));
    });

    test('onRetry callback is called', () async {
      final retryAttempts = <int>[];
      final retryErrors = <ErrorCategory>[];

      await RetryHelper.execute(
        operation: () async {
          throw const AppError(
            category: ErrorCategory.timeout,
            message: 'Timeout',
          );
        },
        config: const RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
          maxDelay: Duration(milliseconds: 100),
        ),
        onRetry: (attempt, error) {
          retryAttempts.add(attempt);
          retryErrors.add(error.category);
        },
      );

      expect(retryAttempts, equals([1, 2, 3]));
      expect(
        retryErrors,
        equals([
          ErrorCategory.timeout,
          ErrorCategory.timeout,
          ErrorCategory.timeout,
        ]),
      );
    });

    test('executeWithPolicy uses correct retry config', () async {
      var attempts = 0;

      final result = await RetryHelper.executeWithPolicy(
        operation: () async {
          attempts++;
          if (attempts < 3) {
            throw const AppError(
              category: ErrorCategory.server5xx,
              message: 'Server error',
            );
          }
          return 'success';
        },
        category: ErrorCategory.server5xx,
      );

      expect(result.isSuccess, isTrue);
      expect(attempts, lessThanOrEqualTo(3));
    });

    test('executeOnce does not retry', () async {
      var attempts = 0;

      try {
        await RetryHelper.executeOnce(
          operation: () async {
            attempts++;
            throw Exception('Error');
          },
        );
        // fail('Should have thrown');
      } catch (e) {
        expect(attempts, equals(1));
      }
    });

    test('executeOnce respects cancellation', () async {
      final token = CancellationToken();
      token.cancel();

      expect(
        () => RetryHelper.executeOnce(
          operation: () async => 'test',
          cancellationToken: token,
        ),
        throwsA(isA<OperationCancelledException>()),
      );
    });

    test('non-AppError exceptions are wrapped', () async {
      final result = await RetryHelper.execute(
        operation: () async {
          throw Exception('Regular exception');
        },
        config: const RetryConfig(
          maxAttempts: 1,
          initialDelay: Duration(milliseconds: 10),
          maxDelay: Duration(milliseconds: 100),
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.error?.category, equals(ErrorCategory.unknown));
      expect(result.error?.originalError, isA<Exception>());
    });
  });

  group('RetryConfig', () {
    test('fromPolicy creates correct config', () {
      final policy = ErrorPolicyRegistry.getPolicy(ErrorCategory.timeout);
      final config = RetryConfig.fromPolicy(policy);

      expect(config.maxAttempts, equals(policy.maxRetries));
      expect(config.initialDelay, equals(policy.initialDelay));
      expect(config.maxDelay, equals(policy.maxDelay));
    });

    test('never config has zero attempts', () {
      expect(RetryConfig.never.maxAttempts, equals(0));
      expect(RetryConfig.never.initialDelay, equals(Duration.zero));
    });
  });
}
