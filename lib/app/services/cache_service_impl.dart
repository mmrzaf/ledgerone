import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/contracts/cache_contract.dart';
import '../../core/contracts/storage_contract.dart';

/// In-memory + persistent cache implementation
class CacheServiceImpl implements CacheService {
  final StorageService _storage;

  // In-memory cache for fast access
  final Map<String, CachedData<dynamic>> _memoryCache = {};

  // Default TTL for cached data
  static const Duration defaultTTL = Duration(minutes: 5);

  CacheServiceImpl({required StorageService storage}) : _storage = storage;

  @override
  Future<void> set<T>(String key, T data, {Duration? ttl}) async {
    final cachedData = CachedData<T>(
      data: data,
      cachedAt: DateTime.now(),
      ttl: ttl ?? defaultTTL,
    );

    // Store in memory
    _memoryCache[key] = cachedData;

    // Persist to storage
    try {
      final cacheEntry = {
        'data': _serializeData(data),
        'cachedAt': cachedData.cachedAt.toIso8601String(),
        'ttlSeconds': cachedData.ttl.inSeconds,
      };

      await _storage.setString('cache_$key', json.encode(cacheEntry));
      debugPrint('Cache: Stored $key (TTL: ${cachedData.ttl.inMinutes}m)');
    } catch (e) {
      debugPrint('Cache: Failed to persist $key: $e');
      // Continue with in-memory cache only
    }
  }

  @override
  Future<CachedData<T>?> get<T>(String key) async {
    // Check memory cache first
    final memCached = _memoryCache[key];
    if (memCached != null && memCached.isValid) {
      return memCached as CachedData<T>;
    }

    // Check persistent storage
    try {
      final cached = await _storage.getString('cache_$key');
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

      // Restore to memory cache
      _memoryCache[key] = cachedData;

      debugPrint(
        'Cache: Retrieved $key (age: ${cachedData.age.inMinutes}m, valid: ${cachedData.isValid})',
      );
      return cachedData;
    } catch (e) {
      debugPrint('Cache: Failed to retrieve $key: $e');
      return null;
    }
  }

  @override
  Future<bool> hasValid(String key) async {
    final cached = await get(key);
    return cached != null && cached.isValid;
  }

  @override
  Future<void> clear(String key) async {
    _memoryCache.remove(key);
    await _storage.remove('cache_$key');
    debugPrint('Cache: Cleared $key');
  }

  @override
  Future<void> clearAll() async {
    _memoryCache.clear();
    // Note: This only clears cache keys, not all storage
    debugPrint('Cache: Cleared all in-memory cache');
  }

  /// Serialize data for storage
  dynamic _serializeData<T>(T data) {
    if (data is String || data is num || data is bool) {
      return data;
    }
    if (data is Map || data is List) {
      return data;
    }
    // For complex types, convert to JSON string
    return data.toString();
  }

  /// Deserialize data from storage
  T _deserializeData<T>(dynamic data) {
    return data as T;
  }
}
