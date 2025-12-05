import 'package:flutter/material.dart';

import '../../core/contracts/analytics_contract.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/error_policy.dart';
import '../../core/observability/analytics_allowlist.dart';
import '../di.dart';

/// User-facing error messages
/// In a real app, these would come from i18n
class ErrorMessages {
  static const Map<String, String> _messages = {
    'error.network_offline':
        'No internet connection. Please check your network.',
    'error.timeout': 'Request timed out. Please try again.',
    'error.server_error': 'Server error. Please try again later.',
    'error.unauthorized': 'You are not authorized. Please log in again.',
    'error.forbidden': 'You do not have permission to perform this action.',
    'error.not_found': 'The requested resource was not found.',
    'error.invalid_credentials':
        'Invalid credentials. Please check your email and password.',
    'error.token_expired': 'Session expired. Please log in again.',
    'error.parse_error': 'Data error. Please try again.',
    'error.unknown': 'Something went wrong. Please try again.',
  };

  static String getMessage(String key) {
    return _messages[key] ?? 'An unexpected error occurred.';
  }
}

class ErrorPresenter {
  static void showError(
    BuildContext context,
    AppError error, {
    String screen = 'unknown',
    VoidCallback? onRetry,
  }) {
    final policy = ErrorPolicyRegistry.getPolicy(error.category);

    // If the policy says "don't log", we also don't present anything
    if (!policy.shouldLog) return;

    AnalyticsService? analytics;
    try {
      analytics = ServiceLocator().get<AnalyticsService>();
    } catch (_) {
      analytics = null;
    }

    switch (policy.presentation) {
      case ErrorPresentation.inline:
        // Inline errors are shown by the widget itself (ErrorCard handles logging)
        break;

      case ErrorPresentation.banner:
        analytics?.logEvent(
          AnalyticsAllowlist.errorShown.name,
          parameters: {
            'error_category': error.category.name,
            'presentation': 'banner',
            'screen': screen,
          },
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessages.getMessage(policy.userMessageKey)),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.fixed,
          ),
        );
        break;

      case ErrorPresentation.toast:
        analytics?.logEvent(
          AnalyticsAllowlist.errorShown.name,
          parameters: {
            'error_category': error.category.name,
            'presentation': 'toast',
            'screen': screen,
          },
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessages.getMessage(policy.userMessageKey)),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;

      case ErrorPresentation.silent:
        break;
    }
  }
}

class ErrorCard extends StatefulWidget {
  final AppError error;
  final String screen;
  final VoidCallback? onRetry;

  const ErrorCard({
    required this.error,
    required this.screen,
    this.onRetry,
    super.key,
  });

  @override
  State<ErrorCard> createState() => _ErrorCardState();
}

class _ErrorCardState extends State<ErrorCard> {
  AnalyticsService? _analytics;

  @override
  void initState() {
    super.initState();

    final policy = ErrorPolicyRegistry.getPolicy(widget.error.category);
    if (!policy.shouldLog) return;

    try {
      _analytics = ServiceLocator().get<AnalyticsService>();
    } catch (_) {
      _analytics = null;
    }

    _analytics?.logEvent(
      AnalyticsAllowlist.errorShown.name,
      parameters: {
        'error_category': widget.error.category.name,
        'presentation': 'inline',
        'screen': widget.screen,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messageKey = ErrorPolicyRegistry.getUserMessageKey(widget.error);
    final message = ErrorMessages.getMessage(messageKey);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.onRetry != null)
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: widget.onRetry,
                  child: const Text('Try Again'),
                ),
              ),
          ],
        ),
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
