import 'package:flutter/foundation.dart';

/// Performance mark for tracking
class PerformanceMark {
  final String name;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PerformanceMark({required this.name, required this.timestamp, this.metadata});
}

/// Performance metric result
class PerformanceMetric {
  final String name;
  final Duration duration;
  final Map<String, dynamic>? metadata;

  PerformanceMetric({
    required this.name,
    required this.duration,
    this.metadata,
  });

  int get durationMs => duration.inMilliseconds;

  @override
  String toString() => '$name: ${durationMs}ms';
}

/// Tracks performance metrics for critical user flows
class PerformanceTracker {
  static final PerformanceTracker _instance = PerformanceTracker._internal();
  factory PerformanceTracker() => _instance;
  PerformanceTracker._internal();

  final Map<String, DateTime> _starts = {};
  final Map<String, PerformanceMark> _marks = {};
  final List<PerformanceMetric> _metrics = [];

  /// Start tracking a performance metric
  void start(String name, {Map<String, dynamic>? metadata}) {
    _starts[name] = DateTime.now();
    debugPrint('Performance: Started tracking "$name"');

    if (metadata != null) {
      _marks['${name}_start'] = PerformanceMark(
        name: name,
        timestamp: _starts[name]!,
        metadata: metadata,
      );
    }
  }

  /// Stop tracking and record metric
  PerformanceMetric? stop(String name, {Map<String, dynamic>? metadata}) {
    final startTime = _starts[name];
    if (startTime == null) {
      debugPrint('Performance: Warning - no start time for "$name"');
      return null;
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    final metric = PerformanceMetric(
      name: name,
      duration: duration,
      metadata: metadata,
    );

    _metrics.add(metric);
    _starts.remove(name);

    debugPrint('Performance: $name completed in ${duration.inMilliseconds}ms');

    return metric;
  }

  /// Mark a point in time
  void mark(String name, {Map<String, dynamic>? metadata}) {
    _marks[name] = PerformanceMark(
      name: name,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    debugPrint('Performance: Mark "$name"');
  }

  /// Measure duration between two marks
  PerformanceMetric? measure(String name, String startMark, String endMark) {
    final start = _marks[startMark];
    final end = _marks[endMark];

    if (start == null || end == null) {
      debugPrint('Performance: Warning - missing marks for measure "$name"');
      return null;
    }

    final duration = end.timestamp.difference(start.timestamp);
    final metric = PerformanceMetric(
      name: name,
      duration: duration,
      metadata: {'start_mark': startMark, 'end_mark': endMark},
    );

    _metrics.add(metric);
    debugPrint('Performance: Measured $name: ${duration.inMilliseconds}ms');

    return metric;
  }

  /// Get all recorded metrics
  List<PerformanceMetric> get metrics => List.unmodifiable(_metrics);

  /// Get metrics by name
  List<PerformanceMetric> getMetrics(String name) {
    return _metrics.where((m) => m.name == name).toList();
  }

  /// Clear all metrics (useful for testing)
  void clear() {
    _starts.clear();
    _marks.clear();
    _metrics.clear();
  }

  /// Reset a specific metric
  void reset(String name) {
    _starts.remove(name);
    _marks.removeWhere((key, _) => key.startsWith(name));
  }
}

/// Standard performance metric names
class PerformanceMetrics {
  static const String coldStart = 'cold_start';
  static const String warmStart = 'warm_start';
  static const String configLoad = 'config_load';
  static const String loginAttempt = 'login_attempt';
  static const String homeReady = 'home_ready';
  static const String dataFetch = 'data_fetch';
  static const String sessionRefresh = 'session_refresh';

  /// All standard metric names
  static const List<String> all = [
    coldStart,
    warmStart,
    configLoad,
    loginAttempt,
    homeReady,
    dataFetch,
    sessionRefresh,
  ];
}
