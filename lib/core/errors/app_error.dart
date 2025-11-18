enum ErrorCategory {
  networkOffline,
  timeout,
  server5xx,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  invalidCredentials,
  tokenExpired,
  parseError,
  unknown,
}

class AppError implements Exception {
  final ErrorCategory category;
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppError({
    required this.category,
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppError($category): $message';
}
