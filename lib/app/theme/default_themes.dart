import 'package:flutter/material.dart';

import '../../core/contracts/theme_contract.dart';

/// Default light theme
@immutable
class DefaultLightTheme {
  const DefaultLightTheme._();

  static const AppColorScheme colorScheme = AppColorScheme(
    // Primary brand
    primary: Color(0xFF2563EB), // Blue-600
    primaryContainer: Color(0xFFDCEAFB),
    onPrimary: Color(0xFFFFFFFF),

    // Secondary / accent
    secondary: Color(0xFF7C3AED), // Violet-600
    secondaryContainer: Color(0xFFEDE9FE),
    onSecondary: Color(0xFFFFFFFF),

    // Surfaces
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF9FAFB),
    onSurface: Color(0xFF111827),
    onSurfaceVariant: Color(0xFF6B7280),

    // Background
    background: Color(0xFFFAFAFA),
    onBackground: Color(0xFF111827),

    // Error
    error: Color(0xFFDC2626), // Red-600
    errorContainer: Color(0xFFFEE2E2),
    onError: Color(0xFFFFFFFF),

    // Success
    success: Color(0xFF16A34A), // Green-600
    successContainer: Color(0xFFDCFCE7),
    onSuccess: Color(0xFFFFFFFF),

    // Warning
    warning: Color(0xFFEA580C), // Orange-600
    warningContainer: Color(0xFFFFEDD5),
    onWarning: Color(0xFFFFFFFF),

    // Borders / outline
    outline: Color(0xFFD1D5DB),
    outlineVariant: Color(0xFFE5E7EB),

    // Overlays
    shadow: Color(0x1A000000),
    scrim: Color(0x99000000),
  );

  static const AppTypography typography = AppTypography(
    // Display
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      height: 1.12,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      height: 1.22,
    ),

    // Headline
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.33,
    ),

    // Title
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      height: 1.5,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),

    // Body
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.43,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.33,
    ),

    // Labels
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.33,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.45,
    ),
  );

  static const AppTheme theme = AppTheme(
    name: 'light',
    brightness: Brightness.light,
    colors: colorScheme,
    typography: typography,
  );
}

/// Default dark theme
@immutable
class DefaultDarkTheme {
  const DefaultDarkTheme._();

  static const AppColorScheme colorScheme = AppColorScheme(
    // Primary brand
    primary: Color(0xFF60A5FA), // Blue-400
    primaryContainer: Color(0xFF1E3A8A),
    onPrimary: Color(0xFF000000),

    // Secondary / accent
    secondary: Color(0xFFA78BFA), // Violet-400
    secondaryContainer: Color(0xFF5B21B6),
    onSecondary: Color(0xFF000000),

    // Surfaces
    surface: Color(0xFF1F2937),
    surfaceVariant: Color(0xFF374151),
    onSurface: Color(0xFFE5E7EB),
    onSurfaceVariant: Color(0xFF9CA3AF),

    // Background
    background: Color(0xFF111827),
    onBackground: Color(0xFFE5E7EB),

    // Error
    error: Color(0xFFF87171), // Red-400
    errorContainer: Color(0xFF7F1D1D),
    onError: Color(0xFF000000),

    // Success
    success: Color(0xFF4ADE80), // Green-400
    successContainer: Color(0xFF14532D),
    onSuccess: Color(0xFF000000),

    // Warning
    warning: Color(0xFFFB923C), // Orange-400
    warningContainer: Color(0xFF7C2D12),
    onWarning: Color(0xFF000000),

    // Borders / outline
    outline: Color(0xFF4B5563),
    outlineVariant: Color(0xFF374151),

    // Overlays
    shadow: Color(0x66000000),
    scrim: Color(0xCC000000),
  );

  /// Dark uses the same type scale as light to avoid layout shifts.
  static const AppTypography typography = DefaultLightTheme.typography;

  static const AppTheme theme = AppTheme(
    name: 'dark',
    brightness: Brightness.dark,
    colors: colorScheme,
    typography: typography,
  );
}

/// AMOLED pure-black dark theme
@immutable
class MidnightAmoledTheme {
  const MidnightAmoledTheme._();

  static const AppColorScheme colorScheme = AppColorScheme(
    primary: Color(0xFF60A5FA),
    primaryContainer: Color(0xFF0B1120),
    onPrimary: Color(0xFF020617),

    secondary: Color(0xFF38BDF8),
    secondaryContainer: Color(0xFF082F49),
    onSecondary: Color(0xFF020617),

    surface: Color(0xFF000000), // pure black
    surfaceVariant: Color(0xFF020617),
    onSurface: Color(0xFFE5E7EB),
    onSurfaceVariant: Color(0xFF9CA3AF),

    background: Color(0xFF000000),
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
    outlineVariant: Color(0xFF111827),

    shadow: Color(0xCC000000),
    scrim: Color(0xE6000000),
  );

  static const AppTheme theme = AppTheme(
    name: 'amoled_dark',
    brightness: Brightness.dark,
    colors: colorScheme,
    typography: DefaultDarkTheme.typography,
  );
}

/// High contrast light theme (accessibility-focused)
@immutable
class HighContrastLightTheme {
  const HighContrastLightTheme._();

  static const AppColorScheme colorScheme = AppColorScheme(
    primary: Color(0xFF0000CC), // strong blue
    primaryContainer: Color(0xFFFFFFFF),
    onPrimary: Color(0xFFFFFFFF),

    secondary: Color(0xFFFFA800), // strong amber
    secondaryContainer: Color(0xFFFFFFFF),
    onSecondary: Color(0xFF000000),

    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF5F5F5),
    onSurface: Color(0xFF000000),
    onSurfaceVariant: Color(0xFF111111),

    background: Color(0xFFFFFFFF),
    onBackground: Color(0xFF000000),

    error: Color(0xFFB00020),
    errorContainer: Color(0xFFFFE1E1),
    onError: Color(0xFFFFFFFF),

    success: Color(0xFF006400),
    successContainer: Color(0xFFE0FFE0),
    onSuccess: Color(0xFF000000),

    warning: Color(0xFFB25900),
    warningContainer: Color(0xFFFFF3CD),
    onWarning: Color(0xFF000000),

    outline: Color(0xFF000000),
    outlineVariant: Color(0xFF444444),

    shadow: Color(0x55000000),
    scrim: Color(0x99000000),
  );

  static const AppTypography typography = DefaultLightTheme.typography;

  static const AppTheme theme = AppTheme(
    name: 'high_contrast_light',
    brightness: Brightness.light,
    colors: colorScheme,
    typography: typography,
  );
}

/// High contrast dark theme (accessibility-focused)
@immutable
class HighContrastDarkTheme {
  const HighContrastDarkTheme._();

  static const AppColorScheme colorScheme = AppColorScheme(
    primary: Color(0xFF93C5FD),
    primaryContainer: Color(0xFF1D4ED8),
    onPrimary: Color(0xFF000000),

    secondary: Color(0xFFFBBF24),
    secondaryContainer: Color(0xFF92400E),
    onSecondary: Color(0xFF000000),

    surface: Color(0xFF000000),
    surfaceVariant: Color(0xFF111111),
    onSurface: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xFFE5E5E5),

    background: Color(0xFF000000),
    onBackground: Color(0xFFFFFFFF),

    error: Color(0xFFFFB4AB),
    errorContainer: Color(0xFF93000A),
    onError: Color(0xFF000000),

    success: Color(0xFFB9F6CA),
    successContainer: Color(0xFF00C853),
    onSuccess: Color(0xFF000000),

    warning: Color(0xFFFFE57F),
    warningContainer: Color(0xFFF57F17),
    onWarning: Color(0xFF000000),

    outline: Color(0xFFFFFFFF),
    outlineVariant: Color(0xFFBDBDBD),

    shadow: Color(0xCC000000),
    scrim: Color(0xE6000000),
  );

  static const AppTypography typography = DefaultDarkTheme.typography;

  static const AppTheme theme = AppTheme(
    name: 'high_contrast_dark',
    brightness: Brightness.dark,
    colors: colorScheme,
    typography: typography,
  );
}

/// Warm sepia reading theme
@immutable
class SepiaTheme {
  const SepiaTheme._();

  static const AppColorScheme colorScheme = AppColorScheme(
    primary: Color(0xFF92400E),
    primaryContainer: Color(0xFFFBBF77),
    onPrimary: Color(0xFFFFFBEB),

    secondary: Color(0xFFB45309),
    secondaryContainer: Color(0xFFFCD9A8),
    onSecondary: Color(0xFF3F2A1C),

    surface: Color(0xFFF5E9D4),
    surfaceVariant: Color(0xFFEAD8C0),
    onSurface: Color(0xFF3F2A1C),
    onSurfaceVariant: Color(0xFF5C3B28),

    background: Color(0xFFF3E5D0),
    onBackground: Color(0xFF3F2A1C),

    error: Color(0xFFB91C1C),
    errorContainer: Color(0xFFFFE4E4),
    onError: Color(0xFF3F2A1C),

    success: Color(0xFF15803D),
    successContainer: Color(0xFFDCFCE7),
    onSuccess: Color(0xFF1F2933),

    warning: Color(0xFFB45309),
    warningContainer: Color(0xFFFDE68A),
    onWarning: Color(0xFF3F2A1C),

    outline: Color(0xFFD6BC8C),
    outlineVariant: Color(0xFFEAD7B0),

    shadow: Color(0x33000000),
    scrim: Color(0x55000000),
  );

  static const AppTypography typography = DefaultLightTheme.typography;

  static const AppTheme theme = AppTheme(
    name: 'sepia',
    brightness: Brightness.light,
    colors: colorScheme,
    typography: typography,
  );
}

@immutable
class BlueBrandTheme {
  const BlueBrandTheme._();

  static const AppColorScheme colorScheme = AppColorScheme(
    // Stronger blue brand
    primary: Color(0xFF1D4ED8),
    primaryContainer: Color(0xFFDBEAFE),
    onPrimary: Color(0xFFFFFFFF),

    secondary: Color(0xFF0EA5E9),
    secondaryContainer: Color(0xFFE0F2FE),
    onSecondary: Color(0xFF0B1120),

    // Copied from DefaultLightTheme (not referenced!)
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF9FAFB),
    onSurface: Color(0xFF111827),
    onSurfaceVariant: Color(0xFF6B7280),

    background: Color(0xFFFAFAFA),
    onBackground: Color(0xFF111827),

    error: Color(0xFFDC2626),
    errorContainer: Color(0xFFFEE2E2),
    onError: Color(0xFFFFFFFF),

    success: Color(0xFF16A34A),
    successContainer: Color(0xFFDCFCE7),
    onSuccess: Color(0xFFFFFFFF),

    warning: Color(0xFFEA580C),
    warningContainer: Color(0xFFFFEDD5),
    onWarning: Color(0xFFFFFFFF),

    outline: Color(0xFFD1D5DB),
    outlineVariant: Color(0xFFE5E7EB),

    shadow: Color(0x1A000000),
    scrim: Color(0x99000000),
  );

  static const AppTheme theme = AppTheme(
    name: 'blue',
    brightness: Brightness.light,
    colors: colorScheme,
    typography: DefaultLightTheme.typography,
  );
}
