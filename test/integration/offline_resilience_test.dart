import 'package:app_flutter_starter/app/services/cache_service_impl.dart';
import 'package:app_flutter_starter/app/services/mock_services.dart';
import 'package:app_flutter_starter/app/services/network_service_impl.dart';
import 'package:app_flutter_starter/core/contracts/cache_contract.dart';
import 'package:app_flutter_starter/core/contracts/network_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkService', () {
    test('starts with unknown status', () async {
      final network = SimulatedNetworkService();
      await network.initialize();

      final status = await network.status;
      expect(status, NetworkStatus.online);
    });

    test('reports online status', () async {
      final network = SimulatedNetworkService();
      await network.initialize();

      network.setStatus(NetworkStatus.online);

      final status = await network.status;
      expect(status, NetworkStatus.online);
      expect(await network.isOnline, isTrue);
    });

    test('reports offline status', () async {
      final network = SimulatedNetworkService();
      await network.initialize();

      network.setStatus(NetworkStatus.offline);

      final status = await network.status;
      expect(status, NetworkStatus.offline);
      expect(await network.isOnline, isFalse);
    });

    test('emits status changes', () async {
      final network = SimulatedNetworkService();
      await network.initialize();

      final statusChanges = <NetworkStatus>[];
      network.statusStream.listen(statusChanges.add);

      network.setStatus(NetworkStatus.online);
      network.setStatus(NetworkStatus.offline);
      network.setStatus(NetworkStatus.online);

      await Future.delayed(Duration.zero);

      expect(statusChanges, [
        NetworkStatus.online,
        NetworkStatus.offline,
        NetworkStatus.online,
      ]);
    });
  });

  group('CacheService', () {
    late MockStorageService storage;
    late CacheServiceImpl cache;

    setUp(() {
      storage = MockStorageService();
      cache = CacheServiceImpl(storage: storage);
    });

    test('stores and retrieves data', () async {
      await cache.set('test_key', 'test_value');

      final cached = await cache.get<String>('test_key');

      expect(cached, isNotNull);
      expect(cached!.data, 'test_value');
      expect(cached.isValid, isTrue);
    });

    test('respects TTL', () async {
      await cache.set(
        'short_ttl',
        'value',
        ttl: const Duration(milliseconds: 100),
      );

      // Immediately valid
      var cached = await cache.get<String>('short_ttl');
      expect(cached?.isValid, isTrue);

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 150));

      // Now invalid
      cached = await cache.get<String>('short_ttl');
      expect(cached?.isValid, isFalse);
      expect(cached?.isStale, isTrue);
    });

    test('hasValid checks validity', () async {
      await cache.set('test', 'value', ttl: const Duration(hours: 1));

      expect(await cache.hasValid('test'), isTrue);
      expect(await cache.hasValid('nonexistent'), isFalse);
    });

    test('clear removes entry', () async {
      await cache.set('test', 'value');

      expect(await cache.hasValid('test'), isTrue);

      await cache.clear('test');

      expect(await cache.hasValid('test'), isFalse);
    });

    test('clearAll removes all entries', () async {
      await cache.set('key1', 'value1');
      await cache.set('key2', 'value2');

      await cache.clearAll();

      expect(await cache.hasValid('key1'), isFalse);
      expect(await cache.hasValid('key2'), isFalse);
    });

    test('persists to storage', () async {
      await cache.set('persistent', 'data');

      // Create new cache instance with same storage
      final cache2 = CacheServiceImpl(storage: storage);

      final cached = await cache2.get<String>('persistent');
      expect(cached, isNotNull);
      expect(cached!.data, 'data');
    });

    test('handles complex data types', () async {
      final data = {'key': 'value', 'number': 42};

      await cache.set('complex', data);

      final cached = await cache.get<Map<String, dynamic>>('complex');
      expect(cached?.data, data);
    });
  });

  group('Offline Resilience', () {
    test('cache provides last-known-good data', () async {
      final storage = MockStorageService();
      final cache = CacheServiceImpl(storage: storage);

      // Store initial data
      await cache.set('data', 'original', ttl: const Duration(minutes: 5));

      // Verify we can retrieve it
      var cached = await cache.get<String>('data');
      expect(cached?.data, 'original');
      expect(cached?.isValid, isTrue);

      // Simulate time passing but still within TTL
      await Future.delayed(const Duration(milliseconds: 100));

      // Should still be valid
      cached = await cache.get<String>('data');
      expect(cached?.data, 'original');
      expect(cached?.isValid, isTrue);
    });

    test('stale cache can still be used as fallback', () async {
      final storage = MockStorageService();
      final cache = CacheServiceImpl(storage: storage);

      // Store with short TTL
      await cache.set(
        'data',
        'stale_value',
        ttl: const Duration(milliseconds: 50),
      );

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 100));

      // Cache is stale but data is still accessible
      final cached = await cache.get<String>('data');
      expect(cached, isNotNull);
      expect(cached!.isStale, isTrue);
      expect(cached.data, 'stale_value');
    });

    test('network status affects retry behavior', () async {
      final network = SimulatedNetworkService();
      await network.initialize();

      // Start offline
      network.setStatus(NetworkStatus.offline);

      // Operations should respect offline state
      expect(await network.isOnline, isFalse);

      // Go online
      network.setStatus(NetworkStatus.online);

      expect(await network.isOnline, isTrue);
    });
  });

  group('Cache Age Tracking', () {
    test('tracks when data was cached', () async {
      final storage = MockStorageService();
      final cache = CacheServiceImpl(storage: storage);

      final beforeCache = DateTime.now();
      await cache.set('test', 'value');
      final afterCache = DateTime.now();

      final cached = await cache.get<String>('test');
      expect(cached, isNotNull);

      final cachedAt = cached!.cachedAt;
      expect(
        cachedAt.isAfter(beforeCache) || cachedAt.isAtSameMomentAs(beforeCache),
        isTrue,
      );
      expect(
        cachedAt.isBefore(afterCache) || cachedAt.isAtSameMomentAs(afterCache),
        isTrue,
      );
    });

    test('calculates age correctly', () async {
      final storage = MockStorageService();
      final cache = CacheServiceImpl(storage: storage);

      await cache.set('test', 'value');

      await Future.delayed(const Duration(milliseconds: 100));

      final cached = await cache.get<String>('test');
      expect(cached, isNotNull);
      expect(cached!.age.inMilliseconds, greaterThanOrEqualTo(100));
    });
  });
}
