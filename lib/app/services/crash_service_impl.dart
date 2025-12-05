import 'package:flutter/foundation.dart';
import '../../core/contracts/crash_contract.dart';
import '../../core/contracts/storage_contract.dart';
import '../../core/errors/app_error.dart';

/// Breadcrumb for crash context
class Breadcrumb {
  final String message;
  final DateTime timestamp;
  final String? category;
  final Map<String, dynamic>? data;

  Breadcrumb({
    required this.message,
    required this.timestamp,
    this.category,
    this.data,
  });

  @override
  String toString() {
    final time = timestamp.toIso8601String();
    final cat = category != null ? '[$category]' : '';
    return '$time $cat $message';
  }
}

/// Crash service with breadcrumbs and sanitization
class CrashServiceImpl implements CrashService {
  final StorageService _storage;
  final CrashService? _vendor; // Optional vendor implementation

  static const String _consentKey = 'crash_reporting_consent';
  static const int _maxBreadcrumbs = 50;

  bool? _consentGranted;
  final List<Breadcrumb> _breadcrumbs = [];

  CrashServiceImpl({required StorageService storage, CrashService? vendor})
    : _storage = storage,
      _vendor = vendor;

  /// Initialize and load consent
  Future<void> initialize() async {
    _consentGranted = await _storage.getBool(_consentKey);
    debugPrint('Crash: Initialized. Consent: $_consentGranted');
  }

  /// Set crash reporting consent
  Future<void> setConsent(bool granted) async {
    _consentGranted = granted;
    await _storage.setBool(_consentKey, granted);
    debugPrint('Crash: Consent ${granted ? 'granted' : 'revoked'}');

    if (!granted) {
      // Clear breadcrumbs when consent revoked
      _breadcrumbs.clear();
    }
  }

  /// Check if consent is granted
  bool get hasConsent => _consentGranted ?? false;

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
  }) async {
    if (!hasConsent) {
      debugPrint('Crash: Error recording blocked (no consent)');
      return;
    }

    // Sanitize exception and stack trace
    final sanitizedException = _sanitizeException(exception);
    final sanitizedStack = _sanitizeStackTrace(stack);

    debugPrint('Crash: Recording error: ${sanitizedException.toString()}');

    // Attach breadcrumbs to error context
    final context = {
      'breadcrumbs': _breadcrumbs.map((b) => b.toString()).toList(),
      'reason': reason?.toString(),
    };

    await _vendor?.recordError(
      sanitizedException,
      sanitizedStack,
      reason: context,
    );
  }

  @override
  Future<void> log(String message) async {
    if (!hasConsent) {
      return;
    }

    addBreadcrumb(message);
    await _vendor?.log(message);
  }

  /// Add a breadcrumb for crash context
  void addBreadcrumb(
    String message, {
    String? category,
    Map<String, dynamic>? data,
  }) {
    if (!hasConsent) {
      return;
    }

    final breadcrumb = Breadcrumb(
      message: _sanitizeMessage(message),
      timestamp: DateTime.now(),
      category: category,
      data: _sanitizeData(data),
    );

    _breadcrumbs.add(breadcrumb);

    // Keep only recent breadcrumbs
    if (_breadcrumbs.length > _maxBreadcrumbs) {
      _breadcrumbs.removeAt(0);
    }
  }

  /// Record navigation breadcrumb
  void recordNavigation(String from, String to) {
    addBreadcrumb('Navigation: $from → $to', category: 'navigation');
  }

  /// Record error category breadcrumb
  void recordErrorCategory(String category, String screen) {
    addBreadcrumb('Error: $category on $screen', category: 'error');
  }

  /// Get current breadcrumbs (for debugging)
  List<Breadcrumb> get breadcrumbs => List.unmodifiable(_breadcrumbs);

  /// Clear breadcrumbs
  void clearBreadcrumbs() {
    _breadcrumbs.clear();
  }

  /// Sanitize exception to remove PII
  dynamic _sanitizeException(dynamic exception) {
    if (exception is AppError) {
      // AppError is already safe - contains no PII
      return exception;
    }

    if (exception is Exception) {
      final message = exception.toString();
      return Exception(_sanitizeMessage(message));
    }

    return _sanitizeMessage(exception.toString());
  }

  /// Sanitize stack trace to remove file paths
  StackTrace? _sanitizeStackTrace(StackTrace? stack) {
    if (stack == null) return null;

    // In production, you'd want to sanitize file paths
    // For now, just return the stack as-is
    // TODO: Remove absolute file paths from stack traces
    return stack;
  }

  /// Sanitize message to remove potential PII
  String _sanitizeMessage(String message) {
    // Redact email addresses
    var sanitized = message.replaceAll(
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
      '[EMAIL]',
    );

    // Redact phone numbers (simple pattern)
    sanitized = sanitized.replaceAll(
      RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b'),
      '[PHONE]',
    );

    // Redact tokens (common patterns)
    sanitized = sanitized.replaceAll(
      RegExp(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false),
      'Bearer [TOKEN]',
    );

    return sanitized;
  }

  /// Sanitize data map
  Map<String, dynamic>? _sanitizeData(Map<String, dynamic>? data) {
    if (data == null) return null;

    final sanitized = <String, dynamic>{};
    final piiKeys = ['email', 'password', 'token', 'phone', 'address'];

    for (final entry in data.entries) {
      final key = entry.key.toLowerCase();

      if (piiKeys.any((pii) => key.contains(pii))) {
        sanitized[entry.key] = '[REDACTED]';
      } else {
        sanitized[entry.key] = entry.value;
      }
    }

    return sanitized;
  }
}
