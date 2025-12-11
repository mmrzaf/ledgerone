/// Log levels in order of severity
enum LogLevel {
  debug,
  info,
  warning,
  error;

  bool get isDebug => this == LogLevel.debug;
  bool get isInfo => this == LogLevel.info;
  bool get isWarning => this == LogLevel.warning;
  bool get isError => this == LogLevel.error;
}

/// A single log entry
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? tag;
  final dynamic error;
  final StackTrace? stackTrace;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level.name,
    'message': message,
    if (tag != null) 'tag': tag,
    if (error != null) 'error': error.toString(),
  };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
    timestamp: DateTime.parse(json['timestamp'] as String),
    level: LogLevel.values.byName(json['level'] as String),
    message: json['message'] as String,
    tag: json['tag'] as String?,
    error: json['error'],
  );

  @override
  String toString() {
    final tagStr = tag != null ? '[$tag] ' : '';
    final errorStr = error != null ? ' | Error: $error' : '';
    return '${timestamp.toIso8601String()} [${level.name.toUpperCase()}] $tagStr$message$errorStr';
  }
}

/// Service for application-wide logging
abstract interface class LoggingService {
  /// Stream of log entries
  Stream<LogEntry> get logStream;

  /// Get all current logs
  List<LogEntry> get logs;

  /// Log a debug message
  void debug(String message, {String? tag});

  /// Log an info message
  void info(String message, {String? tag});

  /// Log a warning
  void warning(String message, {String? tag, dynamic error});

  /// Log an error
  void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  });

  /// Clear all logs
  Future<void> clear();

  /// Initialize service (load persisted logs)
  Future<void> initialize();

  /// Dispose resources
  void dispose();
}
