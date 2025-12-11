import 'dart:convert';

import 'package:ledgerone/core/observability/app_logger.dart';

import '../../core/contracts/cache_contract.dart';
import '../../core/contracts/storage_contract.dart';

/// In-memory + persistent cache implementation
class CacheServiceImpl implements CacheService {
  final StorageService _storage;
  final Map<String, CachedData<dynamic>> _memoryCache = {};

  static const Duration defaultTTL = Duration(minutes: 5);
  static const String _cachePrefix = 'cache_';
  static const String _cacheIndexKey = 'cache_index';

  CacheServiceImpl({required StorageService storage}) : _storage = storage;

  @override
  Future<void> set<T>(String key, T data, {Duration? ttl}) async {
    final cachedData = CachedData<T>(
      data: data,
      cachedAt: DateTime.now(),
      ttl: ttl ?? defaultTTL,
    );

    _memoryCache[key] = cachedData;

    try {
      final cacheEntry = {
        'data': _serializeData(data),
        'cachedAt': cachedData.cachedAt.toIso8601String(),
        'ttlSeconds': cachedData.ttl.inSeconds,
      };

      await _storage.setString('$_cachePrefix$key', json.encode(cacheEntry));
      await _addKeyToIndex(key);

      AppLogger.info(
        'Cache: Stored $key (TTL: ${cachedData.ttl.inMinutes}m)',
        tag: 'Cache',
      );
    } catch (e) {
      AppLogger.error('Cache: Failed to persist $key: $e', tag: 'Cache');
    }
  }

  @override
  Future<CachedData<T>?> get<T>(String key) async {
    final memCached = _memoryCache[key];
    if (memCached != null && memCached.isValid) {
      return memCached as CachedData<T>;
    }

    try {
      final cached = await _storage.getString('$_cachePrefix$key');
      if (cached == null) return null;

      final cacheEntry = json.decode(cached) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(cacheEntry['cachedAt'] as String);
      final ttl = Duration(seconds: cacheEntry['ttlSeconds'] as int);
      final data = _deserializeData<T>(cacheEntry['data']);

      final cachedData = CachedData<T>(
        data: data,
        cachedAt: cachedAt,
        ttl: ttl,
      );

      _memoryCache[key] = cachedData;

      AppLogger.info(
        'Cache: Retrieved $key (age: ${cachedData.age.inMinutes}m, valid: ${cachedData.isValid})',
        tag: 'Cache',
      );
      return cachedData;
    } catch (e) {
      AppLogger.error('Cache: Failed to retrieve $key: $e', tag: 'Cache');
      return null;
    }
  }

  @override
  Future<bool> hasValid(String key) async {
    final cached = await get<dynamic>(key);
    return cached != null && cached.isValid;
  }

  @override
  Future<void> clear(String key) async {
    _memoryCache.remove(key);
    await _storage.remove('$_cachePrefix$key');
    await _removeKeyFromIndex(key);
    AppLogger.info('Cache: Cleared $key', tag: 'Cache');
  }

  @override
  Future<void> clearAll() async {
    _memoryCache.clear();

    try {
      final indexJson = await _storage.getString(_cacheIndexKey);
      if (indexJson != null) {
        final List<dynamic> keys = json.decode(indexJson) as List<dynamic>;
        for (final k in keys.cast<String>()) {
          await _storage.remove('$_cachePrefix$k');
        }
      }
      await _storage.remove(_cacheIndexKey);

      AppLogger.info(
        'Cache: Cleared all cache (memory + persistent)',
        tag: 'Cache',
      );
    } catch (e) {
      AppLogger.error(
        'Cache: Failed to clear all persistent cache: $e',
        tag: 'Cache',
      );
    }
  }

  Future<void> _addKeyToIndex(String key) async {
    try {
      final indexJson = await _storage.getString(_cacheIndexKey);
      final List<String> keys = indexJson != null
          ? (json.decode(indexJson) as List<dynamic>).cast<String>()
          : <String>[];

      if (!keys.contains(key)) {
        keys.add(key);
        await _storage.setString(_cacheIndexKey, json.encode(keys));
      }
    } catch (e) {
      AppLogger.error('Cache: Failed to update cache index: $e', tag: 'Cache');
    }
  }

  Future<void> _removeKeyFromIndex(String key) async {
    try {
      final indexJson = await _storage.getString(_cacheIndexKey);
      if (indexJson == null) return;

      final List<String> keys = (json.decode(indexJson) as List<dynamic>)
          .cast<String>();

      if (keys.remove(key)) {
        if (keys.isEmpty) {
          await _storage.remove(_cacheIndexKey);
        } else {
          await _storage.setString(_cacheIndexKey, json.encode(keys));
        }
      }
    } catch (e) {
      AppLogger.error('Cache: Failed to update cache index: $e', tag: 'Cache');
    }
  }

  dynamic _serializeData<T>(T data) {
    if (data is String || data is num || data is bool) return data;
    if (data is Map || data is List) return data;
    return data.toString();
  }

  T _deserializeData<T>(dynamic data) {
    return data as T;
  }
}
