import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:worklog/domain/models/shell_destination.dart';
import 'package:worklog/ui/core/app.dart';
import 'package:worklog/ui/core/icons/tab_icon.dart';
import 'package:worklog/ui/core/theme/app_tokens.dart';
import 'package:worklog/ui/shell/widgets/app_bottom_nav_bar.dart';
import 'package:worklog/ui/shell/widgets/app_shell.dart';
import 'package:worklog/ui/statistics/widgets/statistics_screen.dart';

/// Finds a tab label inside the bottom bar, excluding identical AppBar titles.
Finder navLabel(String label) {
  return find.descendant(
    of: find.byType(AppBottomNavBar),
    matching: find.text(label),
  );
}

/// Finds the bottom-bar tab for [destination].
Finder navTab(ShellDestination destination) {
  return find.byKey(ValueKey<String>('nav-${destination.name}'));
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

      for (final ShellDestination destination in ShellDestination.values) {
        final Finder tab = navTab(destination);
        expect(tab, findsOneWidget);
        expect(
          find.descendant(of: tab, matching: find.byType(TabIcon)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: tab, matching: find.text(destination.label)),
          findsOneWidget,
        );
      }
    });

    testWidgets('each tab puts its icon above its label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const WorklogApp());

      for (final ShellDestination destination in ShellDestination.values) {
        final Finder tab = navTab(destination);
        final Rect icon = tester.getRect(
          find.descendant(of: tab, matching: find.byType(TabIcon)),
        );
        final Rect label = tester.getRect(
          find.descendant(of: tab, matching: find.text(destination.label)),
        );

        expect(icon.bottom, lessThanOrEqualTo(label.top));
        expect(icon.size, const Size.square(AppSizes.navIcon));
      }
    });

    testWidgets('tab labels are the Ukrainian copy, in the specified order', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const WorklogApp());

      // Read the labels left to right, as the user sees them.
      final List<ShellDestination> byPosition = ShellDestination.values.toList()
        ..sort(
          (ShellDestination a, ShellDestination b) => tester
              .getCenter(navTab(a))
              .dx
              .compareTo(tester.getCenter(navTab(b)).dx),
        );
      final List<String> rendered = byPosition
          .map((ShellDestination d) => d.label)
          .toList();

      expect(rendered, <String>[
        'Головна',
        'Тренування',
        'Статистика',
        'Досягнення',
        'Профіль',
      ]);
    });

    testWidgets('bottom bar is 68 logical pixels tall', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const WorklogApp());

      expect(
        tester.getSize(find.byType(AppBottomNavBar)).height,
        AppSizes.bottomNavHeight,
      );
      expect(AppSizes.bottomNavHeight, 68);
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
      final Finder bar = find.byType(AppBottomNavBar);

      // Same outline glyph in both states; the tint carries the selection.
      Color iconColor(ShellDestination destination) {
        return tester
            .widget<TabIcon>(
              find.descendant(
                of: bar,
                matching: find.byWidgetPredicate(
                  (Widget w) => w is TabIcon && w.destination == destination,
                ),
              ),
            )
            .color;
      }

      // Home starts active.
      expect(iconColor(ShellDestination.home), AppColors.accentBlue);
      expect(iconColor(ShellDestination.training), AppColors.textMuted);

      await tester.tap(navLabel('Тренування'));
      await tester.pumpAndSettle();

      // The distinction follows the selection.
      expect(iconColor(ShellDestination.training), AppColors.accentBlue);
      expect(iconColor(ShellDestination.home), AppColors.textMuted);
    });

    testWidgets('tapping a tab selects it and shows that tab body', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const WorklogApp());

      await tester.tap(navLabel('Статистика'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<AppBottomNavBar>(find.byType(AppBottomNavBar))
            .selectedIndex,
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

    // 4.5" ~= 360x640, 6.7" ~= 430x932; 320x640 guards the narrow edge. The
    // landscape pair covers rotation at both ends of the range.
    for (final Size size in _AppShellSpec.supportedSizes) {
      for (final double scale in <double>[1, 2]) {
        testWidgets('renders without overflow at '
            '${size.width}x${size.height}, ${scale}x text', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          await tester.pumpWidget(const WorklogApp());
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(AppShell), findsOneWidget);
          expect(
            tester.getSize(find.byType(AppBottomNavBar)).height,
            AppSizes.bottomNavHeight,
          );
        });
      }
    }

    testWidgets('survives a 2x system text scale at the narrowest width', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = _AppShellSpec.supportedSizes.first;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(const WorklogApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(AppBottomNavBar)).height,
        AppSizes.bottomNavHeight,
      );
      for (final ShellDestination destination in ShellDestination.values) {
        expect(navLabel(destination.label), findsOneWidget);
      }
    });

    testWidgets('keeps the bar clear of the bottom safe-area inset', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const WorklogApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The 68px bar sits above the home indicator; the inset is added
      // beneath it rather than squeezing the tabs.
      expect(
        tester.getSize(find.byType(AppBottomNavBar)).height,
        AppSizes.bottomNavHeight + 34,
      );
      expect(
        tester.getBottomLeft(navLabel(ShellDestination.home.label)).dy,
        lessThanOrEqualTo(932 - 34),
      );
    });

    testWidgets('scroll position survives a switch in landscape too', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(640, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const WorklogApp());
      final Finder homeList = find.byKey(const PageStorageKey<String>('home'));

      await tester.drag(homeList, const Offset(0, -200));
      await tester.pumpAndSettle();
      final double scrolled = scrollOffset(tester, homeList);
      expect(scrolled, greaterThan(0));

      await tester.tap(navLabel('Профіль'));
      await tester.pumpAndSettle();
      await tester.tap(navLabel('Головна'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(scrollOffset(tester, homeList), scrolled);
    });
  });
}

/// Screen sizes WORLOG-001 pins down, kept in one place.
abstract final class _AppShellSpec {
  static const List<Size> supportedSizes = <Size>[
    Size(320, 640),
    Size(360, 640),
    Size(430, 932),
    Size(640, 360),
    Size(932, 430),
  ];
}
