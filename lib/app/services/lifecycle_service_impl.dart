import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:ledgerone/core/observability/app_logger.dart';
import '../../core/contracts/lifecycle_contract.dart' as core;

class AppLifecycleServiceImpl extends WidgetsBindingObserver
    implements core.AppLifecycleService {
  final StreamController<core.AppLifecycleState> _stateController =
      StreamController<core.AppLifecycleState>.broadcast();

  final List<void Function()> _resumeCallbacks = [];
  final List<void Function()> _pauseCallbacks = [];

  core.AppLifecycleState _currentState = core.AppLifecycleState.resumed;
  DateTime? _lastResumeTime;
  DateTime? _lastPauseTime;

  @override
  core.AppLifecycleState get currentState => _currentState;

  @override
  Stream<core.AppLifecycleState> get stateStream => _stateController.stream;

  @override
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    AppLogger.info('Lifecycle: Monitoring initialized', tag: 'Lifecycle');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stateController.close();
    _resumeCallbacks.clear();
    _pauseCallbacks.clear();
  }

  @override
  void onResume(void Function() callback) {
    _resumeCallbacks.add(callback);
  }

  @override
  void onPause(void Function() callback) {
    _pauseCallbacks.add(callback);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final newState = _mapState(state);

    if (newState != _currentState) {
      _currentState = newState;
      _stateController.add(_currentState);

      AppLogger.debug(
        'Lifecycle: State changed to ${_currentState.name}',
        tag: 'Lifecycle',
      );

      if (_currentState == core.AppLifecycleState.resumed) {
        _lastResumeTime = DateTime.now();
        _notifyResumeCallbacks();
      } else if (_currentState == core.AppLifecycleState.paused) {
        _lastPauseTime = DateTime.now();
        _notifyPauseCallbacks();
      }
    }
  }

  void _notifyResumeCallbacks() {
    for (final callback in _resumeCallbacks) {
      try {
        callback();
      } catch (e) {
        AppLogger.error(
          'Lifecycle: Error in resume callback: $e',
          tag: 'Lifecycle',
        );
      }
    }
  }

  void _notifyPauseCallbacks() {
    for (final callback in _pauseCallbacks) {
      try {
        callback();
      } catch (e) {
        AppLogger.error(
          'Lifecycle: Error in pause callback: $e',
          tag: 'Lifecycle',
        );
      }
    }
  }

  core.AppLifecycleState _mapState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        return core.AppLifecycleState.resumed;
      case AppLifecycleState.inactive:
        return core.AppLifecycleState.inactive;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        return core.AppLifecycleState.paused;
      case AppLifecycleState.detached:
        return core.AppLifecycleState.detached;
    }
  }

  /// Get time since last resume
  Duration? get timeSinceResume {
    if (_lastResumeTime == null) return null;
    return DateTime.now().difference(_lastResumeTime!);
  }

  /// Get time spent in background
  Duration? get timeInBackground {
    if (_lastPauseTime == null || _lastResumeTime == null) return null;
    if (_lastResumeTime!.isBefore(_lastPauseTime!)) return null;
    return _lastResumeTime!.difference(_lastPauseTime!);
  }
}
