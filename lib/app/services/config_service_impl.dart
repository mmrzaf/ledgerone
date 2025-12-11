import 'dart:async';
import 'dart:convert';

import 'package:ledgerone/core/observability/app_logger.dart';

import '../../core/contracts/config_contract.dart';
import '../../core/contracts/config_provider.dart';
import '../../core/contracts/storage_contract.dart';
import '../../core/errors/app_error.dart';
import '../../core/runtime/retry_helper.dart';
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
    // 1. Start with defaults
    _flags.addAll(defaultFlags);

    // 2. Load from cache (fast path)
    try {
      final cachedJson = await _storage.getString(_storageKey);
      if (cachedJson != null) {
        final Map<String, dynamic> cached =
            json.decode(cachedJson) as Map<String, dynamic>;
        _flags.addAll(cached);
        AppLogger.info(
          'Config: Loaded ${cached.length} flags from cache',
          tag: 'Config',
        );
      }
    } catch (e) {
      AppLogger.error('Config: Failed to load cache: $e', tag: 'Config');
    }

    // 3. Refresh from remote (async, with retry)
    await _refreshRemote();
  }

  Future<void> _refreshRemote() async {
    final result = await RetryHelper.executeWithPolicy<Map<String, dynamic>>(
      operation: () => _remoteProvider.fetchConfig(),
      category: ErrorCategory.timeout,
      onRetry: (attempt, error) {
        AppLogger.error(
          'Config: Retry attempt $attempt after error: ${error.category}',
          tag: 'Config',
        );
      },
    );

    if (result.isSuccess) {
      final remoteFlags = result.data!;
      _flags.addAll(remoteFlags);

      try {
        await _storage.setString(_storageKey, json.encode(_flags));
        AppLogger.debug(
          'Config: Remote refresh complete. Keys updated: ${remoteFlags.length}',
          tag: 'Config',
        );
      } catch (e) {
        AppLogger.error(
          'Config: Failed to cache remote config: $e',
          tag: 'Config',
        );
      }
    } else if (result.isFailure) {
      AppLogger.error(
        'Config: Remote refresh failed after ${result.attemptsMade} attempts: ${result.error?.category}',
        tag: 'Config',
      );
      // Continue with cached/default config
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
