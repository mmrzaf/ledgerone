import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/contracts/network_contract.dart';

/// Mock implementation of NetworkService for v0.6
/// In production, this would use connectivity_plus or similar package
class NetworkServiceImpl implements NetworkService {
  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  NetworkStatus _currentStatus = NetworkStatus.unknown;
  Timer? _pollTimer;

  @override
  Future<void> initialize() async {
    // Start with unknown, then check
    _currentStatus = NetworkStatus.unknown;

    // Initial check
    await _checkConnectivity();

    // Poll every 5 seconds (in production, use actual connectivity listeners)
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkConnectivity();
    });

    debugPrint('Network: Monitoring initialized');
  }

  Future<void> _checkConnectivity() async {
    // In production, this would use connectivity_plus to check actual status
    // For now, simulate occasional offline periods for testing
    final now = DateTime.now();
    final isEvenMinute = now.minute % 2 == 0;

    // Simulate being offline every other minute (for demo/testing)
    final newStatus = isEvenMinute
        ? NetworkStatus.online
        : NetworkStatus.offline; // Always online for now

    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _statusController.add(_currentStatus);
      debugPrint('Network: Status changed to ${_currentStatus.name}');
    }
  }

  @override
  Future<NetworkStatus> get status async => _currentStatus;

  @override
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  @override
  Future<bool> get isOnline async => _currentStatus.isOnline;

  void dispose() {
    _pollTimer?.cancel();
    _statusController.close();
  }
}

/// Simulated network service that can be controlled for testing
class SimulatedNetworkService implements NetworkService {
  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  NetworkStatus _currentStatus = NetworkStatus.offline;

  @override
  Future<void> initialize() async {
    debugPrint('Network: Simulated service initialized');
  }

  /// Manually set network status (for testing)
  void setStatus(NetworkStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(_currentStatus);
      debugPrint('Network: Simulated status set to ${_currentStatus.name}');
    }
  }

  @override
  Future<NetworkStatus> get status async => _currentStatus;

  @override
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  @override
  Future<bool> get isOnline async => _currentStatus.isOnline;

  void dispose() {
    _statusController.close();
  }
}
