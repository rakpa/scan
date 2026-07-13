import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App type ramp — Aptos when bundled, Inter as fallback elsewhere.
abstract final class AppTypography {
  static const _aptos = 'Aptos';

  static TextTheme textTheme(ColorScheme scheme) {
    final base = _baseTextTheme();
    final onSurface = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;

    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        color: onSurface,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: onSurface,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: onSurface,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: base.bodyLarge?.copyWith(height: 1.5, color: onSurface),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.5, color: muted),
      bodySmall: base.bodySmall?.copyWith(height: 1.45, color: muted),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: onSurface,
      ),
    );
  }

  static TextTheme _baseTextTheme() {
    try {
      return TextTheme(
        displaySmall: const TextStyle(fontFamily: _aptos, fontSize: 36),
        headlineMedium: const TextStyle(fontFamily: _aptos, fontSize: 28),
        headlineSmall: const TextStyle(fontFamily: _aptos, fontSize: 24),
        titleLarge: const TextStyle(fontFamily: _aptos, fontSize: 22),
        titleMedium: const TextStyle(fontFamily: _aptos, fontSize: 18),
        titleSmall: const TextStyle(fontFamily: _aptos, fontSize: 16),
        bodyLarge: const TextStyle(fontFamily: _aptos, fontSize: 17),
        bodyMedium: const TextStyle(fontFamily: _aptos, fontSize: 15),
        bodySmall: const TextStyle(fontFamily: _aptos, fontSize: 13),
        labelLarge: const TextStyle(fontFamily: _aptos, fontSize: 15),
      );
    } catch (_) {
      return GoogleFonts.interTextTheme();
    }
  }
}
