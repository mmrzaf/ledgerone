import 'app_error.dart';

enum ErrorPresentation { inline, banner, toast, silent }

enum RetryStrategy { never, manual, automatic }

class ErrorPolicy {
  final ErrorCategory category;
  final ErrorPresentation presentation;
  final RetryStrategy retryStrategy;
  final int maxRetries;
  final Duration initialDelay;
  final Duration maxDelay;
  final String userMessageKey;
  final bool shouldLog;

  const ErrorPolicy({
    required this.category,
    required this.presentation,
    required this.retryStrategy,
    required this.maxRetries,
    required this.initialDelay,
    required this.maxDelay,
    required this.userMessageKey,
    this.shouldLog = true,
  });
}

class ErrorPolicyRegistry {
  static const Map<ErrorCategory, ErrorPolicy> _policies = {
    ErrorCategory.networkOffline: ErrorPolicy(
      category: ErrorCategory.networkOffline,
      presentation: ErrorPresentation.banner,
      retryStrategy: RetryStrategy.automatic,
      maxRetries: 3,
      initialDelay: Duration(seconds: 1),
      maxDelay: Duration(seconds: 10),
      userMessageKey: 'error.network_offline',
    ),

    ErrorCategory.timeout: ErrorPolicy(
      category: ErrorCategory.timeout,
      presentation: ErrorPresentation.inline,
      retryStrategy: RetryStrategy.manual,
      maxRetries: 2,
      initialDelay: Duration(seconds: 2),
      maxDelay: Duration(seconds: 8),
      userMessageKey: 'error.timeout',
    ),

    ErrorCategory.server5xx: ErrorPolicy(
      category: ErrorCategory.server5xx,
      presentation: ErrorPresentation.inline,
      retryStrategy: RetryStrategy.automatic,
      maxRetries: 2,
      initialDelay: Duration(seconds: 2),
      maxDelay: Duration(seconds: 10),
      userMessageKey: 'error.server_error',
    ),

    ErrorCategory.badRequest: ErrorPolicy(
      category: ErrorCategory.badRequest,
      presentation: ErrorPresentation.inline,
      retryStrategy: RetryStrategy.never,
      maxRetries: 0,
      initialDelay: Duration.zero,
      maxDelay: Duration.zero,
      userMessageKey: 'error.bad_request',
    ),

    ErrorCategory.unauthorized: ErrorPolicy(
      category: ErrorCategory.unauthorized,
      presentation: ErrorPresentation.banner,
      retryStrategy: RetryStrategy.never,
      maxRetries: 0,
      initialDelay: Duration.zero,
      maxDelay: Duration.zero,
      userMessageKey: 'error.unauthorized',
    ),

    ErrorCategory.forbidden: ErrorPolicy(
      category: ErrorCategory.forbidden,
      presentation: ErrorPresentation.inline,
      retryStrategy: RetryStrategy.never,
      maxRetries: 0,
      initialDelay: Duration.zero,
      maxDelay: Duration.zero,
      userMessageKey: 'error.forbidden',
    ),

    ErrorCategory.notFound: ErrorPolicy(
      category: ErrorCategory.notFound,
      presentation: ErrorPresentation.inline,
      retryStrategy: RetryStrategy.never,
      maxRetries: 0,
      initialDelay: Duration.zero,
      maxDelay: Duration.zero,
      userMessageKey: 'ledger.error.asset_not_found',
    ),

    ErrorCategory.invalidCredentials: ErrorPolicy(
      category: ErrorCategory.invalidCredentials,
      presentation: ErrorPresentation.inline,
      retryStrategy: RetryStrategy.never,
      maxRetries: 0,
      initialDelay: Duration.zero,
      maxDelay: Duration.zero,
      userMessageKey: 'error.invalid_credentials',
    ),

    ErrorCategory.tokenExpired: ErrorPolicy(
      category: ErrorCategory.tokenExpired,
      presentation: ErrorPresentation.silent,
      retryStrategy: RetryStrategy.automatic,
      maxRetries: 1,
      initialDelay: Duration(milliseconds: 500),
      maxDelay: Duration(seconds: 2),
      userMessageKey: 'error.session_expired',
    ),

    ErrorCategory.parseError: ErrorPolicy(
      category: ErrorCategory.parseError,
      presentation: ErrorPresentation.inline,
      retryStrategy: RetryStrategy.manual,
      maxRetries: 1,
      initialDelay: Duration(seconds: 1),
      maxDelay: Duration(seconds: 5),
      userMessageKey: 'error.parse_error',
    ),

    ErrorCategory.unknown: ErrorPolicy(
      category: ErrorCategory.unknown,
      presentation: ErrorPresentation.inline,
      retryStrategy: RetryStrategy.manual,
      maxRetries: 1,
      initialDelay: Duration(seconds: 1),
      maxDelay: Duration(seconds: 5),
      userMessageKey: 'error.unknown',
    ),
  };

  static ErrorPolicy getPolicy(ErrorCategory category) {
    return _policies[category] ?? _policies[ErrorCategory.unknown]!;
  }

  static String getUserMessageKey(AppError error) {
    return getPolicy(error.category).userMessageKey;
  }

  static bool shouldRetry(ErrorCategory category) {
    final policy = getPolicy(category);
    return policy.retryStrategy != RetryStrategy.never;
  }

  static bool allowsAutomaticRetry(ErrorCategory category) {
    final policy = getPolicy(category);
    return policy.retryStrategy == RetryStrategy.automatic;
  }
}
