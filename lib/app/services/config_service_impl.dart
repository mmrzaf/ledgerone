import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/contracts/config_contract.dart';
import '../../core/contracts/storage_contract.dart';
import '../../core/contracts/config_provider.dart';
import '../config/default_flags.dart';

class ConfigServiceImpl implements ConfigService {
  final StorageService _storage;
  final RemoteConfigProvider _remoteProvider;

  final Map<String, dynamic> _flags = {};
  static const String _storageKey = 'config_cache';

  ConfigServiceImpl({
    required StorageService storage,
    required RemoteConfigProvider remoteProvider,
  }) : _storage = storage,
       _remoteProvider = remoteProvider;

  @override
  Future<void> initialize() async {
    _flags.addAll(defaultFlags);

    try {
      final cachedJson = await _storage.getString(_storageKey);
      if (cachedJson != null) {
        final Map<String, dynamic> cached = json.decode(cachedJson);
        _flags.addAll(cached);
      }
    } catch (e) {
      debugPrint('Config: Failed to load cache: $e');
    }

    unawaited(_refreshRemote());
  }

  Future<void> _refreshRemote() async {
    try {
      final remoteFlags = await _remoteProvider.fetchConfig();

      _flags.addAll(remoteFlags);

      await _storage.setString(_storageKey, json.encode(_flags));

      debugPrint(
        'Config: Remote refresh complete. Keys updated: ${remoteFlags.length}',
      );
    } catch (e) {
      debugPrint('Config: Remote refresh failed: $e');
    }
  }

  @override
  bool getFlag(String key, {bool defaultValue = false}) {
    final value = _flags[key];
    if (value is bool) return value;
    return defaultValue;
  }

  @override
  String getString(String key, {String defaultValue = ''}) {
    final value = _flags[key];
    if (value is String) return value;
    return defaultValue;
  }
}
