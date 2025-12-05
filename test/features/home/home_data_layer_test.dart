import 'package:app_flutter_starter/app/services/cache_service_impl.dart';
import 'package:app_flutter_starter/core/contracts/cache_contract.dart';
import 'package:app_flutter_starter/core/errors/app_error.dart';
import 'package:app_flutter_starter/core/errors/result.dart';
import 'package:app_flutter_starter/core/network/http_client_contract.dart';
import 'package:app_flutter_starter/features/home/data/home_local_data_source.dart';
import 'package:app_flutter_starter/features/home/data/home_remote_data_source.dart';
import 'package:app_flutter_starter/features/home/data/home_repository_impl.dart';
import 'package:app_flutter_starter/features/home/domain/home_models.dart';
import 'package:app_flutter_starter/features/home/domain/home_repository.dart';
import 'package:app_flutter_starter/features/home/domain/home_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_services.dart';

class MockHttpClient implements HttpClient {
  dynamic Function()? responseProvider;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    if (responseProvider == null) {
      throw const AppError(
        category: ErrorCategory.server5xx,
        message: 'No response provider',
      );
    }
    return responseProvider!();
  }

  @override
  Future<dynamic> post(String path, {dynamic body}) async {
    throw UnimplementedError();
  }

  @override
  Future<dynamic> put(String path, {dynamic body}) async {
    throw UnimplementedError();
  }

  @override
  Future<dynamic> delete(String path) async {
    throw UnimplementedError();
  }
}

void main() {
  group('HomeLocalDataSourceImpl', () {
    late CacheService cache;
    late HomeLocalDataSource dataSource;

    setUp(() {
      final storage = MockStorageService();
      cache = CacheServiceImpl(storage: storage);
      dataSource = HomeLocalDataSourceImpl(cache);
    });

    test('returns null when no cached data', () async {
      final result = await dataSource.get();
      expect(result, isNull);
    });

    test('stores and retrieves home data', () async {
      final data = HomeData(
        message: 'Test message',
        timestamp: DateTime(2025, 1, 1),
      );

      await dataSource.set(data);
      final cached = await dataSource.get();

      expect(cached, isNotNull);
      expect(cached!.data.message, 'Test message');
      expect(cached.data.timestamp, DateTime(2025, 1, 1));
    });

    test('clears cached data', () async {
      final data = HomeData(message: 'Test', timestamp: DateTime(2025, 1, 1));

      await dataSource.set(data);
      await dataSource.clear();

      final cached = await dataSource.get();
      expect(cached, isNull);
    });

    test('cached data respects TTL', () async {
      final data = HomeData(message: 'Test', timestamp: DateTime(2025, 1, 1));

      await dataSource.set(data);
      final cached = await dataSource.get();

      expect(cached!.isValid, isTrue);
      expect(cached.ttl, const Duration(minutes: 10));
    });
  });

  group('HomeRemoteDataSourceImpl', () {
    late MockHttpClient httpClient;
    late HomeRemoteDataSource dataSource;

    setUp(() {
      httpClient = MockHttpClient();
      dataSource = HomeRemoteDataSourceImpl(httpClient);
    });

    test('fetches home data successfully', () async {
      httpClient.responseProvider = () => {
        'message': 'Remote data',
        'timestamp': '2025-01-01T00:00:00.000',
      };

      final data = await dataSource.fetchHomeData();

      expect(data.message, 'Remote data');
      expect(data.timestamp, DateTime(2025, 1, 1));
    });

    test('handles wrapped data response', () async {
      httpClient.responseProvider = () => {
        'data': {
          'message': 'Wrapped data',
          'timestamp': '2025-01-01T00:00:00.000',
        },
      };

      final data = await dataSource.fetchHomeData();

      expect(data.message, 'Wrapped data');
    });

    test('throws parseError on invalid response shape', () async {
      httpClient.responseProvider = () => 'invalid string response';

      expect(
        () => dataSource.fetchHomeData(),
        throwsA(
          isA<AppError>().having(
            (e) => e.category,
            'category',
            ErrorCategory.parseError,
          ),
        ),
      );
    });

    test('propagates AppError from HTTP client', () async {
      httpClient.responseProvider = () {
        throw const AppError(
          category: ErrorCategory.timeout,
          message: 'Timeout',
        );
      };

      expect(
        () => dataSource.fetchHomeData(),
        throwsA(
          isA<AppError>().having(
            (e) => e.category,
            'category',
            ErrorCategory.timeout,
          ),
        ),
      );
    });

    test('wraps non-AppError exceptions', () async {
      httpClient.responseProvider = () {
        throw Exception('Random error');
      };

      expect(
        () => dataSource.fetchHomeData(),
        throwsA(
          isA<AppError>().having(
            (e) => e.category,
            'category',
            ErrorCategory.server5xx,
          ),
        ),
      );
    });
  });

  group('HomeRepositoryImpl', () {
    late MockHomeLocalDataSource local;
    late MockHomeRemoteDataSource remote;
    late HomeRepository repository;

    setUp(() {
      local = MockHomeLocalDataSource();
      remote = MockHomeRemoteDataSource();
      repository = HomeRepositoryImpl(remote: remote, local: local);
    });

    test('returns fresh data on successful load', () async {
      final freshData = HomeData(
        message: 'Fresh data',
        timestamp: DateTime(2025, 1, 1),
      );
      remote.nextResponse = freshData;

      final result = await repository.load();

      expect(result, isA<Success<HomeData>>());
      expect((result as Success<HomeData>).data.message, 'Fresh data');
      expect(local.storedData?.message, 'Fresh data'); // Should cache
    });

    test('falls back to cached data on failure', () async {
      final cachedData = HomeData(
        message: 'Cached data',
        timestamp: DateTime(2025, 1, 1),
      );
      local.cachedData = CachedData(
        data: cachedData,
        cachedAt: DateTime.now(),
        ttl: const Duration(minutes: 10),
      );
      remote.shouldFail = true;

      final result = await repository.load();

      expect(result, isA<Success<HomeData>>());
      expect((result as Success<HomeData>).data.message, 'Cached data');
    });

    test('returns error when no cached data available', () async {
      remote.shouldFail = true;

      final result = await repository.load();

      expect(result, isA<Failure<HomeData>>());
      expect(
        (result as Failure<HomeData>).error.category,
        ErrorCategory.timeout,
      );
    });

    test('forceRefresh bypasses cache check', () async {
      final freshData = HomeData(
        message: 'Forced fresh',
        timestamp: DateTime(2025, 1, 1),
      );
      remote.nextResponse = freshData;

      await repository.load(forceRefresh: true);

      expect(local.storedData?.message, 'Forced fresh');
    });
  });

  group('HomeData', () {
    test('serializes to JSON correctly', () {
      final data = HomeData(message: 'Test', timestamp: DateTime(2025, 1, 1));

      final json = data.toJson();

      expect(json['message'], 'Test');
      expect(json['timestamp'], '2025-01-01T00:00:00.000');
    });

    test('deserializes from JSON correctly', () {
      final json = {'message': 'Test', 'timestamp': '2025-01-01T00:00:00.000'};

      final data = HomeData.fromJson(json);

      expect(data.message, 'Test');
      expect(data.timestamp, DateTime(2025, 1, 1));
    });
  });
}

// Test doubles
class MockHomeLocalDataSource implements HomeLocalDataSource {
  CachedData<HomeData>? cachedData;
  HomeData? storedData;

  @override
  Future<CachedData<HomeData>?> get() async => cachedData;

  @override
  Future<void> set(HomeData data) async {
    storedData = data;
  }

  @override
  Future<void> clear() async {
    cachedData = null;
    storedData = null;
  }
}

class MockHomeRemoteDataSource implements HomeRemoteDataSource {
  HomeData? nextResponse;
  bool shouldFail = false;

  @override
  Future<HomeData> fetchHomeData() async {
    if (shouldFail) {
      throw const AppError(
        category: ErrorCategory.timeout,
        message: 'Simulated failure',
      );
    }
    if (nextResponse == null) {
      throw const AppError(
        category: ErrorCategory.server5xx,
        message: 'No response set',
      );
    }
    return nextResponse!;
  }
}
