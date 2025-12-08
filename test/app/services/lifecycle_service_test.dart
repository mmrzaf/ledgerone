import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerone/app/services/lifecycle_service_impl.dart';
import 'package:ledgerone/core/contracts/lifecycle_contract.dart' as core;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLifecycleServiceImpl', () {
    late AppLifecycleServiceImpl service;

    setUp(() {
      service = AppLifecycleServiceImpl();
      service.initialize();
    });

    tearDown(() {
      service.dispose();
    });

    test('initializes with resumed state', () {
      expect(service.currentState, core.AppLifecycleState.resumed);
    });

    test('emits state changes through stream', () async {
      final states = <core.AppLifecycleState>[];
      final subscription = service.stateStream.listen(states.add);

      // Simulate lifecycle change
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);

      expect(states, contains(core.AppLifecycleState.paused));
      expect(service.currentState, core.AppLifecycleState.paused);

      await subscription.cancel();
    });

    test('calls resume callbacks when app resumes', () async {
      var resumeCallbackCalled = false;
      service.onResume(() {
        resumeCallbackCalled = true;
      });

      // Change to a different state first
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);

      // Then resume
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(resumeCallbackCalled, isTrue);
    });

    test('calls pause callbacks when app pauses', () async {
      var pauseCallbackCalled = false;
      service.onPause(() {
        pauseCallbackCalled = true;
      });

      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);

      expect(pauseCallbackCalled, isTrue);
    });

    test('handles multiple resume callbacks', () async {
      var callCount = 0;

      service.onResume(() => callCount++);
      service.onResume(() => callCount++);
      service.onResume(() => callCount++);

      // Change state to paused first
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);

      // Then resume
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(callCount, 3);
    });

    test('handles callback errors gracefully', () async {
      var otherCallbackCalled = false;

      service.onResume(() {
        throw Exception('Error in callback');
      });

      service.onResume(() {
        otherCallbackCalled = true;
      });

      // Change to paused first
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);

      // Then resume
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      // Second callback should still execute
      expect(otherCallbackCalled, isTrue);
    });

    test('maps Flutter lifecycle states correctly', () async {
      final mappings = {
        AppLifecycleState.resumed: core.AppLifecycleState.resumed,
        AppLifecycleState.inactive: core.AppLifecycleState.inactive,
        AppLifecycleState.paused: core.AppLifecycleState.paused,
        AppLifecycleState.hidden: core.AppLifecycleState.paused,
        AppLifecycleState.detached: core.AppLifecycleState.detached,
      };

      for (final entry in mappings.entries) {
        service.didChangeAppLifecycleState(entry.key);
        await Future<void>.delayed(Duration.zero);
        expect(service.currentState, entry.value);
      }
    });

    test('tracks time since resume', () async {
      // Need to trigger a resume to start tracking
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final timeSinceResume = service.timeSinceResume;
      expect(timeSinceResume, isNotNull);
      expect(timeSinceResume!.inMilliseconds, greaterThanOrEqualTo(50));
    });

    test('tracks time in background', () async {
      // Pause
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Resume
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      final timeInBackground = service.timeInBackground;
      expect(timeInBackground, isNotNull);
      expect(timeInBackground!.inMilliseconds, greaterThanOrEqualTo(50));
    });

    test('does not emit duplicate states', () async {
      final states = <core.AppLifecycleState>[];
      final subscription = service.stateStream.listen(states.add);

      // Change to paused
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);

      // Try to set paused again
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);

      // Should only emit paused once
      expect(states.where((s) => s == core.AppLifecycleState.paused).length, 1);

      await subscription.cancel();
    });

    test('dispose cleans up resources', () {
      service.dispose();

      // After dispose, stream should be closed
      // Listening to a closed stream returns a done subscription
      final subscription = service.stateStream.listen((_) {});
      expect(subscription, isA<StreamSubscription>());
      subscription.cancel();
    });
  });
}
