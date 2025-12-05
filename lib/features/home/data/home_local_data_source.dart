import '../../../core/contracts/cache_contract.dart';
import '../domain/home_models.dart';
import '../domain/home_source.dart';

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  static const _cacheKey = 'home.last_known_good';
  final CacheService _cache;

  HomeLocalDataSourceImpl(this._cache);

  @override
  Future<CachedData<HomeData>?> get() async {
    final cached = await _cache.get<Map<String, dynamic>>(_cacheKey);
    if (cached == null) return null;

    return CachedData<HomeData>(
      data: HomeData.fromJson(cached.data),
      cachedAt: cached.cachedAt,
      ttl: cached.ttl,
    );
  }

  @override
  Future<void> set(HomeData data) {
    return _cache.set(
      _cacheKey,
      data.toJson(),
      ttl: const Duration(minutes: 10),
    );
  }

  @override
  Future<void> clear() => _cache.clear(_cacheKey);
}
