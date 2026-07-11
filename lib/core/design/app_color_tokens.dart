import 'package:flutter/material.dart';

/// Extra design tokens that don't fit Material's [ColorScheme] — flat brand
/// surfaces and semantic colors. No gradients: the design is solid dark-purple.
///
/// Exposed as a [ThemeExtension] so widgets read them via
/// `Theme.of(context).extension<AppTokens>()!`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.splashBackground,
    required this.scanSurface,
    required this.brandSoft,
    required this.onBrandSoft,
    required this.surfaceSunken,
    required this.textTertiary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.premium,
  });

  /// Solid dark-purple used on the splash + scan hero background.
  final Color splashBackground;
  final Color scanSurface;

  /// Light purple container fill + its on-color (chips, soft badges).
  final Color brandSoft;
  final Color onBrandSoft;

  /// A recessed surface (cards, wells).
  final Color surfaceSunken;

  /// Lowest-emphasis text (timestamps, captions).
  final Color textTertiary;

  final Color success;
  final Color warning;
  final Color danger;

  /// Highlight / "Pro" accent (amber).
  final Color premium;

  @override
  AppTokens copyWith({
    Color? splashBackground,
    Color? scanSurface,
    Color? brandSoft,
    Color? onBrandSoft,
    Color? surfaceSunken,
    Color? textTertiary,
    Color? success,
    Color? warning,
    Color? danger,
    Color? premium,
  }) {
    return AppTokens(
      splashBackground: splashBackground ?? this.splashBackground,
      scanSurface: scanSurface ?? this.scanSurface,
      brandSoft: brandSoft ?? this.brandSoft,
      onBrandSoft: onBrandSoft ?? this.onBrandSoft,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      textTertiary: textTertiary ?? this.textTertiary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      premium: premium ?? this.premium,
    );
  }

  @override
  AppTokens lerp(AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      splashBackground: Color.lerp(splashBackground, other.splashBackground, t)!,
      scanSurface: Color.lerp(scanSurface, other.scanSurface, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      onBrandSoft: Color.lerp(onBrandSoft, other.onBrandSoft, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      premium: Color.lerp(premium, other.premium, t)!,
    );
  }
}

/// Raw brand colour constants. The single source of truth — change these to
/// re-skin the whole app. Dark-purple, flat.
abstract final class BrandColors {
  static const Color purple = Color(0xFF5B21B6); // primary (dark purple)
  static const Color purpleBright = Color(0xFF6D28D9); // logo / accents
  static const Color purpleDeep = Color(0xFF2E1065); // splash / scan surface
  static const Color purpleSoft = Color(0xFFEDE9FE); // light container
  static const Color amber = Color(0xFFF59E0B);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
}

/// Light + dark [ColorScheme]s and matching [AppTokens].
abstract final class AppPalette {
  // ---- Light ----
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: BrandColors.purple,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: BrandColors.purpleSoft,
    onPrimaryContainer: Color(0xFF2E1065),
    secondary: BrandColors.purpleBright,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: BrandColors.purpleSoft,
    onSecondaryContainer: Color(0xFF2E1065),
    tertiary: BrandColors.amber,
    onTertiary: Color(0xFF3D2C00),
    error: BrandColors.danger,
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF18181B),
    surfaceContainerHighest: Color(0xFFF4F4F7),
    onSurfaceVariant: Color(0xFF52525B),
    outline: Color(0xFFD4D4D8),
    outlineVariant: Color(0xFFE7E7EC),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2A2533),
    onInverseSurface: Color(0xFFF4F4F7),
    inversePrimary: Color(0xFFC4B5FD),
  );

  static const AppTokens lightTokens = AppTokens(
    splashBackground: BrandColors.purpleDeep,
    scanSurface: BrandColors.purpleDeep,
    brandSoft: BrandColors.purpleSoft,
    onBrandSoft: Color(0xFF4C1D95),
    surfaceSunken: Color(0xFFF4F4F7),
    textTertiary: Color(0xFFA1A1AA),
    success: BrandColors.success,
    warning: BrandColors.warning,
    danger: BrandColors.danger,
    premium: BrandColors.amber,
  );

  // ---- Dark ----
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFA78BFA),
    onPrimary: Color(0xFF2E1065),
    primaryContainer: Color(0xFF4C1D95),
    onPrimaryContainer: Color(0xFFEDE9FE),
    secondary: Color(0xFFC4B5FD),
    onSecondary: Color(0xFF2E1065),
    secondaryContainer: Color(0xFF4C1D95),
    onSecondaryContainer: Color(0xFFEDE9FE),
    tertiary: BrandColors.amber,
    onTertiary: Color(0xFF3D2C00),
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF4A0A0A),
    surface: Color(0xFF0F0B1A),
    onSurface: Color(0xFFF4F4F7),
    surfaceContainerHighest: Color(0xFF1C1730),
    onSurfaceVariant: Color(0xFFA9A4B8),
    outline: Color(0xFF3F3A4D),
    outlineVariant: Color(0xFF272233),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF4F4F7),
    onInverseSurface: Color(0xFF2A2533),
    inversePrimary: BrandColors.purple,
  );

  static const AppTokens darkTokens = AppTokens(
    splashBackground: BrandColors.purpleDeep,
    scanSurface: Color(0xFF241848),
    brandSoft: Color(0xFF2A2140),
    onBrandSoft: Color(0xFFC4B5FD),
    surfaceSunken: Color(0xFF161122),
    textTertiary: Color(0xFF6B6878),
    success: BrandColors.success,
    warning: BrandColors.warning,
    danger: Color(0xFFFF6B6B),
    premium: Color(0xFFF5C451),
  );
}
