import 'package:flutter/material.dart';

import '../../core/contracts/theme_contract.dart';

/// Shared typography so layout doesn’t shift between themes.
@immutable
class LedgerTypography {
  const LedgerTypography._();

  static const AppTypography base = AppTypography(
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
}

/// Bright, cool, “air + glass” light theme.
@immutable
class AuroraLightTheme {
  const AuroraLightTheme._();

  static const AppColorScheme colorScheme = AppColorScheme(
    // Primary brand (cool blue)
    primary: Color(0xFF2563EB), // blue-600
    primaryContainer: Color(0xFFDBEAFE),
    onPrimary: Color(0xFFFFFFFF),

    // Secondary / accent (emerald)
    secondary: Color(0xFF10B981), // emerald-500
    secondaryContainer: Color(0xFFD1FAE5),
    onSecondary: Color(0xFF022C22),

    // Surfaces
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF3F4FF), // very light cool tint
    onSurface: Color(0xFF0F172A),
    onSurfaceVariant: Color(0xFF64748B),

    // Background
    background: Color(0xFFF4F6FB),
    onBackground: Color(0xFF020617),

    // Error
    error: Color(0xFFDC2626),
    errorContainer: Color(0xFFFEE2E2),
    onError: Color(0xFFFFFFFF),

    // Success
    success: Color(0xFF16A34A),
    successContainer: Color(0xFFDCFCE7),
    onSuccess: Color(0xFF052E16),

    // Warning
    warning: Color(0xFFEA580C),
    warningContainer: Color(0xFFFFEDD5),
    onWarning: Color(0xFF431407),

    // Borders / outline
    outline: Color(0xFFD1D5DB),
    outlineVariant: Color(0xFFE5E7EB),

    // Overlays
    shadow: Color(0x1A000000),
    scrim: Color(0x99000000),
  );

  static const AppTheme theme = AppTheme(
    name: 'aurora_light',
    brightness: Brightness.light,
    colors: colorScheme,
    typography: LedgerTypography.base,
  );
}

/// Neutral “finance dashboard at night” dark theme.
@immutable
class EmberDarkTheme {
  const EmberDarkTheme._();

  static const AppColorScheme colorScheme = AppColorScheme(
    // Warm primary
    primary: Color(0xFFF97316), // orange-400
    primaryContainer: Color(0xFF7C2D12),
    onPrimary: Color(0xFF000000),

    // Secondary (rose accent)
    secondary: Color(0xFFE11D48),
    secondaryContainer: Color(0xFF831843),
    onSecondary: Color(0xFFFFFFFF),

    // Surfaces (charcoal)
    surface: Color(0xFF111827),
    surfaceVariant: Color(0xFF1F2937),
    onSurface: Color(0xFFE5E7EB),
    onSurfaceVariant: Color(0xFF9CA3AF),

    // Background
    background: Color(0xFF020617),
    onBackground: Color(0xFFE5E7EB),

    // Error
    error: Color(0xFFF97373),
    errorContainer: Color(0xFF7F1D1D),
    onError: Color(0xFF000000),

    // Success
    success: Color(0xFF4ADE80),
    successContainer: Color(0xFF14532D),
    onSuccess: Color(0xFF000000),

    // Warning
    warning: Color(0xFFFBBF24),
    warningContainer: Color(0xFF78350F),
    onWarning: Color(0xFF000000),

    // Borders / outline
    outline: Color(0xFF4B5563),
    outlineVariant: Color(0xFF374151),

    // Overlays
    shadow: Color(0xCC000000),
    scrim: Color(0xE6000000),
  );

  static const AppTheme theme = AppTheme(
    name: 'ember_dark',
    brightness: Brightness.dark,
    colors: colorScheme,
    typography: LedgerTypography.base,
  );
}

/// OLED-friendly, pure black with neon accents.
@immutable
class VoidAmoledTheme {
  const VoidAmoledTheme._();

  static const AppColorScheme colorScheme = AppColorScheme(
    primary: Color(0xFF22D3EE), // cyan
    primaryContainer: Color(0xFF0F172A),
    onPrimary: Color(0xFF000000),

    secondary: Color(0xFFA855F7), // violet
    secondaryContainer: Color(0xFF1E1B4B),
    onSecondary: Color(0xFF000000),

    surface: Color(0xFF000000), // pure black
    surfaceVariant: Color(0xFF020617),
    onSurface: Color(0xFFE5E7EB),
    onSurfaceVariant: Color(0xFF9CA3AF),

    background: Color(0xFF000000),
    onBackground: Color(0xFFE5E7EB),

    error: Color(0xFFF97373),
    errorContainer: Color(0xFF7F1D1D),
    onError: Color(0xFF000000),

    success: Color(0xFF4ADE80),
    successContainer: Color(0xFF14532D),
    onSuccess: Color(0xFF000000),

    warning: Color(0xFFFBBF24),
    warningContainer: Color(0xFF854D0E),
    onWarning: Color(0xFF000000),

    outline: Color(0xFF4B5563),
    outlineVariant: Color(0xFF1F2937),

    shadow: Color(0xCC000000),
    scrim: Color(0xE6000000),
  );

  static const AppTheme theme = AppTheme(
    name: 'void_amoled',
    brightness: Brightness.dark,
    colors: colorScheme,
    typography: LedgerTypography.base,
  );
}

/// Ultra high-contrast light theme (accessibility-first).
@immutable
class NimbusHighContrastLightTheme {
  const NimbusHighContrastLightTheme._();

  static const AppColorScheme colorScheme = AppColorScheme(
    primary: Color(0xFF0033CC), // deep blue
    primaryContainer: Color(0xFFFFFFFF),
    onPrimary: Color(0xFFFFFFFF),

    secondary: Color(0xFFFF8C00), // strong amber
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

  static const AppTheme theme = AppTheme(
    name: 'nimbus_high_contrast_light',
    brightness: Brightness.light,
    colors: colorScheme,
    typography: LedgerTypography.base,
  );
}

/// Ultra high-contrast dark theme (accessibility-first).
@immutable
class DuskHighContrastDarkTheme {
  const DuskHighContrastDarkTheme._();

  static const AppColorScheme colorScheme = AppColorScheme(
    primary: Color(0xFF93C5FD), // light blue
    primaryContainer: Color(0xFF1D4ED8),
    onPrimary: Color(0xFF000000),

    secondary: Color(0xFFFDE68A), // strong yellow
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

  static const AppTheme theme = AppTheme(
    name: 'dusk_high_contrast_dark',
    brightness: Brightness.dark,
    colors: colorScheme,
    typography: LedgerTypography.base,
  );
}

/// Warm sepia reading / “paper ledger” theme.
@immutable
class ParchmentSepiaTheme {
  const ParchmentSepiaTheme._();

  static const AppColorScheme colorScheme = AppColorScheme(
    primary: Color(0xFF8B5A2B),
    primaryContainer: Color(0xFFF6D9A8),
    onPrimary: Color(0xFF3F2A1C),

    secondary: Color(0xFFB5651D),
    secondaryContainer: Color(0xFFFDE6B8),
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
    onSuccess: Color(0xFF10291A),

    warning: Color(0xFFB45309),
    warningContainer: Color(0xFFFDE68A),
    onWarning: Color(0xFF3F2A1C),

    outline: Color(0xFFD6BC8C),
    outlineVariant: Color(0xFFEAD7B0),

    shadow: Color(0x33000000),
    scrim: Color(0x55000000),
  );

  static const AppTheme theme = AppTheme(
    name: 'parchment_sepia',
    brightness: Brightness.light,
    colors: colorScheme,
    typography: LedgerTypography.base,
  );
}

/// Blue-heavy light theme with more saturated brand color.
@immutable
class MarinaBlueTheme {
  const MarinaBlueTheme._();

  static const AppColorScheme colorScheme = AppColorScheme(
    primary: Color(0xFF1D4ED8), // strong blue
    primaryContainer: Color(0xFFDBEAFE),
    onPrimary: Color(0xFFFFFFFF),

    secondary: Color(0xFF0EA5E9), // cyan accent
    secondaryContainer: Color(0xFFE0F2FE),
    onSecondary: Color(0xFF0B1120),

    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE5F0FF),
    onSurface: Color(0xFF020617),
    onSurfaceVariant: Color(0xFF475569),

    background: Color(0xFFF1F5FF),
    onBackground: Color(0xFF020617),

    error: Color(0xFFDC2626),
    errorContainer: Color(0xFFFEE2E2),
    onError: Color(0xFFFFFFFF),

    success: Color(0xFF16A34A),
    successContainer: Color(0xFFDCFCE7),
    onSuccess: Color(0xFF052E16),

    warning: Color(0xFFF97316),
    warningContainer: Color(0xFFFFE7D5),
    onWarning: Color(0xFF431407),

    outline: Color(0xFFCBD5F5),
    outlineVariant: Color(0xFFE5EDFF),

    shadow: Color(0x1A000000),
    scrim: Color(0x99000000),
  );

  static const AppTheme theme = AppTheme(
    name: 'marina_blue',
    brightness: Brightness.light,
    colors: colorScheme,
    typography: LedgerTypography.base,
  );
}
