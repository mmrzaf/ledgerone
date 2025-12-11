import 'package:flutter/widgets.dart';
import 'package:ledgerone/core/observability/app_logger.dart';

import '../../core/contracts/i18n_contract.dart';
import '../../core/contracts/storage_contract.dart';
import '../../core/i18n/translations.dart';

/// Implementation of LocalizationService
class LocalizationServiceImpl extends ChangeNotifier
    implements LocalizationService {
  final StorageService _storage;

  // Singleton instance for easy access (used by .tr extension)
  static late LocalizationServiceImpl instance;

  static const String _storageKey = 'selected_locale';

  LocaleInfo _currentLocale = _supportedLocalesList[0]; // Default to English

  // Supported locales with RTL information
  static const List<LocaleInfo> _supportedLocalesList = [
    LocaleInfo(
      languageCode: 'en',
      displayName: 'English',
      textDirection: TextDirection.ltr,
    ),
    LocaleInfo(
      languageCode: 'de',
      displayName: 'Deutsch',
      textDirection: TextDirection.ltr,
    ),
    LocaleInfo(
      languageCode: 'fa',
      displayName: 'فارسی',
      textDirection: TextDirection.rtl,
    ),
  ];

  LocalizationServiceImpl({required StorageService storage})
    : _storage = storage {
    instance = this;
  }

  @override
  Future<void> initialize() async {
    // Try to load saved locale
    final savedLocale = await _storage.getString(_storageKey);

    if (savedLocale != null) {
      final parts = savedLocale.split('_');
      final languageCode = parts[0];
      final countryCode = parts.length > 1 ? parts[1] : null;

      if (isSupported(languageCode, countryCode: countryCode)) {
        _currentLocale = _supportedLocalesList.firstWhere(
          (locale) => locale.languageCode == languageCode,
        );
        AppLogger.info(
          'Localization: Restored locale ${_currentLocale.localeCode}',
          tag: 'Localization',
        );
      }
    }

    AppLogger.info(
      'Localization: Initialized with ${_currentLocale.localeCode}',
      tag: 'Localization',
    );
    notifyListeners();
  }

  @override
  LocaleInfo get currentLocale => _currentLocale;

  @override
  List<LocaleInfo> get supportedLocales => _supportedLocalesList;

  @override
  Future<void> setLocale(String languageCode, {String? countryCode}) async {
    if (!isSupported(languageCode, countryCode: countryCode)) {
      AppLogger.warning(
        'Localization: Unsupported locale $languageCode',
        tag: 'Localization',
      );
      return;
    }

    _currentLocale = _supportedLocalesList.firstWhere(
      (locale) => locale.languageCode == languageCode,
    );

    // Save to storage
    await _storage.setString(_storageKey, _currentLocale.localeCode);

    AppLogger.debug(
      'Localization: Switched to ${_currentLocale.localeCode}',
      tag: 'Localization',
    );
    notifyListeners();
  }

  @override
  String get(String key, {Map<String, dynamic>? args}) {
    final localeCode = _currentLocale.languageCode;
    final translations = allTranslations[localeCode];

    if (translations == null) {
      AppLogger.warning(
        'Localization: No translations for $localeCode',
        tag: 'Localization',
      );
      return key;
    }

    String? raw = translations[key];

    if (raw == null) {
      AppLogger.warning(
        'Localization: Missing key "$key" for $localeCode',
        tag: 'Localization',
      );
      raw = allTranslations['en']?[key] ?? key;
    }

    var translation = raw;

    if (args != null) {
      args.forEach((argKey, value) {
        translation = translation.replaceAll('{$argKey}', value.toString());
      });
    }

    return translation;
  }

  @override
  bool isSupported(String languageCode, {String? countryCode}) {
    return _supportedLocalesList.any(
      (locale) => locale.languageCode == languageCode,
    );
  }
}

/// Extension for easy string translation
extension StringTranslation on String {
  String tr({Map<String, dynamic>? args}) {
    return LocalizationServiceImpl.instance.get(this, args: args);
  }
}
