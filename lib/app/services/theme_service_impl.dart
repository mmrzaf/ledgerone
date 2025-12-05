import 'package:flutter/foundation.dart';
import '../../app/theme/default_themes.dart';
import '../../core/contracts/storage_contract.dart';
import '../../core/contracts/theme_contract.dart';

/// Implementation of ThemeService
class ThemeServiceImpl implements ThemeService {
  final StorageService _storage;

  static const String _storageKey = 'selected_theme';

  AppTheme _currentTheme = DefaultLightTheme.theme;

  static const List<AppTheme> _availableThemesList = [
    DefaultLightTheme.theme,
    DefaultDarkTheme.theme,
  ];

  ThemeServiceImpl({required StorageService storage}) : _storage = storage;

  @override
  Future<void> initialize() async {
    // Try to load saved theme
    final savedTheme = await _storage.getString(_storageKey);

    if (savedTheme != null) {
      final theme = _availableThemesList
          .where((t) => t.name == savedTheme)
          .firstOrNull;

      if (theme != null) {
        _currentTheme = theme;
        debugPrint('Theme: Restored theme "${_currentTheme.name}"');
      }
    }

    debugPrint('Theme: Initialized with "${_currentTheme.name}"');
  }

  @override
  AppTheme get currentTheme => _currentTheme;

  @override
  List<AppTheme> get availableThemes => _availableThemesList;

  @override
  Future<void> setTheme(String themeName) async {
    final theme = _availableThemesList
        .where((t) => t.name == themeName)
        .firstOrNull;

    if (theme == null) {
      debugPrint('Theme: Unknown theme "$themeName"');
      return;
    }

    _currentTheme = theme;
    await _storage.setString(_storageKey, themeName);

    debugPrint('Theme: Switched to "$themeName"');
  }

  @override
  Future<void> toggleBrightness() async {
    final newTheme = _currentTheme.isDark
        ? DefaultLightTheme.theme
        : DefaultDarkTheme.theme;

    await setTheme(newTheme.name);
  }
}
