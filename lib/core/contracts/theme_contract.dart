import 'package:flutter/widgets.dart';

/// Semantic color roles for the application
/// Features reference roles, not raw colors
class AppColorScheme {
  // Primary actions and brand colors
  final Color primary;
  final Color primaryContainer;
  final Color onPrimary;

  // Secondary/accent colors
  final Color secondary;
  final Color secondaryContainer;
  final Color onSecondary;

  // Surface colors
  final Color surface;
  final Color surfaceVariant;
  final Color onSurface;
  final Color onSurfaceVariant;

  // Background
  final Color background;
  final Color onBackground;

  // Error states
  final Color error;
  final Color errorContainer;
  final Color onError;

  // Success states
  final Color success;
  final Color successContainer;
  final Color onSuccess;

  // Warning states
  final Color warning;
  final Color warningContainer;
  final Color onWarning;

  // Borders and dividers
  final Color outline;
  final Color outlineVariant;

  // Overlays and shadows
  final Color shadow;
  final Color scrim;

  const AppColorScheme({
    required this.primary,
    required this.primaryContainer,
    required this.onPrimary,
    required this.secondary,
    required this.secondaryContainer,
    required this.onSecondary,
    required this.surface,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.background,
    required this.onBackground,
    required this.error,
    required this.errorContainer,
    required this.onError,
    required this.success,
    required this.successContainer,
    required this.onSuccess,
    required this.warning,
    required this.warningContainer,
    required this.onWarning,
    required this.outline,
    required this.outlineVariant,
    required this.shadow,
    required this.scrim,
  });
}

/// Typography scale for the application
class AppTypography {
  // Display styles (largest)
  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle displaySmall;

  // Headline styles
  final TextStyle headlineLarge;
  final TextStyle headlineMedium;
  final TextStyle headlineSmall;

  // Title styles
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle titleSmall;

  // Body text
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;

  // Labels
  final TextStyle labelLarge;
  final TextStyle labelMedium;
  final TextStyle labelSmall;

  const AppTypography({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
  });
}

/// Spacing scale for consistent layouts
class AppSpacing {
  // Base unit (typically 4px)
  static const double unit = 4.0;

  // Spacing scale
  static const double xxs = unit * 1; // 4px
  static const double xs = unit * 2; // 8px
  static const double sm = unit * 3; // 12px
  static const double md = unit * 4; // 16px
  static const double lg = unit * 6; // 24px
  static const double xl = unit * 8; // 32px
  static const double xxl = unit * 12; // 48px
  static const double xxxl = unit * 16; // 64px
}

/// Border radius scale
class AppRadius {
  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 9999;
}

/// Elevation scale for shadows
class AppElevation {
  static const double none = 0;
  static const double sm = 2;
  static const double md = 4;
  static const double lg = 8;
  static const double xl = 16;
}

/// Complete theme definition
class AppTheme {
  final String name;
  final Brightness brightness;
  final AppColorScheme colors;
  final AppTypography typography;

  const AppTheme({
    required this.name,
    required this.brightness,
    required this.colors,
    required this.typography,
  });

  bool get isDark => brightness == Brightness.dark;

  bool get isLight => brightness == Brightness.light;
}

/// Service for managing themes
abstract interface class ThemeService {
  /// Current theme
  AppTheme get currentTheme;

  /// Available themes
  List<AppTheme> get availableThemes;

  /// Set theme by name
  Future<void> setTheme(String themeName);

  /// Toggle between light and dark
  Future<void> toggleBrightness();

  /// Initialize service
  Future<void> initialize();
}
