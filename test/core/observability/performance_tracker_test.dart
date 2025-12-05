import 'package:app_flutter_starter/core/observability/performance_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PerformanceTracker', () {
    late PerformanceTracker tracker;

    setUp(() {
      tracker = PerformanceTracker();
      tracker.clear();
    });

    test('tracks duration between start and stop', () {
      tracker.start('test_metric');

      // Simulate work
      Future<void>.delayed(const Duration(milliseconds: 10));

      final metric = tracker.stop('test_metric');

      expect(metric, isNotNull);
      expect(metric!.name, equals('test_metric'));
      expect(metric.duration.inMilliseconds, greaterThanOrEqualTo(0));
    });

    test('returns null when stopping without start', () {
      final metric = tracker.stop('never_started');
      expect(metric, isNull);
    });

    test('marks points in time', () {
      tracker.mark('point_a');
      tracker.mark('point_b');

      final metric = tracker.measure('test', 'point_a', 'point_b');

      expect(metric, isNotNull);
      expect(metric!.duration.inMilliseconds, greaterThanOrEqualTo(0));
    });

    test('stores multiple metrics', () {
      tracker.start('metric1');
      tracker.stop('metric1');

      tracker.start('metric2');
      tracker.stop('metric2');

      expect(tracker.metrics.length, equals(2));
    });

    test('can retrieve metrics by name', () {
      tracker.start('test');
      tracker.stop('test');

      tracker.start('test');
      tracker.stop('test');

      final metrics = tracker.getMetrics('test');
      expect(metrics.length, equals(2));
    });

    test('clear removes all metrics', () {
      tracker.start('test');
      tracker.stop('test');

      tracker.clear();

      expect(tracker.metrics.isEmpty, isTrue);
    });

    test('supports metadata', () {
      tracker.start('test', metadata: {'key': 'value'});
      final metric = tracker.stop('test', metadata: {'result': 'success'});

      expect(metric, isNotNull);
      expect(metric!.metadata, isNotNull);
    });
  });

  group('PerformanceMetrics', () {
    test('defines standard metric names', () {
      expect(PerformanceMetrics.coldStart, equals('cold_start'));
      expect(PerformanceMetrics.loginAttempt, equals('login_attempt'));
      expect(PerformanceMetrics.homeReady, equals('home_ready'));
    });

    test('all list contains all metrics', () {
      expect(PerformanceMetrics.all, contains('cold_start'));
      expect(PerformanceMetrics.all, contains('login_attempt'));
      expect(PerformanceMetrics.all, contains('home_ready'));
    });
  });
}
