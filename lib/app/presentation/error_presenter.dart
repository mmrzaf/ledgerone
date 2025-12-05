import 'package:flutter/material.dart';

import '../../core/contracts/analytics_contract.dart';
import '../../core/contracts/i18n_contract.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/error_policy.dart';
import '../../core/i18n/string_keys.dart';
import '../../core/observability/analytics_allowlist.dart';
import '../di.dart';

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

    final l10n = context.l10n;
    final message = l10n.get(policy.userMessageKey);

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
            content: Text(message),
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
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();

    // Log error presentation
    try {
      final analytics = ServiceLocator().get<AnalyticsService>();
      analytics.logEvent(
        AnalyticsAllowlist.errorShown.name,
        parameters: {
          'error_category': widget.error.category.name,
          'presentation': 'inline',
          'screen': widget.screen,
        },
      );
    } catch (_) {
      // Analytics is optional
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final l10n = context.l10n;

    // Title: localized, but "Something went wrong" in English
    final title = l10n.get(L10nKeys.errorInlineTitle);

    // Prefer the concrete error message; fall back to policy-based copy
    final messageKey = ErrorPolicyRegistry.getUserMessageKey(widget.error);
    final fallbackMessage = l10n.get(messageKey);
    final message = widget.error.message.isNotEmpty
        ? widget.error.message
        : fallbackMessage;

    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: const TextStyle(color: Colors.black87)),
                  if (widget.onRetry != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: widget.onRetry,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.get(L10nKeys.retry)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _dismissed = true),
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
