import 'package:flutter/material.dart';

import '../../../domain/models/shell_destination.dart';
import '../../core/icons/tab_icon.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';

/// The bottom navigation bar from 📐 UI Component Rules → Bottom Navigation
/// Bar, with the Figma Tab bar's geometry: five fixed tabs,
/// [AppSizes.bottomNavHeight] tall, a 24px Lucide outline icon 4px above a
/// 12/16 label, the active tab in [AppColors.accentBlue] and inactive tabs
/// muted.
///
/// Built from tokens rather than Material 3's `NavigationBar`, whose layout
/// assumes an 80px bar with a 32px indicator slot, and whose `String` labels
/// cannot be held to one line, so the longer Ukrainian labels wrap on narrow
/// phones.
///
/// The bottom safe-area inset is added beneath the bar's row, so the tabs never
/// sit under a home indicator or gesture bar.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  /// Index into [ShellDestination.values] of the active tab.
  final int selectedIndex;

  /// Called with the tapped tab's index, including when it is already active.
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgSecondary,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSizes.bottomNavHeight,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: AppSizes.navLabelMaxTextScale,
            child: Row(
              children: <Widget>[
                for (final ShellDestination destination
                    in ShellDestination.values)
                  Expanded(
                    child: _NavItem(
                      key: ValueKey<String>('nav-${destination.name}'),
                      destination: destination,
                      selected: destination.index == selectedIndex,
                      onTap: () => onDestinationSelected(destination.index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One tab: icon above a single-line label, tinted by selection.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.accentBlue : AppColors.textMuted;
    final TextStyle labelStyle = AppTheme.navLabel().copyWith(color: color);

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Same outline glyph in both states; only the tint changes.
              TabIcon(destination: destination, color: color),
              const SizedBox(height: AppSpacing.xs),
              // One line, always: a label that does not fit the tab's width
              // shrinks rather than wrapping out of the fixed-height bar.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  destination.label,
                  maxLines: 1,
                  softWrap: false,
                  style: labelStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
