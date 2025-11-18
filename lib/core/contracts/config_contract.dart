abstract interface class ConfigService {
  Future<void> initialize();
  bool getFlag(String key, {bool defaultValue = false});
  String getString(String key, {String defaultValue = ''});
}
