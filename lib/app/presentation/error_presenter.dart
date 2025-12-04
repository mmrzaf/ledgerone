import 'package:flutter/material.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/error_policy.dart';

/// User-facing error messages
/// In a real app, these would come from i18n
class ErrorMessages {
  static const Map<String, String> _messages = {
    'error.network_offline':
        'No internet connection. Please check your network.',
    'error.timeout': 'Request timed out. Please try again.',
    'error.server_error': 'Server error. Please try again later.',
    'error.bad_request': 'Invalid request. Please check your input.',
    'error.unauthorized': 'Your session has expired. Please sign in again.',
    'error.forbidden': 'You don\'t have permission to access this.',
    'error.not_found': 'The requested resource was not found.',
    'error.invalid_credentials': 'Invalid email or password.',
    'error.session_expired': 'Your session has expired.',
    'error.parse_error': 'Unable to process the response. Please try again.',
    'error.unknown': 'Something went wrong. Please try again.',
  };

  static String getMessage(String key) {
    return _messages[key] ?? _messages['error.unknown']!;
  }
}

/// Widget to present errors according to policy
class ErrorPresenter {
  /// Show error according to its policy
  static void showError(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
  }) {
    final policy = ErrorPolicyRegistry.getPolicy(error.category);
    final message = ErrorMessages.getMessage(policy.userMessageKey);

    switch (policy.presentation) {
      case ErrorPresentation.inline:
        // Inline errors are shown by the widget itself
        break;

      case ErrorPresentation.banner:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 5),
            action:
                onRetry != null && policy.retryStrategy == RetryStrategy.manual
                ? SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: onRetry,
                  )
                : null,
          ),
        );
        break;

      case ErrorPresentation.toast:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;

      case ErrorPresentation.silent:
        // Don't show to user
        break;
    }
  }
}

/// Inline error card widget
class ErrorCard extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;

  const ErrorCard({required this.error, this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    final policy = ErrorPolicyRegistry.getPolicy(error.category);
    final message = ErrorMessages.getMessage(policy.userMessageKey);
    final canRetry =
        policy.retryStrategy != RetryStrategy.never && onRetry != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (canRetry) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading indicator with cancellation
class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty state widget
class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({
    required this.message,
    this.icon = Icons.inbox_outlined,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
