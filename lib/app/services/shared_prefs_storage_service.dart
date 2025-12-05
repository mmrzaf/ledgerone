import 'package:shared_preferences/shared_preferences.dart';

import '../../core/contracts/storage_contract.dart';

/// StorageService implementation backed by SharedPreferences.
///
/// Use `SharedPrefsStorageService.create()` in DI to get an instance.
class SharedPrefsStorageService implements StorageService {
  final SharedPreferences _prefs;

  SharedPrefsStorageService._(this._prefs);

  /// Factory to create the service with an initialized SharedPreferences.
  static Future<SharedPrefsStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPrefsStorageService._(prefs);
  }

  @override
  Future<void> setString(String key, String value) async {
    final ok = await _prefs.setString(key, value);
    if (!ok) {
      // We don’t throw here to avoid crashing the app on storage failure.
      // If you want stricter behavior, add logging or wrap in AppError.
    }
  }

  @override
  Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    final ok = await _prefs.setBool(key, value);
    if (!ok) {
      // Same note as setString.
    }
  }

  @override
  Future<bool?> getBool(String key) async {
    // `getBool` returns null if the key is missing – that’s exactly what
    // the contract promises.
    return _prefs.getBool(key);
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}
