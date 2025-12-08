import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerone/app/services/localization_service_impl.dart';
import 'package:ledgerone/core/i18n/string_keys.dart';

import '../../helpers/mock_services.dart';

void main() {
  late MockStorageService storage;
  late LocalizationServiceImpl localization;
  setUp(() async {
    storage = MockStorageService();
    localization = LocalizationServiceImpl(storage: storage);
    await localization.initialize();
  });

  group('LocalizationServiceImpl – locales & persistence', () {
    test('exposes expected supported locales', () {
      final locales = localization.supportedLocales;

      expect(locales.length, 3);
      expect(
        locales.map((l) => l.languageCode).toList(),
        equals(<String>['en', 'de', 'fa']),
      );

      final fa = locales.firstWhere((l) => l.languageCode == 'fa');
      expect(fa.isRTL, isTrue);
      expect(fa.textDirection, TextDirection.rtl);
    });

    test('resolves app name key', () {
      expect(localization.get(L10nKeys.appName), 'LedgerOne');
    });
  });

  test('switches locale and returns proper translations', () async {
    await localization.setLocale('de');
    expect(localization.currentLocale.languageCode, 'de');
    expect(localization.get(L10nKeys.success), 'Erfolg');

    await localization.setLocale('fa');
    expect(localization.currentLocale.languageCode, 'fa');
    expect(localization.get(L10nKeys.success), 'موفقیت');
  });

  test('persists locale across restarts', () async {
    await localization.setLocale('de');

    final newService = LocalizationServiceImpl(storage: storage);
    await newService.initialize();

    expect(newService.currentLocale.languageCode, 'de');
  });

  test('isSupported matches supportedLocales', () {
    expect(localization.isSupported('en'), isTrue);
    expect(localization.isSupported('de'), isTrue);
    expect(localization.isSupported('fa'), isTrue);

    expect(localization.isSupported('es'), isFalse);
    expect(localization.isSupported('ar'), isFalse);
  });

  test('ignores unsupported locale codes', () async {
    final before = localization.currentLocale.languageCode;

    await localization.setLocale('es'); // not supported

    expect(localization.currentLocale.languageCode, before);
  });

  group('StringTranslation extension – .tr()', () {
    late MockStorageService storage;
    late LocalizationServiceImpl localization;

    setUp(() async {
      storage = MockStorageService();
      localization = LocalizationServiceImpl(storage: storage);
      await localization.initialize();
    });

    test('tr() uses English by default', () {
      final value = L10nKeys.success.tr();
      expect(value, 'Success');
    });

    test('tr() respects current locale', () async {
      await localization.setLocale('fa');

      final value = L10nKeys.success.tr();
      expect(value, 'موفقیت');
    });
  });

  group('Translation coverage (spot check)', () {
    test('selected keys have non-empty translations', () async {
      final storage = MockStorageService();
      final localization = LocalizationServiceImpl(storage: storage);
      await localization.initialize();

      const keys = <String>[
        L10nKeys.appName,
        L10nKeys.onboardingSkip,
        L10nKeys.a11yErrorIcon,
        L10nKeys.errorNetworkOffline,
        L10nKeys.errorTimeout,
        L10nKeys.networkOffline,
        L10nKeys.networkOnline,
      ];

      for (final key in keys) {
        final value = localization.get(key);
        expect(value, isNotEmpty, reason: 'Missing translation for $key');
        expect(value, isNot(key), reason: 'Key not translated: $key');
      }
    });
  });
}
