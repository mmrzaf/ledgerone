import 'package:flutter/foundation.dart';

import '../contracts/logging_contract.dart';

/// Central app logger that forwards to LoggingService when available.
/// Falls back to debugPrint in debug mode.
class AppLogger {
  static LoggingService? _loggingService;

  /// Called from DI once LoggingService is ready.
  static void attach(LoggingService service) {
    _loggingService = service;
  }

  /// Optional – if you ever want to fully detach (tests, etc.)
  static void detach() {
    _loggingService = null;
  }

  static void debug(String message, {String? tag}) {
    if (_loggingService != null) {
      _loggingService!.debug(message, tag: tag);
    } else {
      _fallback(message, tag: tag);
    }
  }

  static void info(String message, {String? tag}) {
    if (_loggingService != null) {
      _loggingService!.info(message, tag: tag);
    } else {
      _fallback(message, tag: tag);
    }
  }

  static void warning(String message, {String? tag, dynamic error}) {
    if (_loggingService != null) {
      _loggingService!.warning(message, tag: tag, error: error);
    } else {
      _fallback(message, tag: tag, error: error);
    }
  }

  static void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (_loggingService != null) {
      _loggingService!.error(
        message,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      _fallback(message, tag: tag, error: error);
    }
  }

  static void _fallback(String message, {String? tag, dynamic error}) {
    if (!kDebugMode) return;

    final tagPart = tag != null ? '[$tag] ' : '';
    final errPart = error != null ? ' | error: $error' : '';
    debugPrint('$tagPart$message$errPart');
  }
}
