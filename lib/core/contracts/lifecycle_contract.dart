/// App lifecycle states
enum AppLifecycleState {
  /// App is visible and responding to user input
  resumed,

  /// App is not visible but still running
  paused,

  /// App is in background and may be suspended
  inactive,

  /// App is about to be terminated
  detached,
}

/// Service for monitoring app lifecycle events
abstract interface class AppLifecycleService {
  /// Current lifecycle state
  AppLifecycleState get currentState;

  /// Stream of lifecycle state changes
  Stream<AppLifecycleState> get stateStream;

  /// Register a callback for when app resumes from background
  void onResume(void Function() callback);

  /// Register a callback for when app goes to background
  void onPause(void Function() callback);

  /// Initialize lifecycle monitoring
  void initialize();

  /// Clean up resources
  void dispose();
}
