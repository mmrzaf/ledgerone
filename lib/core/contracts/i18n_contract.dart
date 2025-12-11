import 'package:flutter/widgets.dart';
import 'package:ledgerone/app/services/localization_service_impl.dart';

/// Locale information
class LocaleInfo {
  final String languageCode;
  final String? countryCode;
  final String displayName;
  final TextDirection textDirection;

  const LocaleInfo({
    required this.languageCode,
    this.countryCode,
    required this.displayName,
    required this.textDirection,
  });

  Locale get locale => Locale(languageCode, countryCode);

  bool get isRTL => textDirection == TextDirection.rtl;

  String get localeCode =>
      countryCode != null ? '${languageCode}_$countryCode' : languageCode;
}

/// Service for managing localization
abstract interface class LocalizationService implements Listenable {
  /// Current locale
  LocaleInfo get currentLocale;

  /// All supported locales
  List<LocaleInfo> get supportedLocales;

  /// Set current locale
  Future<void> setLocale(String languageCode, {String? countryCode});

  /// Get localized string by key
  String get(String key, {Map<String, dynamic>? args});

  /// Check if locale is supported
  bool isSupported(String languageCode, {String? countryCode});

  /// Initialize service
  Future<void> initialize();
}

/// Extension for easy access to localization in widgets
extension LocalizationContext on BuildContext {
  LocalizationService get l10n {
    // In production, use InheritedWidget or Provider
    // For now, use a simple static instance
    return LocalizationServiceImpl.instance;
  }
}
