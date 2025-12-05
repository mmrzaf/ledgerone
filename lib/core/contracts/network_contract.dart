/// Network connectivity status
enum NetworkStatus {
  /// Device is connected to the internet
  online,

  /// Device has no internet connection
  offline,

  /// Connection status is unknown or indeterminate
  unknown;

  bool get isOnline => this == NetworkStatus.online;
  bool get isOffline => this == NetworkStatus.offline;
}

/// Service for monitoring network connectivity
abstract interface class NetworkService {
  /// Get current network status
  Future<NetworkStatus> get status;

  /// Stream of network status changes
  Stream<NetworkStatus> get statusStream;

  /// Check if device is currently online
  Future<bool> get isOnline;

  /// Initialize network monitoring
  Future<void> initialize();
}
