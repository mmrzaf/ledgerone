import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app_flutter_starter/core/contracts/storage_contract.dart';
import 'package:app_flutter_starter/core/contracts/config_provider.dart';
import 'package:app_flutter_starter/app/services/config_service_impl.dart';

class MockStorageService extends Mock implements StorageService {}

class MockRemoteConfigProvider extends Mock implements RemoteConfigProvider {}

void main() {
  late MockStorageService storage;
  late MockRemoteConfigProvider remote;
  late ConfigServiceImpl configService;

  setUp(() {
    storage = MockStorageService();
    remote = MockRemoteConfigProvider();
    configService = ConfigServiceImpl(storage: storage, remoteProvider: remote);
  });

  test('getFlag returns default when storage and remote are empty', () async {
    // Arrange
    when(() => storage.getString(any())).thenAnswer((_) async => null);
    when(
      () => remote.fetchConfig(),
    ).thenAnswer((_) async => {}); // Empty remote

    // Act
    await configService.initialize();

    // Assert (from default_flags.dart)
    expect(configService.getFlag('auth.enabled'), isTrue);
    expect(
      configService.getFlag('non_existent_key', defaultValue: false),
      isFalse,
    );
  });

  test('initialize loads cache and overrides defaults', () async {
    // Arrange: Cache says auth.enabled = FALSE
    final cachedData = json.encode({'auth.enabled': false});
    when(() => storage.getString(any())).thenAnswer((_) async => cachedData);
    when(() => remote.fetchConfig()).thenAnswer(
      (_) async => Completer<Map<String, dynamic>>().future,
    ); // Hang remote

    // Act
    await configService.initialize();

    // Assert: Cache should win over default (which is true)
    expect(configService.getFlag('auth.enabled'), isFalse);
  });

  test('remote refresh updates values in background', () async {
    // Arrange
    when(() => storage.getString(any())).thenAnswer((_) async => null);
    // Remote returns a value
    when(
      () => remote.fetchConfig(),
    ).thenAnswer((_) async => {'home.promo_banner.enabled': true});
    when(() => storage.setString(any(), any())).thenAnswer((_) async {});

    // Act
    await configService.initialize();

    // Wait for the unawaited async refresh to complete
    await Future.delayed(Duration.zero);

    // Assert
    expect(configService.getFlag('home.promo_banner.enabled'), isTrue);
    verify(() => storage.setString('config_cache', any())).called(1);
  });
}
