import '../../core/contracts/config_contract.dart';
import '../../core/contracts/storage_contract.dart';
import '../../core/contracts/auth_contract.dart';
import '../../core/contracts/analytics_contract.dart';
import '../../core/contracts/crash_contract.dart';

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

class MockAuthService implements AuthService {
  bool _isAuthenticated = false;
  String? _userId;

  @override
  Future<bool> get isAuthenticated async => _isAuthenticated;

  @override
  Future<String?> get userId async => _userId;

  @override
  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.length < 6) {
      throw Exception('Invalid credentials');
    }

    _isAuthenticated = true;
    _userId = email.split('@').first;
  }

  @override
  Future<void> logout() async {
    _isAuthenticated = false;
    _userId = null;
  }

  @override
  Future<void> refreshSession() async {}
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
