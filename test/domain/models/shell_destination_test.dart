import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/domain/models/shell_destination.dart';

void main() {
  group('ShellDestination', () {
    test('declares the five shell tabs in bar order', () {
      expect(ShellDestination.values, <ShellDestination>[
        ShellDestination.home,
        ShellDestination.training,
        ShellDestination.statistics,
        ShellDestination.achievements,
        ShellDestination.profile,
      ]);
    });

    test('labels are the Ukrainian copy from 📐 UI Component Rules', () {
      expect(
        ShellDestination.values.map((ShellDestination d) => d.label).toList(),
        <String>[
          'Головна',
          'Тренування',
          'Статистика',
          'Досягнення',
          'Профіль',
        ],
      );
    });

    test('every destination has a non-empty, unique label', () {
      final List<String> labels = ShellDestination.values
          .map((ShellDestination d) => d.label)
          .toList();

      expect(labels.any((String label) => label.trim().isEmpty), isFalse);
      expect(labels.toSet(), hasLength(labels.length));
    });

    test('every destination has a unique, rooted route path', () {
      final List<String> paths = ShellDestination.values
          .map((ShellDestination d) => d.path)
          .toList();

      expect(paths, <String>[
        '/home',
        '/training',
        '/statistics',
        '/achievements',
        '/profile',
      ]);
      expect(paths.toSet(), hasLength(paths.length));
      for (final String path in paths) {
        expect(
          path.startsWith('/'),
          isTrue,
          reason: 'branch roots must be absolute so tabs stay addressable',
        );
      }
    });
  });
}
