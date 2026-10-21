import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/domain/models/shell_destination.dart';
import 'package:worklog/ui/core/icons/lucide_svg.dart';
import 'package:worklog/ui/core/icons/tab_icon.dart';

/// Each tab's expected glyph and the path data that identifies it. A wrong or
/// redrawn glyph fails here.
const Map<ShellDestination, ({String lucide, String svg, List<String> paths})>
_spec = <ShellDestination, ({String lucide, String svg, List<String> paths})>{
  ShellDestination.home: (
    lucide: 'house',
    svg: LucideSvg.house,
    paths: <String>[
      'M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8',
      'M3 10a2 2 0 0 1 .709-1.528l7-6a2 2 0 0 1 2.582 0l7 6A2 2 0 0 1 '
          '21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z',
    ],
  ),
  ShellDestination.training: (
    lucide: 'barbell (design, horizontal)',
    svg: LucideSvg.barbell,
    paths: <String>[
      '<line x1="7" y1="12" x2="17" y2="12"/>',
      '<line x1="7" y1="8" x2="7" y2="16"/>',
      '<line x1="17" y1="8" x2="17" y2="16"/>',
      '<line x1="4.5" y1="9.5" x2="4.5" y2="14.5"/>',
      '<line x1="19.5" y1="9.5" x2="19.5" y2="14.5"/>',
      '<line x1="2" y1="12" x2="4.5" y2="12"/>',
      '<line x1="19.5" y1="12" x2="22" y2="12"/>',
    ],
  ),
  ShellDestination.statistics: (
    lucide: 'bar chart on a baseline (design)',
    svg: LucideSvg.barChart,
    paths: <String>[
      '<line x1="3" y1="20" x2="21" y2="20"/>',
      '<line x1="7" y1="20" x2="7" y2="12"/>',
      '<line x1="12" y1="20" x2="12" y2="5"/>',
      '<line x1="17" y1="20" x2="17" y2="14"/>',
    ],
  ),
  ShellDestination.achievements: (
    lucide: 'two concentric rings (design)',
    svg: LucideSvg.rings,
    paths: <String>[
      '<circle cx="12" cy="12" r="9"/>',
      '<circle cx="12" cy="12" r="4"/>',
    ],
  ),
  ShellDestination.profile: (
    lucide: 'user',
    svg: LucideSvg.user,
    paths: <String>[
      'M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2',
      '<circle cx="12" cy="7" r="4"/>',
    ],
  ),
};

/// Every SVG the app ships, tab icons and the rest.
const List<String> _all = <String>[
  LucideSvg.house,
  LucideSvg.barbell,
  LucideSvg.barChart,
  LucideSvg.rings,
  LucideSvg.user,
  LucideSvg.searchX,
];

void main() {
  group('LucideSvg', () {
    test('covers every destination', () {
      expect(_spec.keys, unorderedEquals(ShellDestination.values));
    });

    for (final ShellDestination destination in ShellDestination.values) {
      final ({String lucide, String svg, List<String> paths}) want =
          _spec[destination]!;

      test('${destination.label} is `${want.lucide}`', () {
        expect(destination.lucideSvg, want.svg);
        for (final String path in want.paths) {
          expect(destination.lucideSvg, contains(path));
        }
      });
    }

    test('every tab has a distinct glyph', () {
      final Set<String> svgs = ShellDestination.values
          .map((ShellDestination d) => d.lucideSvg)
          .toSet();

      expect(svgs, hasLength(ShellDestination.values.length));
    });

    test('rings are exactly two circles, with no centre dot', () {
      expect('<circle'.allMatches(LucideSvg.rings), hasLength(2));
    });

    test('all icons are 1.5px round-capped outlines on a 24 viewBox', () {
      expect(LucideSvg.strokeWidth, '1.5');
      for (final String svg in _all) {
        expect(svg, contains('stroke-width="1.5"'));
        expect(svg, contains('fill="none"'));
        expect(svg, contains('stroke-linecap="round"'));
        expect(svg, contains('stroke-linejoin="round"'));
        expect(svg, contains('viewBox="0 0 24 24"'));
        expect(svg, isNot(contains(RegExp(r'stroke-width="(?!1\.5")'))));
      }
    });

    for (final String svg in _all) {
      testWidgets('parses and paints: ${svg.hashCode}', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          Center(
            child: LucideSvgIcon(
              svg: svg,
              size: 24,
              color: const Color(0xFF000000),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(LucideSvgIcon)),
          const Size.square(24),
        );
      });
    }
  });
}
