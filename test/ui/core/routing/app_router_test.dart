import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:worklog/domain/models/shell_destination.dart';
import 'package:worklog/ui/core/app.dart';
import 'package:worklog/ui/core/routing/app_router.dart';
import 'package:worklog/ui/core/widgets/not_found_screen.dart';
import 'package:worklog/ui/home/widgets/home_screen.dart';
import 'package:worklog/ui/shell/widgets/app_shell.dart';
import 'package:worklog/ui/statistics/widgets/statistics_screen.dart';
import 'package:worklog/ui/training/widgets/training_screen.dart';

/// The location the router currently shows.
String locationOf(GoRouter router) {
  return router.routerDelegate.currentConfiguration.uri.toString();
}

/// Finds a tab label inside the bottom bar, excluding identical AppBar titles.
Finder navLabel(String label) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppRouter', () {
    testWidgets('starts on the Головна tab', (WidgetTester tester) async {
      final GoRouter router = AppRouter.create();
      await tester.pumpWidget(WorklogApp(router: router));

      expect(locationOf(router), ShellDestination.home.path);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('every tab has its own address', (WidgetTester tester) async {
      final GoRouter router = AppRouter.create();
      await tester.pumpWidget(WorklogApp(router: router));

      for (final ShellDestination destination in ShellDestination.values) {
        await tester.tap(navLabel(destination.label));
        await tester.pumpAndSettle();

        expect(locationOf(router), destination.path);
      }
    });

    testWidgets('a deep link opens inside the shell, on the right tab', (
      WidgetTester tester,
    ) async {
      final GoRouter router = AppRouter.create(
        initialLocation: ShellDestination.statistics.path,
      );
      await tester.pumpWidget(WorklogApp(router: router));
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(StatisticsScreen), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        ShellDestination.statistics.index,
      );
    });

    testWidgets('navigating by route updates the selected tab', (
      WidgetTester tester,
    ) async {
      final GoRouter router = AppRouter.create();
      await tester.pumpWidget(WorklogApp(router: router));

      router.go(ShellDestination.training.path);
      await tester.pumpAndSettle();

      expect(find.byType(TrainingScreen), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        ShellDestination.training.index,
      );
    });

    testWidgets('each branch keeps its own navigator', (
      WidgetTester tester,
    ) async {
      // One Navigator per branch is what lets a later story push a detail
      // screen inside a tab with the bottom bar still on screen.
      final GoRouter router = AppRouter.create();
      await tester.pumpWidget(WorklogApp(router: router));

      await tester.tap(navLabel(ShellDestination.training.label));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppShell),
          matching: find.byType(Navigator),
        ),
        findsWidgets,
      );
    });

    testWidgets('an unknown route shows the not-found screen', (
      WidgetTester tester,
    ) async {
      final GoRouter router = AppRouter.create(initialLocation: '/nope');
      await tester.pumpWidget(WorklogApp(router: router));
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(find.text('Сторінку не знайдено'), findsOneWidget);
    });

    testWidgets('the not-found screen links back into the shell', (
      WidgetTester tester,
    ) async {
      final GoRouter router = AppRouter.create(initialLocation: '/nope');
      await tester.pumpWidget(WorklogApp(router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('На головну'));
      await tester.pumpAndSettle();

      expect(locationOf(router), ShellDestination.home.path);
      expect(find.byType(AppShell), findsOneWidget);
    });
  });
}
