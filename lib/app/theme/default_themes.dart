import 'package:flutter/material.dart';

import '../../core/contracts/theme_contract.dart';

/// Default light theme
class DefaultLightTheme {
  static const colorScheme = AppColorScheme(
    primary: Color(0xFF2563EB),
    // Blue-600
    primaryContainer: Color(0xFFDCEAFB),
    onPrimary: Color(0xFFFFFFFF),

    secondary: Color(0xFF7C3AED),
    // Violet-600
    secondaryContainer: Color(0xFFEDE9FE),
    onSecondary: Color(0xFFFFFFFF),

    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF9FAFB),
    onSurface: Color(0xFF111827),
    onSurfaceVariant: Color(0xFF6B7280),

    background: Color(0xFFFAFAFA),
    onBackground: Color(0xFF111827),

    error: Color(0xFFDC2626),
    // Red-600
    errorContainer: Color(0xFFFEE2E2),
    onError: Color(0xFFFFFFFF),

    success: Color(0xFF16A34A),
    // Green-600
    successContainer: Color(0xFFDCFCE7),
    onSuccess: Color(0xFFFFFFFF),

    warning: Color(0xFFEA580C),
    // Orange-600
    warningContainer: Color(0xFFFFEDD5),
    onWarning: Color(0xFFFFFFFF),

    outline: Color(0xFFD1D5DB),
    outlineVariant: Color(0xFFE5E7EB),

    shadow: Color(0x1A000000),
    scrim: Color(0x99000000),
  );

  static const typography = AppTypography(
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

  static const theme = AppTheme(
    name: 'light',
    brightness: Brightness.light,
    colors: colorScheme,
    typography: typography,
  );
}

/// Default dark theme
class DefaultDarkTheme {
  static const colorScheme = AppColorScheme(
    primary: Color(0xFF60A5FA),
    // Blue-400
    primaryContainer: Color(0xFF1E3A8A),
    onPrimary: Color(0xFF000000),

    secondary: Color(0xFFA78BFA),
    // Violet-400
    secondaryContainer: Color(0xFF5B21B6),
    onSecondary: Color(0xFF000000),

    surface: Color(0xFF1F2937),
    surfaceVariant: Color(0xFF374151),
    onSurface: Color(0xFFE5E7EB),
    onSurfaceVariant: Color(0xFF9CA3AF),

    background: Color(0xFF111827),
    onBackground: Color(0xFFE5E7EB),

    error: Color(0xFFF87171),
    // Red-400
    errorContainer: Color(0xFF7F1D1D),
    onError: Color(0xFF000000),

    success: Color(0xFF4ADE80),
    // Green-400
    successContainer: Color(0xFF14532D),
    onSuccess: Color(0xFF000000),

    warning: Color(0xFFFB923C),
    // Orange-400
    warningContainer: Color(0xFF7C2D12),
    onWarning: Color(0xFF000000),

    outline: Color(0xFF4B5563),
    outlineVariant: Color(0xFF374151),

    shadow: Color(0x66000000),
    scrim: Color(0xCC000000),
  );

  static const theme = AppTheme(
    name: 'dark',
    brightness: Brightness.dark,
    colors: colorScheme,
    typography: DefaultLightTheme.typography, // Same typography
  );
}
