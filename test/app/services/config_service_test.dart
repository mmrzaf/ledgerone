import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerone/app/services/config_service_impl.dart';
import 'package:ledgerone/core/contracts/storage_contract.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_remote_config_provider.dart';

class MockStorageService extends Mock implements StorageService {}

void main() {
  late MockStorageService storage;
  late TestRemoteConfigProvider remote;
  late ConfigServiceImpl configService;

  setUp(() {
    storage = MockStorageService();
    remote = TestRemoteConfigProvider();
    configService = ConfigServiceImpl(storage: storage, remoteProvider: remote);
  });

  test('getFlag returns default when storage and remote are empty', () async {
    // Arrange
    when(() => storage.getString(any())).thenAnswer((_) async => null);

    // Act
    await configService.initialize();

    // Assert (from default_flags.dart)
    expect(
      configService.getFlag('non_existent_key', defaultValue: false),
      isFalse,
    );
  });

  test('initialize loads cache and overrides defaults', () async {
    // Arrange: Cache says telemetry.enabled = FALSE
    final cachedData = json.encode({'telemetry.enabled': false});
    when(() => storage.getString(any())).thenAnswer((_) async => cachedData);

    // Act
    await configService.initialize();

    // Assert: Cache should win over default (which is true)
    expect(configService.getFlag('telemetry.enabled'), isFalse);
  });

  test('remote refresh updates values in background', () async {
    // Arrange
    when(() => storage.getString(any())).thenAnswer((_) async => null);
    when(() => storage.setString(any(), any())).thenAnswer((_) async {});

    // Act
    await configService.initialize();

    // Wait for the async refresh to complete
    await Future<void>.delayed(Duration.zero);

    // Assert
    expect(configService.getFlag('home.promo_banner.enabled'), isTrue);
    verify(() => storage.setString('config_cache', any())).called(1);
  });
}
