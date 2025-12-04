import 'dart:math';
import '../errors/app_error.dart';
import '../errors/error_policy.dart';
import 'cancellation_token.dart';

/// Configuration for retry behavior
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool useJitter;

  const RetryConfig({
    required this.maxAttempts,
    required this.initialDelay,
    required this.maxDelay,
    this.backoffMultiplier = 2.0,
    this.useJitter = true,
  });

  factory RetryConfig.fromPolicy(ErrorPolicy policy) {
    return RetryConfig(
      maxAttempts: policy.maxRetries,
      initialDelay: policy.initialDelay,
      maxDelay: policy.maxDelay,
    );
  }

  static const never = RetryConfig(
    maxAttempts: 0,
    initialDelay: Duration.zero,
    maxDelay: Duration.zero,
  );
}

/// Result of a retry operation
class RetryResult<T> {
  final T? data;
  final AppError? error;
  final int attemptsMade;
  final bool wasCancelled;

  const RetryResult._({
    this.data,
    this.error,
    required this.attemptsMade,
    this.wasCancelled = false,
  });

  bool get isSuccess => data != null && error == null;
  bool get isFailure => error != null;

  factory RetryResult.success(T data, int attemptsMade) {
    return RetryResult._(data: data, attemptsMade: attemptsMade);
  }

  factory RetryResult.failure(AppError error, int attemptsMade) {
    return RetryResult._(error: error, attemptsMade: attemptsMade);
  }

  factory RetryResult.cancelled(int attemptsMade) {
    return RetryResult._(attemptsMade: attemptsMade, wasCancelled: true);
  }
}

/// Helper for executing operations with retry and backoff
class RetryHelper {
  static final _random = Random();

  static Future<RetryResult<T>> execute<T>({
    required Future<T> Function() operation,
    required RetryConfig config,
    CancellationToken? cancellationToken,
    void Function(int attempt, AppError error)? onRetry,
  }) async {
    final token = cancellationToken ?? CancellationToken.none;
    var currentDelay = config.initialDelay;

    for (var attempt = 1; attempt <= config.maxAttempts + 1; attempt++) {
      try {
        token.throwIfCancelled();
        final result = await operation();
        return RetryResult.success(result, attempt);
      } on OperationCancelledException {
        return RetryResult.cancelled(attempt);
      } catch (e) {
        final appError = e is AppError
            ? e
            : AppError(
                category: ErrorCategory.unknown,
                message: e.toString(),
                originalError: e,
              );

        if (attempt > config.maxAttempts) {
          return RetryResult.failure(appError, attempt);
        }
        final policy = ErrorPolicyRegistry.getPolicy(appError.category);
        if (policy.retryStrategy == RetryStrategy.never) {
          return RetryResult.failure(appError, attempt);
        }
        onRetry?.call(attempt, appError);

        try {
          token.throwIfCancelled();
          await _delayWithBackoff(
            currentDelay,
            config.maxDelay,
            config.useJitter,
            token,
          );
        } on OperationCancelledException {
          return RetryResult.cancelled(attempt);
        }

        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * config.backoffMultiplier)
              .toInt(),
        );
      }
    }

    return RetryResult.failure(
      const AppError(
        category: ErrorCategory.unknown,
        message: 'Unexpected retry completion',
      ),
      config.maxAttempts + 1,
    );
  }

  /// Execute with policy-based retry
  static Future<RetryResult<T>> executeWithPolicy<T>({
    required Future<T> Function() operation,
    required ErrorCategory category,
    CancellationToken? cancellationToken,
    void Function(int attempt, AppError error)? onRetry,
  }) async {
    final policy = ErrorPolicyRegistry.getPolicy(category);
    final config = RetryConfig.fromPolicy(policy);

    return execute(
      operation: operation,
      config: config,
      cancellationToken: cancellationToken,
      onRetry: onRetry,
    );
  }

  /// Delay with exponential backoff and jitter
  static Future<void> _delayWithBackoff(
    Duration delay,
    Duration maxDelay,
    bool useJitter,
    CancellationToken token,
  ) async {
    var actualDelay = delay;

    if (actualDelay > maxDelay) {
      actualDelay = maxDelay;
    }

    if (useJitter) {
      final jitterMs = _random.nextInt(actualDelay.inMilliseconds ~/ 2);
      actualDelay = Duration(
        milliseconds: actualDelay.inMilliseconds + jitterMs,
      );
    }

    await Future.delayed(actualDelay);
    token.throwIfCancelled();
  }

  /// Simple manual retry - just execute once with cancellation support
  static Future<T> executeOnce<T>({
    required Future<T> Function() operation,
    CancellationToken? cancellationToken,
  }) async {
    final token = cancellationToken ?? CancellationToken.none;
    token.throwIfCancelled();
    return await operation();
  }
}
