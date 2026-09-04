import 'package:flutter/material.dart';

/// A top-level destination in the app's bottom navigation shell.
///
/// Declaration order is the tab order in the bar, fixed by
/// 📐 UI Component Rules → Bottom Navigation Bar.
///
/// Labels are Ukrainian: that page defines the app's UI copy. The English names
/// in the WORLOG-001 description identify the tabs for the reader; they are not
/// the strings shown to users.
///
/// Icons follow the rules page's Lucide mapping, resolved to their nearest
/// Material equivalents so the app keeps using the bundled icon font rather
/// than taking a dependency for five glyphs. The page permits a different
/// library "as long as the 5-icon mapping and outline/filled pairing stay the
/// same", which is what [icon]/[selectedIcon] preserve.
enum ShellDestination {
  /// Lucide `home`.
  home(
    path: '/home',
    label: 'Головна',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),

  /// Lucide `dumbbell`.
  training(
    path: '/training',
    label: 'Тренування',
    icon: Icons.fitness_center_outlined,
    selectedIcon: Icons.fitness_center,
  ),

  /// Lucide `bar-chart-2`.
  statistics(
    path: '/statistics',
    label: 'Статистика',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
  ),

  /// Lucide `trophy`.
  achievements(
    path: '/achievements',
    label: 'Досягнення',
    icon: Icons.emoji_events_outlined,
    selectedIcon: Icons.emoji_events,
  ),

  /// Lucide `circle-user` — the rounded frame is part of the spec, so this is
  /// `account_circle` rather than the frameless `person`.
  profile(
    path: '/profile',
    label: 'Профіль',
    icon: Icons.account_circle_outlined,
    selectedIcon: Icons.account_circle,
  );

  const ShellDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  /// Route location of this tab's branch root.
  ///
  /// Later stories nest their screens under this path, so a tab's whole stack
  /// stays addressable — `/training/exercise/42` keeps the bar on Тренування.
  final String path;

  /// Text shown under the tab icon.
  final String label;

  /// Icon shown while the tab is inactive.
  final IconData icon;

  /// Icon shown while the tab is active.
  ///
  /// The rules page distinguishes the active tab by colour; the filled variant
  /// is an extra non-colour cue, so the distinction survives for users who
  /// cannot rely on hue alone.
  final IconData selectedIcon;
}
