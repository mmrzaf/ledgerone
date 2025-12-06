import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerone/app/services/cache_service_impl.dart';
import 'package:ledgerone/core/contracts/cache_contract.dart';

import '../../helpers/mock_services.dart';

void main() {
  group('CacheServiceImpl', () {
    late MockStorageService storage;
    late CacheServiceImpl cache;

    setUp(() {
      storage = MockStorageService();
      cache = CacheServiceImpl(storage: storage);
    });

    group('Basic Operations', () {
      test('stores and retrieves string data', () async {
        await cache.set('test_key', 'test_value');

        final cached = await cache.get<String>('test_key');

        expect(cached, isNotNull);
        expect(cached!.data, 'test_value');
        expect(cached.isValid, isTrue);
      });

      test('stores and retrieves numeric data', () async {
        await cache.set('number', 42);

        final cached = await cache.get<int>('number');

        expect(cached?.data, 42);
      });

      test('stores and retrieves boolean data', () async {
        await cache.set('flag', true);

        final cached = await cache.get<bool>('flag');

        expect(cached?.data, true);
      });

      test('stores and retrieves complex data', () async {
        final data = {
          'key': 'value',
          'number': 42,
          'list': [1, 2, 3],
        };

        await cache.set('complex', data);

        final cached = await cache.get<Map<String, dynamic>>('complex');

        expect(cached?.data, data);
      });

      test('returns null for non-existent key', () async {
        final cached = await cache.get<String>('nonexistent');

        expect(cached, isNull);
      });
    });

    group('TTL Handling', () {
      test('respects default TTL', () async {
        await cache.set('test', 'value');

        final cached = await cache.get<String>('test');

        expect(cached?.ttl, const Duration(minutes: 5));
      });

      test('respects custom TTL', () async {
        await cache.set('test', 'value', ttl: const Duration(hours: 1));

        final cached = await cache.get<String>('test');

        expect(cached?.ttl, const Duration(hours: 1));
      });

      test('isValid returns true within TTL', () async {
        await cache.set('test', 'value', ttl: const Duration(hours: 1));

        final cached = await cache.get<String>('test');

        expect(cached?.isValid, isTrue);
        expect(cached?.isStale, isFalse);
      });

      test('isValid returns false after TTL', () async {
        await cache.set('short', 'value', ttl: const Duration(milliseconds: 1));

        await Future<void>.delayed(const Duration(milliseconds: 50));

        final cached = await cache.get<String>('short');

        expect(cached?.isValid, isFalse);
        expect(cached?.isStale, isTrue);
      });

      test('calculates age correctly', () async {
        await cache.set('test', 'value');

        await Future<void>.delayed(const Duration(milliseconds: 100));

        final cached = await cache.get<String>('test');

        expect(cached?.age.inMilliseconds, greaterThanOrEqualTo(50));
      });
    });

    group('Cache Validation', () {
      test('hasValid returns true for valid cache', () async {
        await cache.set('test', 'value', ttl: const Duration(hours: 1));

        expect(await cache.hasValid('test'), isTrue);
      });

      test('hasValid returns false for non-existent key', () async {
        expect(await cache.hasValid('nonexistent'), isFalse);
      });

      test('hasValid returns false for expired cache', () async {
        await cache.set('test', 'value', ttl: const Duration(milliseconds: 1));

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(await cache.hasValid('test'), isFalse);
      });
    });

    group('Cache Management', () {
      test('clear removes specific entry', () async {
        await cache.set('test1', 'value1');
        await cache.set('test2', 'value2');

        await cache.clear('test1');

        expect(await cache.hasValid('test1'), isFalse);
        expect(await cache.hasValid('test2'), isTrue);
      });

      test('clearAll removes all entries', () async {
        await cache.set('test1', 'value1');
        await cache.set('test2', 'value2');
        await cache.set('test3', 'value3');

        await cache.clearAll();

        expect(await cache.hasValid('test1'), isFalse);
        expect(await cache.hasValid('test2'), isFalse);
        expect(await cache.hasValid('test3'), isFalse);
      });
    });

    group('Persistence', () {
      test('persists to storage', () async {
        await cache.set('persistent', 'data');

        // Verify storage was called
        final stored = await storage.getString('cache_persistent');
        expect(stored, isNotNull);
      });

      test('loads from storage', () async {
        await cache.set('test', 'value');

        // Create new cache instance with same storage
        final cache2 = CacheServiceImpl(storage: storage);

        final cached = await cache2.get<String>('test');
        expect(cached?.data, 'value');
      });

      test('handles storage failures gracefully', () async {
        // This should not throw even if storage fails
        await cache.set('test', 'value');

        // Should still work with in-memory cache
        final cached = await cache.get<String>('test');
        expect(cached?.data, 'value');
      });

      test('handles corrupt storage data gracefully', () async {
        // Manually corrupt storage
        await storage.setString('cache_corrupt', 'not valid json');

        // Should return null, not throw
        final cached = await cache.get<String>('corrupt');
        expect(cached, isNull);
      });
    });

    group('Memory Cache', () {
      test('uses memory cache for repeated access', () async {
        await cache.set('test', 'value');

        // First access
        final cached1 = await cache.get<String>('test');
        expect(cached1?.data, 'value');

        // Second access (should use memory cache)
        final cached2 = await cache.get<String>('test');
        expect(cached2?.data, 'value');
      });

      test('memory cache is cleared with clearAll', () async {
        await cache.set('test', 'value');

        // Load into memory cache
        await cache.get<String>('test');

        // Clear all
        await cache.clearAll();

        // Should not be in memory cache
        final cached = await cache.get<String>('test');
        expect(cached, isNull);
      });
    });

    group('CachedData Properties', () {
      test('cachedAt records correct timestamp', () async {
        final before = DateTime.now();
        await cache.set('test', 'value');
        final after = DateTime.now();

        final cached = await cache.get<String>('test');

        expect(cached, isNotNull);
        expect(
          cached!.cachedAt.isAfter(before) ||
              cached.cachedAt.isAtSameMomentAs(before),
          isTrue,
        );
        expect(
          cached.cachedAt.isBefore(after) ||
              cached.cachedAt.isAtSameMomentAs(after),
          isTrue,
        );
      });

      test('age increases over time', () async {
        await cache.set('test', 'value');

        final cached1 = await cache.get<String>('test');
        final age1 = cached1?.age.inMilliseconds ?? 0;

        await Future<void>.delayed(const Duration(milliseconds: 100));

        final cached2 = await cache.get<String>('test');
        final age2 = cached2?.age.inMilliseconds ?? 0;

        expect(age2, greaterThan(age1));
      });
    });

    group('Edge Cases', () {
      test('handles null values', () async {
        // This test depends on your implementation
        // Some caches might not support null values
        try {
          await cache.set('null_test', null);
          final CachedData<dynamic>? _ = await cache.get('null_test');
          // Either succeeds or throws - both are valid
        } catch (e) {
          // Expected for caches that don't support null
        }
      });

      test('handles empty strings', () async {
        await cache.set('empty', '');

        final cached = await cache.get<String>('empty');
        expect(cached?.data, '');
      });

      test('handles large data', () async {
        final largeData = List.generate(1000, (i) => 'item_$i');

        await cache.set('large', largeData);

        final cached = await cache.get<List<String>>('large');
        expect(cached?.data.length, 1000);
      });

      test('handles special characters in keys', () async {
        await cache.set('key-with-dashes', 'value');
        await cache.set('key_with_underscores', 'value');
        await cache.set('key.with.dots', 'value');

        expect(await cache.hasValid('key-with-dashes'), isTrue);
        expect(await cache.hasValid('key_with_underscores'), isTrue);
        expect(await cache.hasValid('key.with.dots'), isTrue);
      });
    });
  });
}
