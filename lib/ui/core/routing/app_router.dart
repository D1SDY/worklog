import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/shell_destination.dart';
import '../../achievements/widgets/achievements_screen.dart';
import '../../home/widgets/home_screen.dart';
import '../../profile/widgets/profile_screen.dart';
import '../../shell/widgets/app_shell.dart';
import '../../statistics/widgets/statistics_screen.dart';
import '../../training/widgets/training_screen.dart';
import '../widgets/not_found_screen.dart';

/// The app's route table.
///
/// WORLOG-001 asks for "routing between [the tabs]", and states that
/// "everything else in the backlog plugs into this shell". Both are why this is
/// a [StatefulShellRoute.indexedStack] rather than a plain index in a
/// `setState`:
///
/// * every tab is addressable (`/training`), so later stories can deep-link
///   into one and the browser/system back button behaves;
/// * each branch owns a [Navigator], so a story can push a detail screen inside
///   its tab — `/training/exercise/42` — with the bottom bar still on screen;
/// * branches keep their state while inactive, which is what satisfies the
///   "preserves each tab's scroll position" criterion.
abstract final class AppRouter {
  /// Builds a router. Call once per app instance — a [GoRouter] owns
  /// navigation state, so tests build their own rather than sharing a global.
  ///
  /// [initialLocation] defaults to the Головна tab; tests and deep links pass
  /// another route to start elsewhere.
  static GoRouter create({String? initialLocation}) {
    return GoRouter(
      initialLocation: initialLocation ?? ShellDestination.home.path,
      routes: <RouteBase>[
        StatefulShellRoute.indexedStack(
          builder:
              (
                BuildContext context,
                GoRouterState state,
                StatefulNavigationShell navigationShell,
              ) {
                return AppShell(navigationShell: navigationShell);
              },
          branches: <StatefulShellBranch>[
            for (final ShellDestination destination in ShellDestination.values)
              StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: destination.path,
                    name: destination.name,
                    builder: (BuildContext context, GoRouterState state) =>
                        _screenFor(destination),
                  ),
                ],
              ),
          ],
        ),
      ],
      errorBuilder: (BuildContext context, GoRouterState state) =>
          const NotFoundScreen(),
    );
  }

  /// Tab bodies. Each is a placeholder until its own story lands; the mapping
  /// stays exhaustive, so adding a destination is a compile error until its
  /// screen exists.
  static Widget _screenFor(ShellDestination destination) {
    return switch (destination) {
      ShellDestination.home => const HomeScreen(),
      ShellDestination.training => const TrainingScreen(),
      ShellDestination.statistics => const StatisticsScreen(),
      ShellDestination.achievements => const AchievementsScreen(),
      ShellDestination.profile => const ProfileScreen(),
    };
  }
}
