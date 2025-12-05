import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/contracts/i18n_contract.dart';
import '../core/contracts/theme_contract.dart';
import '../core/i18n/string_keys.dart';

/// Root application widget with i18n and theming support
class App extends StatefulWidget {
  final GoRouter router;
  final LocalizationService localization;
  final ThemeService themeService;

  const App({
    required this.router,
    required this.localization,
    required this.themeService,
    super.key,
  });

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    final theme = widget.themeService.currentTheme;
    final locale = widget.localization.currentLocale;

    return MaterialApp.router(
      title: widget.localization.get(L10nKeys.appName),

      // Theme configuration
      theme: _buildThemeData(theme),
      darkTheme: _buildThemeData(DefaultDarkTheme.theme),
      themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,

      // Localization configuration
      locale: locale.locale,
      supportedLocales: widget.localization.supportedLocales
          .map((l) => l.locale)
          .toList(),

      // Router configuration
      routerConfig: widget.router,

      debugShowCheckedModeBanner: false,

      // Accessibility configuration
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Clamp text scaling for better readability
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(1.0, 2.0),
            ),
          ),
          child: Directionality(
            textDirection: locale.textDirection,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  /// Build ThemeData from AppTheme
  ThemeData _buildThemeData(AppTheme appTheme) {
    final colors = appTheme.colors;
    final typography = appTheme.typography;

    return ThemeData(
      useMaterial3: true,
      brightness: appTheme.brightness,

      // Color scheme
      colorScheme: ColorScheme(
        brightness: appTheme.brightness,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        primaryContainer: colors.primaryContainer,
        secondary: colors.secondary,
        onSecondary: colors.onSecondary,
        secondaryContainer: colors.secondaryContainer,
        error: colors.error,
        onError: colors.onError,
        errorContainer: colors.errorContainer,
        surface: colors.surface,
        onSurface: colors.onSurface,
        surfaceContainerHighest: colors.surfaceVariant,
        outline: colors.outline,
        shadow: colors.shadow,
        scrim: colors.scrim,
      ),

      // Typography
      textTheme: TextTheme(
        displayLarge: typography.displayLarge.copyWith(
          color: colors.onBackground,
        ),
        displayMedium: typography.displayMedium.copyWith(
          color: colors.onBackground,
        ),
        displaySmall: typography.displaySmall.copyWith(
          color: colors.onBackground,
        ),
        headlineLarge: typography.headlineLarge.copyWith(
          color: colors.onSurface,
        ),
        headlineMedium: typography.headlineMedium.copyWith(
          color: colors.onSurface,
        ),
        headlineSmall: typography.headlineSmall.copyWith(
          color: colors.onSurface,
        ),
        titleLarge: typography.titleLarge.copyWith(color: colors.onSurface),
        titleMedium: typography.titleMedium.copyWith(color: colors.onSurface),
        titleSmall: typography.titleSmall.copyWith(
          color: colors.onSurfaceVariant,
        ),
        bodyLarge: typography.bodyLarge.copyWith(color: colors.onSurface),
        bodyMedium: typography.bodyMedium.copyWith(color: colors.onSurface),
        bodySmall: typography.bodySmall.copyWith(
          color: colors.onSurfaceVariant,
        ),
        labelLarge: typography.labelLarge.copyWith(color: colors.onSurface),
        labelMedium: typography.labelMedium.copyWith(
          color: colors.onSurfaceVariant,
        ),
        labelSmall: typography.labelSmall.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),

      // Component themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(88, 48), // Accessible touch target
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.outline, width: 1),
        ),
      ),

      // Icon theme
      iconTheme: IconThemeData(color: colors.onSurface, size: 24),
    );
  }
}

// Reference to default themes for the builder
class DefaultDarkTheme {
  static const theme = AppTheme(
    name: 'dark',
    brightness: Brightness.dark,
    colors: AppColorScheme(
      primary: Color(0xFF60A5FA),
      primaryContainer: Color(0xFF1E3A8A),
      onPrimary: Color(0xFF000000),
      secondary: Color(0xFFA78BFA),
      secondaryContainer: Color(0xFF5B21B6),
      onSecondary: Color(0xFF000000),
      surface: Color(0xFF1F2937),
      surfaceVariant: Color(0xFF374151),
      onSurface: Color(0xFFE5E7EB),
      onSurfaceVariant: Color(0xFF9CA3AF),
      background: Color(0xFF111827),
      onBackground: Color(0xFFE5E7EB),
      error: Color(0xFFF87171),
      errorContainer: Color(0xFF7F1D1D),
      onError: Color(0xFF000000),
      success: Color(0xFF4ADE80),
      successContainer: Color(0xFF14532D),
      onSuccess: Color(0xFF000000),
      warning: Color(0xFFFB923C),
      warningContainer: Color(0xFF7C2D12),
      onWarning: Color(0xFF000000),
      outline: Color(0xFF4B5563),
      outlineVariant: Color(0xFF374151),
      shadow: Color(0x66000000),
      scrim: Color(0xCC000000),
    ),
    typography: AppTypography(
      displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400),
      displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    ),
  );
}
