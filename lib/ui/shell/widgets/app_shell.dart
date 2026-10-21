import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_bottom_nav_bar.dart';

/// The persistent navigation shell: a bottom tab bar over five top-level tabs.
///
/// The tab bodies are [navigationShell] itself — an indexed stack of one
/// [Navigator] per branch, built by [AppRouter]. Keeping the branches alive
/// off-screen is what preserves each tab's scroll position; rebuilding a body
/// on every switch would reset it and break WORLOG-001's third criterion.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  /// Branch state and the active index, supplied by the router.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      // Re-tapping the active tab pops back to its root, the platform
      // convention. Switching to another tab resumes where it was left.
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
