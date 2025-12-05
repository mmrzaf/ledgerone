import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../core/contracts/network_contract.dart';

/// Implementation of NetworkService using connectivity_plus.
///
/// This should be the default in prod.
/// Use SimulatedNetworkService (below / in dev) only for tests or storybook-style demos.
class NetworkServiceImpl implements NetworkService {
  final Connectivity _connectivity;
  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  NetworkStatus _currentStatus = NetworkStatus.unknown;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkServiceImpl({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  @override
  Future<void> initialize() async {
    // Initial snapshot
    final results = await _connectivity.checkConnectivity();
    _updateStatus(_mapConnectivity(results));

    // Subscribe to changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(_mapConnectivity(results));
    });

    debugPrint('Network: Monitoring initialized (connectivity_plus)');
  }

  void _updateStatus(NetworkStatus newStatus) {
    if (newStatus == _currentStatus) return;
    _currentStatus = newStatus;
    _statusController.add(_currentStatus);
    debugPrint('Network: Status changed to ${_currentStatus.name}');
  }

  /// Map the list of active connectivity types to a single NetworkStatus.
  ///
  /// connectivity_plus v2 in your setup uses List\<ConnectivityResult\>.
  /// - Empty list → unknown
  /// - All `none` → offline
  /// - Anything else → online
  NetworkStatus _mapConnectivity(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return NetworkStatus.unknown;
    }

    final hasNonNone = results.any((r) => r != ConnectivityResult.none);
    if (!hasNonNone) {
      return NetworkStatus.offline;
    }

    return NetworkStatus.online;
  }

  @override
  Future<NetworkStatus> get status async => _currentStatus;

  @override
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  @override
  Future<bool> get isOnline async => _currentStatus.isOnline;

  /// Call from DI tear-down if you add one.
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}

/// Dev/test helper: manually controlled network status.
///
/// This is still a proper implementation of NetworkService – it just lets
/// tests or demo screens set the current status explicitly.
class SimulatedNetworkService implements NetworkService {
  late final StreamController<NetworkStatus> _statusController;

  NetworkStatus _currentStatus = NetworkStatus.online;

  SimulatedNetworkService() {
    _statusController = StreamController<NetworkStatus>.broadcast(
      onListen: () {
        // Every new subscriber immediately receives the current status.
        _statusController.add(_currentStatus);
      },
    );
  }

  @override
  Future<void> initialize() async {
    // Don't emit here anymore – subscribers may not be attached yet.
    debugPrint('Network: Simulated service initialized');
  }

  NetworkStatus get currentStatus => _currentStatus;

  /// Manually set network status (for testing / demos).
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
