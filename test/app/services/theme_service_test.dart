import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerone/app/services/theme_service_impl.dart';
import 'package:ledgerone/app/theme/default_themes.dart';

import '../../helpers/mock_services.dart';

void main() {
  group('ThemeServiceImpl', () {
    late MockStorageService storage;
    late ThemeServiceImpl themeService;

    setUp(() async {
      storage = MockStorageService();
      themeService = ThemeServiceImpl(storage: storage);
    });

    test('initializes with light theme by default', () async {
      await themeService.initialize();

      expect(themeService.currentTheme.name, 'light');
      expect(themeService.currentTheme.brightness, Brightness.light);
      expect(themeService.currentTheme.isLight, isTrue);
      expect(themeService.currentTheme.isDark, isFalse);
    });

    test('loads saved theme from storage', () async {
      await storage.setString('selected_theme', 'dark');

      await themeService.initialize();

      expect(themeService.currentTheme.name, 'dark');
      expect(themeService.currentTheme.brightness, Brightness.dark);
      expect(themeService.currentTheme.isDark, isTrue);
    });

    test('switches theme and persists', () async {
      await themeService.initialize();

      await themeService.setTheme(DefaultDarkTheme.theme);

      expect(themeService.currentTheme.name, 'dark');

      final saved = await storage.getString('selected_theme');
      expect(saved, 'dark');
    });

    test('ignores unknown stored theme names', () async {
      // Store an invalid theme name
      await storage.setString('selected_theme', 'nonexistent');

      await themeService.initialize();

      // Should fall back to default (light) theme
      expect(themeService.currentTheme.name, 'light');
      expect(themeService.currentTheme.brightness, Brightness.light);
    });

    test('toggleBrightness switches between light and dark', () async {
      await themeService.initialize();

      expect(themeService.currentTheme.isLight, isTrue);

      await themeService.toggleBrightness();

      expect(themeService.currentTheme.isDark, isTrue);

      await themeService.toggleBrightness();

      expect(themeService.currentTheme.isLight, isTrue);
    });

    test('availableThemes returns both themes', () async {
      await themeService.initialize();

      final themes = themeService.availableThemes;

      expect(themes.length, 7);
      expect(themes.map((t) => t.name), contains('light'));
      expect(themes.map((t) => t.name), contains('dark'));
    });

    test('theme persists across service instances', () async {
      await themeService.initialize();
      await themeService.setTheme(DefaultDarkTheme.theme);

      final newService = ThemeServiceImpl(storage: storage);
      await newService.initialize();

      expect(newService.currentTheme.name, 'dark');
    });
  });

  group('DefaultLightTheme', () {
    test('has correct color scheme', () {
      const colors = DefaultLightTheme.colorScheme;

      expect(colors.primary, const Color(0xFF2563EB));
      expect(colors.surface, const Color(0xFFFFFFFF));
      expect(colors.background, const Color(0xFFFAFAFA));
      expect(colors.error, const Color(0xFFDC2626));
    });

    test('has complete typography scale', () {
      const typography = DefaultLightTheme.typography;

      expect(typography.displayLarge.fontSize, 57);
      expect(typography.headlineLarge.fontSize, 32);
      expect(typography.bodyLarge.fontSize, 16);
      expect(typography.labelSmall.fontSize, 11);
    });

    test('theme has correct properties', () {
      const theme = DefaultLightTheme.theme;

      expect(theme.name, 'light');
      expect(theme.brightness, Brightness.light);
      expect(theme.isLight, isTrue);
      expect(theme.isDark, isFalse);
    });
  });

  group('DefaultDarkTheme', () {
    test('has correct color scheme', () {
      const colors = DefaultDarkTheme.colorScheme;

      expect(colors.primary, const Color(0xFF60A5FA));
      expect(colors.surface, const Color(0xFF1F2937));
      expect(colors.background, const Color(0xFF111827));
      expect(colors.error, const Color(0xFFF87171));
    });

    test('theme has correct properties', () {
      const theme = DefaultDarkTheme.theme;

      expect(theme.name, 'dark');
      expect(theme.brightness, Brightness.dark);
      expect(theme.isDark, isTrue);
      expect(theme.isLight, isFalse);
    });
  });
}
