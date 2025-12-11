import 'package:flutter/foundation.dart';

import '../../app/theme/default_themes.dart';
import '../../core/contracts/storage_contract.dart';
import '../../core/contracts/theme_contract.dart';

/// Implementation of ThemeService with change notifications.
class ThemeServiceImpl extends ChangeNotifier implements ThemeService {
  final StorageService _storage;

  static const String _storageKey = 'selected_theme';

  AppTheme _currentTheme = DefaultLightTheme.theme;

  static final List<AppTheme> _availableThemesList = List.unmodifiable([
    DefaultLightTheme.theme, // name: light
    DefaultDarkTheme.theme, // name: dark
    MidnightAmoledTheme.theme, // name: amoled_dark
    HighContrastLightTheme.theme, // name: high_contrast_light
    HighContrastDarkTheme.theme, // name: high_contrast_dark
    SepiaTheme.theme, // name: sepia
    BlueBrandTheme.theme, // name: blue
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
          debugPrint('Theme: Restored theme "${_currentTheme.name}"');
        }
      }
    } catch (e) {
      debugPrint('Theme: Failed to restore theme, using default. Error: $e');
      _currentTheme = DefaultLightTheme.theme;
    }

    debugPrint('Theme: Initialized with "${_currentTheme.name}"');
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
      debugPrint('Theme: Failed to persist theme "${theme.name}": $e');
    }

    debugPrint('Theme: Switched to "${theme.name}"');
    notifyListeners();
  }

  @override
  Future<void> toggleBrightness() async {
    final newTheme = _currentTheme.isDark
        ? DefaultLightTheme.theme
        : DefaultDarkTheme.theme;

    await setTheme(newTheme);
  }
}
