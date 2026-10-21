import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:worklog/domain/models/shell_destination.dart';
import 'package:worklog/ui/core/icons/lucide_svg.dart';
import 'package:worklog/ui/core/icons/tab_icon.dart';
import 'package:worklog/ui/core/theme/app_theme.dart';
import 'package:worklog/ui/core/theme/app_tokens.dart';
import 'package:worklog/ui/shell/widgets/app_bottom_nav_bar.dart';

/// Finds the tab for [destination].
Finder navTab(ShellDestination destination) {
  return find.byKey(ValueKey<String>('nav-${destination.name}'));
}

/// Pumps the bar alone, themed as in the app, with [selected] active.
Future<void> pumpBar(
  WidgetTester tester, {
  ShellDestination selected = ShellDestination.home,
  ValueChanged<int>? onSelected,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        bottomNavigationBar: AppBottomNavBar(
          selectedIndex: selected.index,
          onDestinationSelected: onSelected ?? (int _) {},
        ),
      ),
    ),
  );
}

/// The label [Text] rendered inside [destination]'s tab.
Text labelOf(WidgetTester tester, ShellDestination destination) {
  return tester.widget<Text>(
    find.descendant(
      of: navTab(destination),
      matching: find.text(destination.label),
    ),
  );
}

/// Finds the SVG icon painted inside [destination]'s tab.
Finder iconFinder(ShellDestination destination) {
  return find.descendant(
    of: navTab(destination),
    matching: find.byType(LucideSvgIcon),
  );
}

/// The SVG icon painted inside [destination]'s tab.
LucideSvgIcon iconOf(WidgetTester tester, ShellDestination destination) {
  return tester.widget<LucideSvgIcon>(iconFinder(destination));
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppBottomNavBar', () {
    testWidgets('sits on the secondary surface', (WidgetTester tester) async {
      await pumpBar(tester);

      final Material surface = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(AppBottomNavBar),
              matching: find.byType(Material),
            )
            .first,
      );

      expect(surface.color, AppColors.bgSecondary);
    });

    testWidgets('is 68px tall, the Figma Tab bar height', (
      WidgetTester tester,
    ) async {
      await pumpBar(tester);

      expect(tester.getSize(find.byType(AppBottomNavBar)).height, 68);
      expect(AppSizes.bottomNavHeight, 68);
    });

    testWidgets('active tab is its outline SVG, tinted accent blue', (
      WidgetTester tester,
    ) async {
      await pumpBar(tester, selected: ShellDestination.statistics);

      final LucideSvgIcon icon = iconOf(tester, ShellDestination.statistics);
      expect(icon.svg, LucideSvg.barChart);
      expect(icon.size, AppSizes.navIcon);
      expect(icon.color, AppColors.accentBlue);
      expect(
        labelOf(tester, ShellDestination.statistics).style?.color,
        AppColors.accentBlue,
      );
    });

    testWidgets('inactive tabs are their outline SVGs, muted', (
      WidgetTester tester,
    ) async {
      await pumpBar(tester, selected: ShellDestination.statistics);

      const Map<ShellDestination, String> inactive = <ShellDestination, String>{
        ShellDestination.home: LucideSvg.house,
        ShellDestination.training: LucideSvg.barbell,
        ShellDestination.achievements: LucideSvg.rings,
        ShellDestination.profile: LucideSvg.user,
      };
      for (final MapEntry<ShellDestination, String>(
            key: ShellDestination destination,
            value: String svg,
          )
          in inactive.entries) {
        final LucideSvgIcon icon = iconOf(tester, destination);
        expect(icon.svg, svg);
        expect(icon.size, AppSizes.navIcon);
        expect(icon.color, AppColors.textMuted);
        expect(labelOf(tester, destination).style?.color, AppColors.textMuted);
      }
    });

    testWidgets('active and inactive share one SVG and differ only in colour', (
      WidgetTester tester,
    ) async {
      await pumpBar(tester, selected: ShellDestination.training);
      final LucideSvgIcon active = iconOf(tester, ShellDestination.training);

      await pumpBar(tester);
      final LucideSvgIcon inactive = iconOf(tester, ShellDestination.training);

      expect(active.svg, same(inactive.svg));
      expect(active.size, inactive.size);
      expect(active.color, isNot(inactive.color));
      expect(active.color, AppColors.accentBlue);
      expect(inactive.color, AppColors.textMuted);
    });

    testWidgets('icon is 24x24 and sits 4px above the label, in every tab', (
      WidgetTester tester,
    ) async {
      await pumpBar(tester);

      for (final ShellDestination destination in ShellDestination.values) {
        final Rect icon = tester.getRect(iconFinder(destination));
        final Rect label = tester.getRect(
          find.descendant(
            of: navTab(destination),
            matching: find.text(destination.label),
          ),
        );

        expect(icon.size, const Size.square(24));
        expect(label.top - icon.bottom, 4);
      }
    });

    testWidgets('labels are Inter regular 12/16, on one line', (
      WidgetTester tester,
    ) async {
      await pumpBar(tester);

      final Text label = labelOf(tester, ShellDestination.home);
      final TextStyle style = label.style!;

      expect(style.fontFamily, contains('Inter'));
      expect(style.fontSize, 12);
      expect(style.fontSize! * style.height!, closeTo(16, 0.001));
      expect(style.fontWeight, FontWeight.w400);
      expect(label.maxLines, 1);
      expect(
        tester
            .getSize(
              find.descendant(
                of: navTab(ShellDestination.home),
                matching: find.text(ShellDestination.home.label),
              ),
            )
            .height,
        lessThanOrEqualTo(16),
      );
    });

    testWidgets('tapping a tab reports its index, including the active one', (
      WidgetTester tester,
    ) async {
      final List<int> taps = <int>[];
      await pumpBar(tester, onSelected: taps.add);

      await tester.tap(navTab(ShellDestination.achievements));
      await tester.tap(navTab(ShellDestination.home));

      expect(taps, <int>[
        ShellDestination.achievements.index,
        ShellDestination.home.index,
      ]);
    });

    testWidgets('marks only the active tab as selected for accessibility', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpBar(tester, selected: ShellDestination.profile);

      expect(
        tester.getSemantics(navTab(ShellDestination.profile)),
        matchesSemantics(
          label: ShellDestination.profile.label,
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );
      expect(
        tester.getSemantics(navTab(ShellDestination.home)),
        matchesSemantics(
          label: ShellDestination.home.label,
          isButton: true,
          hasSelectedState: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );
      semantics.dispose();
    });

    test('text-scale cap is derived from the 68px bar geometry', () {
      // (68 - 2 * 4 margin - 24 icon - 4 gap) / 16 line height.
      expect(AppSizes.navLabelMaxTextScale, 2.0);
    });

    // The narrowest phone and landscape, at default and large accessibility
    // text, plus a scale above the cap: the worst cases for a fixed-height bar
    // with five Ukrainian labels.
    for (final Size size in const <Size>[Size(320, 640), Size(640, 360)]) {
      for (final double scale in <double>[1, 2, 3]) {
        testWidgets('every icon and label stays inside the bar at '
            '${size.width.toInt()}x${size.height.toInt()}, ${scale}x text', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          await pumpBar(tester);

          expect(tester.takeException(), isNull);
          final Rect bar = tester.getRect(find.byType(AppBottomNavBar));
          expect(bar.height, AppSizes.bottomNavHeight);
          for (final ShellDestination destination in ShellDestination.values) {
            final Rect tab = tester.getRect(navTab(destination));
            final Rect icon = tester.getRect(iconFinder(destination));
            final Rect label = tester.getRect(
              find.descendant(
                of: navTab(destination),
                matching: find.text(destination.label),
              ),
            );

            for (final Rect part in <Rect>[icon, label]) {
              expect(part.top, greaterThanOrEqualTo(bar.top));
              expect(part.bottom, lessThanOrEqualTo(bar.bottom));
              expect(part.left, greaterThanOrEqualTo(tab.left));
              expect(part.right, lessThanOrEqualTo(tab.right));
            }
          }
        });
      }
    }
  });

  group('TabIcon', () {
    testWidgets('paints its destination SVG at 24px by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const Center(
          child: TabIcon(
            destination: ShellDestination.profile,
            color: AppColors.textMuted,
          ),
        ),
      );

      final LucideSvgIcon icon = tester.widget<LucideSvgIcon>(
        find.byType(LucideSvgIcon),
      );
      expect(icon.svg, LucideSvg.user);
      expect(icon.size, 24);
      expect(tester.getSize(find.byType(TabIcon)), const Size.square(24));
    });
  });
}
