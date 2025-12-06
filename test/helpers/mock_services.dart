import 'package:ledgerone/core/contracts/analytics_contract.dart';
import 'package:ledgerone/core/contracts/config_contract.dart';
import 'package:ledgerone/core/contracts/crash_contract.dart';
import 'package:ledgerone/core/contracts/navigation_contract.dart';
import 'package:ledgerone/core/contracts/storage_contract.dart';

class MockConfigService implements ConfigService {
  final Map<String, dynamic> _flags = {};
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    _initialized = true;
    _flags['auth.enabled'] = true;
    _flags['onboarding.enabled'] = true;
    _flags['telemetry.enabled'] = false;
  }

  @override
  bool getFlag(String key, {bool defaultValue = false}) {
    if (!_initialized) return defaultValue;
    return _flags[key] as bool? ?? defaultValue;
  }

  @override
  String getString(String key, {String defaultValue = ''}) {
    if (!_initialized) return defaultValue;
    return _flags[key] as String? ?? defaultValue;
  }
}

class MockStorageService implements StorageService {
  final Map<String, dynamic> _storage = {};

  @override
  Future<void> setString(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<String?> getString(String key) async {
    return _storage[key] as String?;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    _storage[key] = value;
  }

  @override
  Future<bool?> getBool(String key) async {
    return _storage[key] as bool?;
  }

  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }
}

class MockAnalyticsService implements AnalyticsService {
  final List<Map<String, dynamic>> _events = [];

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    _events.add({
      'name': name,
      'parameters': parameters,
      'timestamp': DateTime.now(),
    });
  }

  @override
  Future<void> setUserId(String? id) async {}

  @override
  Future<void> logScreenView(String screenName) async {
    await logEvent('screen_view', parameters: {'screen_name': screenName});
  }

  List<Map<String, dynamic>> get events => List.unmodifiable(_events);
}

class MockCrashService implements CrashService {
  final List<Map<String, dynamic>> _errors = [];

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
  }) async {
    _errors.add({
      'exception': exception,
      'stack': stack,
      'reason': reason,
      'timestamp': DateTime.now(),
    });
  }

  @override
  Future<void> log(String message) async {}

  List<Map<String, dynamic>> get errors => List.unmodifiable(_errors);
}

class MockNavigationService implements NavigationService {
  final List<String> _stack = <String>[];

  /// Expose history in case a test ever wants to assert on it
  List<String> get history => List.unmodifiable(_stack);

  @override
  void goToRoute(String routeId, {Map<String, dynamic>? params}) {
    _stack.add(routeId);
  }

  @override
  void replaceRoute(String routeId, {Map<String, dynamic>? params}) {
    if (_stack.isNotEmpty) {
      _stack[_stack.length - 1] = routeId;
    } else {
      _stack.add(routeId);
    }
  }

  @override
  void goBack() {
    if (_stack.isNotEmpty) {
      _stack.removeLast();
    }
  }

  @override
  bool canGoBack() => _stack.length > 1;

  @override
  String? get currentRouteId => _stack.isNotEmpty ? _stack.last : null;

  @override
  void clearAndGoTo(String routeId, {Map<String, dynamic>? params}) {
    _stack
      ..clear()
      ..add(routeId);
  }
}
