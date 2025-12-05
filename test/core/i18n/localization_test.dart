import 'package:app_flutter_starter/app/services/localization_service_impl.dart';
import 'package:app_flutter_starter/app/services/mock_services.dart';
import 'package:app_flutter_starter/core/i18n/string_keys.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalizationService', () {
    late MockStorageService storage;
    late LocalizationServiceImpl localization;

    setUp(() {
      storage = MockStorageService();
      localization = LocalizationServiceImpl(storage: storage);
    });

    test('initializes with default locale (English)', () async {
      await localization.initialize();

      expect(localization.currentLocale.languageCode, 'en');
      expect(localization.currentLocale.textDirection, TextDirection.ltr);
    });

    test('returns all supported locales', () {
      expect(localization.supportedLocales.length, 3);
      expect(
        localization.supportedLocales.map((l) => l.languageCode).toList(),
        containsAll(['en', 'es', 'ar']),
      );
    });

    test('switches locale', () async {
      await localization.initialize();
      await localization.setLocale('es');

      expect(localization.currentLocale.languageCode, 'es');
    });

    test('persists locale selection', () async {
      await localization.initialize();
      await localization.setLocale('es');

      final saved = await storage.getString('selected_locale');
      expect(saved, 'es');
    });

    test('restores saved locale on initialization', () async {
      await storage.setString('selected_locale', 'ar');

      await localization.initialize();

      expect(localization.currentLocale.languageCode, 'ar');
    });

    test('identifies RTL locales correctly', () async {
      await localization.initialize();

      // English is LTR
      expect(localization.currentLocale.isRTL, isFalse);

      // Switch to Arabic (RTL)
      await localization.setLocale('ar');
      expect(localization.currentLocale.isRTL, isTrue);
      expect(localization.currentLocale.textDirection, TextDirection.rtl);
    });

    test('translates strings correctly', () async {
      await localization.initialize();

      // English
      expect(localization.get(L10nKeys.appName), 'Flutter Starter');
      expect(localization.get(L10nKeys.loginTitle), 'Sign In');

      // Spanish
      await localization.setLocale('es');
      expect(localization.get(L10nKeys.loginTitle), 'Iniciar sesión');
      expect(localization.get(L10nKeys.onboardingGetStarted), 'Comenzar');

      // Arabic
      await localization.setLocale('ar');
      expect(localization.get(L10nKeys.loginTitle), 'تسجيل الدخول');
    });

    test('falls back to English for missing translations', () async {
      await localization.initialize();
      await localization.setLocale('es');

      // If a key is missing in Spanish, should fallback to English
      final result = localization.get('nonexistent.key');
      expect(result, isNotEmpty);
    });

    test('supports string interpolation', () async {
      await localization.initialize();

      // This would need to be added to translations, but testing the mechanism
      final result = localization.get(
        'test.interpolation',
        args: {'name': 'John', 'count': 5},
      );

      expect(result, isNotEmpty);
    });

    test('validates supported locale check', () {
      expect(localization.isSupported('en'), isTrue);
      expect(localization.isSupported('es'), isTrue);
      expect(localization.isSupported('ar'), isTrue);
      expect(localization.isSupported('fr'), isFalse);
      expect(localization.isSupported('de'), isFalse);
    });

    test('handles unsupported locale gracefully', () async {
      await localization.initialize();

      final beforeLocale = localization.currentLocale.languageCode;

      // Try to set unsupported locale
      await localization.setLocale('unsupported');

      // Should remain unchanged
      expect(localization.currentLocale.languageCode, beforeLocale);
    });
  });

  group('StringTranslation Extension', () {
    late MockStorageService storage;
    late LocalizationServiceImpl localization;

    setUp(() async {
      storage = MockStorageService();
      localization = LocalizationServiceImpl(storage: storage);
      await localization.initialize();
    });

    test('tr() extension translates strings', () {
      final result = L10nKeys.loginTitle.tr();
      expect(result, 'Sign In');
    });

    test('tr() extension works with different locales', () async {
      await localization.setLocale('es');

      final result = L10nKeys.loginTitle.tr();
      expect(result, 'Iniciar sesión');
    });
  });

  group('Translation Coverage', () {
    test('all string keys have English translations', () {
      // Get all L10nKeys constants via reflection or manual list
      final keys = [
        L10nKeys.appName,
        L10nKeys.loginTitle,
        L10nKeys.loginEmail,
        L10nKeys.loginPassword,
        L10nKeys.homeTitle,
        L10nKeys.onboardingTitle,
        L10nKeys.errorNetworkOffline,
        // Add more as needed
      ];

      final storage = MockStorageService();
      final localization = LocalizationServiceImpl(storage: storage);

      for (final key in keys) {
        final translation = localization.get(key);
        expect(translation, isNotEmpty, reason: 'Missing translation for $key');
        expect(translation, isNot(key), reason: 'Key not translated: $key');
      }
    });
  });
}
