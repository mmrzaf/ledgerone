import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/contracts/logging_contract.dart';
import '../../core/contracts/storage_contract.dart';

class LoggingServiceImpl implements LoggingService {
  final StorageService _storage;
  final int maxLogEntries;
  final List<LogEntry> _logs = [];
  final StreamController<LogEntry> _logController =
      StreamController<LogEntry>.broadcast();

  static const String _storageKey = 'app_logs';

  LoggingServiceImpl({
    required StorageService storage,
    this.maxLogEntries = 500,
  }) : _storage = storage;

  @override
  Stream<LogEntry> get logStream => _logController.stream;

  @override
  List<LogEntry> get logs => List.unmodifiable(_logs);

  @override
  Future<void> initialize() async {
    try {
      final stored = await _storage.getString(_storageKey);
      if (stored != null) {
        final decoded = json.decode(stored) as List<dynamic>;
        _logs.addAll(
          decoded
              .map((e) => LogEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
        debugPrint('Logging: Loaded ${_logs.length} persisted logs');
      }
    } catch (e) {
      debugPrint('Logging: Failed to load persisted logs: $e');
    }
  }

  @override
  void debug(String message, {String? tag}) {
    _addLog(LogLevel.debug, message, tag: tag);
  }

  @override
  void info(String message, {String? tag}) {
    _addLog(LogLevel.info, message, tag: tag);
  }

  @override
  void warning(String message, {String? tag, dynamic error}) {
    _addLog(LogLevel.warning, message, tag: tag, error: error);
  }

  @override
  void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _addLog(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _addLog(
    LogLevel level,
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );

    _logs.add(entry);
    _logController.add(entry);

    // Trim if exceeds max
    if (_logs.length > maxLogEntries) {
      _logs.removeAt(0);
    }

    // Also print to console in debug mode
    if (kDebugMode) {
      debugPrint(entry.toString());
    }

    // Persist async (fire and forget)
    _persist();
  }

  Future<void> _persist() async {
    try {
      final encoded = json.encode(_logs.map((e) => e.toJson()).toList());
      await _storage.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Logging: Failed to persist logs: $e');
    }
  }

  @override
  Future<void> clear() async {
    _logs.clear();
    await _storage.remove(_storageKey);
    debugPrint('Logging: Cleared all logs');
  }

  @override
  void dispose() {
    _logController.close();
  }
}
