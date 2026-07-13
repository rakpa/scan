import 'package:flutter/material.dart';

import 'home_design_tokens.dart';

/// Aptos-based text styles for the premium home UI — slightly larger than
/// default Material sizes so labels do not feel cramped.
abstract final class HomeTypography {
  static const family = 'Aptos';

  static const appTitle = TextStyle(
        fontFamily: family,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: HomeDesign.primary,
        letterSpacing: -0.2,
        height: 1.2,
      );

  static const sectionTitle = TextStyle(
        fontFamily: family,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: HomeDesign.onSurface,
        letterSpacing: -0.2,
        height: 1.25,
      );

  static const body = TextStyle(
        fontFamily: family,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: HomeDesign.onSurface,
        height: 1.4,
      );

  static const bodyMuted = TextStyle(
        fontFamily: family,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: HomeDesign.muted,
        height: 1.4,
      );

  static const label = TextStyle(
        fontFamily: family,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: HomeDesign.onSurface,
        height: 1.2,
      );

  static const caption = TextStyle(
        fontFamily: family,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: HomeDesign.muted,
        height: 1.2,
      );

  static const navLabel = TextStyle(
        fontFamily: family,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.1,
      );

  static const quickActionTitle = TextStyle(
        fontFamily: family,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: HomeDesign.onSurface,
        letterSpacing: -0.1,
        height: 1.2,
      );

  static const quickActionSubtitle = TextStyle(
        fontFamily: family,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: HomeDesign.muted,
        height: 1.35,
      );
}
