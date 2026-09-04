import 'package:flutter/material.dart';

/// Design tokens transcribed from 📐 UI Component Rules in Notion:
/// https://app.notion.com/p/3d15b5635132811aad56df8c1e6c53f0
///
/// This file is the single source of truth for the visual language. Widgets
/// must reference these values — a raw hex colour, spacing number or radius
/// written inline in a widget is a bug, not a shortcut.
abstract final class AppColors {
  /// App background, modal/sheet background.
  static const Color bgPrimary = Color(0xFF0F1419);

  /// Cards, inputs, unselected chips, secondary buttons — and the bottom nav.
  static const Color bgSecondary = Color(0xFF1A2332);

  /// Primary actions, selected states, links, chart lines.
  static const Color accentBlue = Color(0xFF2563EB);

  /// Success and favourable movement: save toasts, positive delta, PR check.
  static const Color accentGreen = Color(0xFF10B981);

  /// Gamification: streaks, PRs, achievement unlocks, tier progress.
  static const Color accentOrange = Color(0xFFF59E0B);

  /// Errors, validation and destructive actions ONLY.
  ///
  /// An unfavourable trend or delta uses [accentOrange], never this — unless it
  /// is tied to an actual error state.
  static const Color accentRed = Color(0xFFEF4444);

  /// Primary text and icons on dark surfaces.
  static const Color textPrimary = Color(0xFFF5F7FA);

  /// Opacity for secondary/meta text, section headers, placeholders, disabled
  /// controls and inactive nav tabs.
  static const double mutedOpacity = 0.6;

  /// [textPrimary] at [mutedOpacity]. `0x99` is 60% of 255, kept as a literal
  /// so the value stays usable in `const` contexts; a unit test pins the two
  /// representations together.
  static const Color textMuted = Color(0x99F5F7FA);
}

/// The 4px spacing scale. Padding, margin and gaps come from here — the rules
/// page forbids arbitrary values.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  /// Every permitted step, for tests that assert a value is on the scale.
  static const List<double> scale = <double>[xs, sm, md, lg, xl, xxl];
}

/// Corner radii. Avatars are circular ("50%") — use [BoxShape.circle] rather
/// than a radius value.
abstract final class AppRadius {
  static const double input = 8;
  static const double card = 12;
  static const double modal = 16;
}

/// Fixed component dimensions defined by the rules page.
abstract final class AppSizes {
  /// Bottom navigation bar height, per WORLOG-001 and the rules page.
  static const double bottomNavHeight = 56;

  /// Bottom navigation icon size — the rules page specifies 24×24px.
  static const double navIcon = 24;

  /// Minimum touch target for icon buttons.
  static const double minTouchTarget = 44;

  /// Empty-state icon. The rules page fixes the pattern (centred muted icon +
  /// short muted text) but not a size, so this is derived — twice [navIcon] —
  /// rather than picked arbitrarily.
  static const double emptyStateIcon = navIcon * 2;
}
