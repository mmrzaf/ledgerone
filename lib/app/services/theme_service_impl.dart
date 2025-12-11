import 'package:flutter/foundation.dart';
import 'package:ledgerone/core/observability/app_logger.dart';

import '../../app/theme/default_themes.dart';
import '../../core/contracts/storage_contract.dart';
import '../../core/contracts/theme_contract.dart';

/// Implementation of ThemeService with change notifications.
class ThemeServiceImpl extends ChangeNotifier implements ThemeService {
  final StorageService _storage;

  static const String _storageKey = 'selected_theme';

  AppTheme _currentTheme = AuroraLightTheme.theme;

  static final List<AppTheme> _availableThemesList = List.unmodifiable([
    AuroraLightTheme.theme, // name: aurora_light
    EmberDarkTheme.theme, // name: ember_dark
    VoidAmoledTheme.theme, // name: void_amoled
    NimbusHighContrastLightTheme.theme, // name: nimbus_high_contrast_light
    DuskHighContrastDarkTheme.theme, // name: dusk_high_contrast_dark
    ParchmentSepiaTheme.theme, // name: parchment_sepia
    MarinaBlueTheme.theme, // name: marina_blue
  ]);

  ThemeServiceImpl({required StorageService storage}) : _storage = storage;

  @override
  Future<void> initialize() async {
    try {
      final savedTheme = await _storage.getString(_storageKey);

      if (savedTheme != null) {
        final theme = _availableThemesList
            .where((t) => t.name == savedTheme)
            .firstOrNull; // or use firstWhere+orElse

        if (theme != null) {
          _currentTheme = theme;
          AppLogger.info(
            'Theme: Restored theme "${_currentTheme.name}"',
            tag: 'Theme',
          );
        }
      }
    } catch (e) {
      AppLogger.error(
        'Theme: Failed to restore theme, using default. Error: $e',
        tag: 'Theme',
      );
      _currentTheme = AuroraLightTheme.theme;
    }

    AppLogger.info(
      'Theme: Initialized with "${_currentTheme.name}"',
      tag: 'Theme',
    );
    notifyListeners();
  }

  @override
  AppTheme get currentTheme => _currentTheme;

  @override
  List<AppTheme> get availableThemes => _availableThemesList;

  @override
  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;

    try {
      await _storage.setString(_storageKey, theme.name);
    } catch (e) {
      AppLogger.error(
        'Theme: Failed to persist theme "${theme.name}": $e',
        tag: 'Theme',
      );
    }

    AppLogger.debug('Theme: Switched to "${theme.name}"', tag: 'Theme');
    notifyListeners();
  }

  @override
  Future<void> toggleBrightness() async {
    final newTheme = _currentTheme.isDark
        ? AuroraLightTheme.theme
        : EmberDarkTheme.theme;

    await setTheme(newTheme);
  }
}
