/// Cached data with metadata
class CachedData<T> {
  final T data;
  final DateTime cachedAt;
  final Duration ttl;

  const CachedData({
    required this.data,
    required this.cachedAt,
    required this.ttl,
  });

  /// Check if cache is still valid
  bool get isValid {
    final now = DateTime.now();
    final expiresAt = cachedAt.add(ttl);
    return now.isBefore(expiresAt);
  }

  /// Check if cache is stale but can be used as fallback
  bool get isStale => !isValid;

  /// Age of cached data
  Duration get age => DateTime.now().difference(cachedAt);
}

/// Service for caching data with TTL
abstract interface class CacheService {
  /// Store data with TTL
  Future<void> set<T>(String key, T data, {Duration? ttl});

  /// Retrieve cached data if valid
  Future<CachedData<T>?> get<T>(String key);

  /// Check if cache exists and is valid
  Future<bool> hasValid(String key);

  /// Clear specific cache entry
  Future<void> clear(String key);

  /// Clear all cache
  Future<void> clearAll();
}
