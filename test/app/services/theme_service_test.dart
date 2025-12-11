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

    test('initializes with Aurora light theme by default', () async {
      await themeService.initialize();

      expect(themeService.currentTheme.name, 'aurora_light');
      expect(themeService.currentTheme.brightness, Brightness.light);
      expect(themeService.currentTheme.isLight, isTrue);
      expect(themeService.currentTheme.isDark, isFalse);
    });

    test('loads saved theme from storage', () async {
      // Persist Ember dark theme
      await storage.setString('selected_theme', 'ember_dark');

      await themeService.initialize();

      expect(themeService.currentTheme.name, 'ember_dark');
      expect(themeService.currentTheme.brightness, Brightness.dark);
      expect(themeService.currentTheme.isDark, isTrue);
      expect(themeService.currentTheme.isLight, isFalse);
    });

    test('switches theme and persists', () async {
      await themeService.initialize();

      await themeService.setTheme(EmberDarkTheme.theme);

      expect(themeService.currentTheme.name, 'ember_dark');

      final saved = await storage.getString('selected_theme');
      expect(saved, 'ember_dark');
    });

    test('ignores unknown stored theme names', () async {
      // Store an invalid theme name
      await storage.setString('selected_theme', 'nonexistent');

      await themeService.initialize();

      // Should fall back to default Aurora light theme
      expect(themeService.currentTheme.name, 'aurora_light');
      expect(themeService.currentTheme.brightness, Brightness.light);
      expect(themeService.currentTheme.isLight, isTrue);
    });

    test(
      'toggleBrightness switches between Aurora light and Ember dark',
      () async {
        await themeService.initialize();

        // Start on light
        expect(themeService.currentTheme.isLight, isTrue);
        expect(themeService.currentTheme.name, 'aurora_light');

        await themeService.toggleBrightness();

        // Should now be Ember dark
        expect(themeService.currentTheme.isDark, isTrue);
        expect(themeService.currentTheme.name, 'ember_dark');

        await themeService.toggleBrightness();

        // And back to Aurora light
        expect(themeService.currentTheme.isLight, isTrue);
        expect(themeService.currentTheme.name, 'aurora_light');
      },
    );

    test('availableThemes returns all configured themes', () async {
      await themeService.initialize();

      final themes = themeService.availableThemes;

      expect(themes.length, 7);
      final names = themes.map((t) => t.name).toList();

      expect(names, contains('aurora_light'));
      expect(names, contains('ember_dark'));
      expect(names, contains('void_amoled'));
      expect(names, contains('nimbus_high_contrast_light'));
      expect(names, contains('dusk_high_contrast_dark'));
      expect(names, contains('parchment_sepia'));
      expect(names, contains('marina_blue'));
    });

    test('theme persists across service instances', () async {
      await themeService.initialize();
      await themeService.setTheme(EmberDarkTheme.theme);

      final newService = ThemeServiceImpl(storage: storage);
      await newService.initialize();

      expect(newService.currentTheme.name, 'ember_dark');
      expect(newService.currentTheme.isDark, isTrue);
    });
  });

  group('AuroraLightTheme', () {
    test('has correct color scheme', () {
      const colors = AuroraLightTheme.colorScheme;

      expect(colors.primary, const Color(0xFF2563EB));
      expect(colors.surface, const Color(0xFFFFFFFF));
      // Updated background to match new palette
      expect(colors.background, const Color(0xFFF4F6FB));
      expect(colors.error, const Color(0xFFDC2626));
    });

    test('theme has correct properties', () {
      const theme = AuroraLightTheme.theme;

      expect(theme.name, 'aurora_light');
      expect(theme.brightness, Brightness.light);
      expect(theme.isLight, isTrue);
      expect(theme.isDark, isFalse);
    });
  });

  group('EmberDarkTheme', () {
    test('has correct color scheme', () {
      const colors = EmberDarkTheme.colorScheme;

      // Updated to new Ember palette
      expect(colors.primary, const Color(0xFFF97316)); // warm orange
      expect(colors.surface, const Color(0xFF111827)); // charcoal
      expect(colors.background, const Color(0xFF020617)); // near-black
      expect(colors.error, const Color(0xFFF97373)); // softer red
    });

    test('theme has correct properties', () {
      const theme = EmberDarkTheme.theme;

      expect(theme.name, 'ember_dark');
      expect(theme.brightness, Brightness.dark);
      expect(theme.isDark, isTrue);
      expect(theme.isLight, isFalse);
    });
  });
}
