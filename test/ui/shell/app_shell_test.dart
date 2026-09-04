import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:worklog/domain/models/shell_destination.dart';
import 'package:worklog/ui/core/app.dart';
import 'package:worklog/ui/core/theme/app_tokens.dart';
import 'package:worklog/ui/shell/widgets/app_shell.dart';
import 'package:worklog/ui/statistics/widgets/statistics_screen.dart';

/// Finds a tab label inside the bottom bar, excluding identical AppBar titles.
Finder navLabel(String label) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
}

/// Current scroll offset of the list identified by [list].
double scrollOffset(WidgetTester tester, Finder list) {
  final ScrollableState scrollable = tester.state<ScrollableState>(
    find.descendant(of: list, matching: find.byType(Scrollable)),
  );

  return scrollable.position.pixels;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppShell', () {
    testWidgets('renders five tabs, each with an icon and a label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const WorklogApp());

      expect(find.byType(NavigationDestination), findsNWidgets(5));
      for (final ShellDestination destination in ShellDestination.values) {
        expect(navLabel(destination.label), findsOneWidget);
      }
    });

    testWidgets('tab labels are the Ukrainian copy, in the specified order', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const WorklogApp());

      final List<String> rendered = tester
          .widgetList<NavigationDestination>(find.byType(NavigationDestination))
          .map((NavigationDestination d) => d.label)
          .toList();

      expect(rendered, <String>[
        'Головна',
        'Тренування',
        'Статистика',
        'Досягнення',
        'Профіль',
      ]);
    });

    testWidgets('bottom bar is 56 logical pixels tall', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const WorklogApp());

      expect(
        tester.getSize(find.byType(NavigationBar)).height,
        AppSizes.bottomNavHeight,
      );
    });

    testWidgets('shell paints on the dark primary background', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const WorklogApp());

      final ThemeData theme = Theme.of(tester.element(find.byType(AppShell)));

      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.bgPrimary);
    });

    testWidgets('active tab is visually distinct from inactive tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const WorklogApp());
      final Finder bar = find.byType(NavigationBar);

      // Home starts active: filled icon for it, outlined for the rest.
      expect(
        find.descendant(of: bar, matching: find.byIcon(Icons.home)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bar, matching: find.byIcon(Icons.home_outlined)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: bar,
          matching: find.byIcon(Icons.fitness_center_outlined),
        ),
        findsOneWidget,
      );

      await tester.tap(navLabel('Тренування'));
      await tester.pumpAndSettle();

      // The distinction follows the selection.
      expect(
        find.descendant(of: bar, matching: find.byIcon(Icons.fitness_center)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bar, matching: find.byIcon(Icons.home_outlined)),
        findsOneWidget,
      );
    });

    testWidgets('tapping a tab selects it and shows that tab body', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const WorklogApp());

      await tester.tap(navLabel('Статистика'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        ShellDestination.statistics.index,
      );
      expect(find.byType(StatisticsScreen), findsOneWidget);
    });

    testWidgets('each tab keeps its scroll position across switches', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const WorklogApp());
      final Finder homeList = find.byKey(const PageStorageKey<String>('home'));

      await tester.drag(homeList, const Offset(0, -400));
      await tester.pumpAndSettle();
      final double scrolled = scrollOffset(tester, homeList);
      expect(scrolled, greaterThan(0));

      await tester.tap(navLabel('Тренування'));
      await tester.pumpAndSettle();
      await tester.tap(navLabel('Головна'));
      await tester.pumpAndSettle();

      expect(scrollOffset(tester, homeList), scrolled);
    });

    // 4.5" ~= 360x640, 6.7" ~= 430x932; 320x640 guards the narrow edge.
    for (final Size size in _AppShellSpec.supportedSizes) {
      testWidgets('renders without overflow at ${size.width}x${size.height}', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(const WorklogApp());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(AppShell), findsOneWidget);
        expect(
          tester.getSize(find.byType(NavigationBar)).height,
          AppSizes.bottomNavHeight,
        );
      });
    }
  });
}

/// Screen sizes WORLOG-001 pins down, kept in one place.
abstract final class _AppShellSpec {
  static const List<Size> supportedSizes = <Size>[
    Size(320, 640),
    Size(360, 640),
    Size(430, 932),
  ];
}
