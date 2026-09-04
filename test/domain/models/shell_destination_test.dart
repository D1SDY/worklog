import 'package:flutter/material.dart';
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

    test('selected icon differs from the unselected icon', () {
      for (final ShellDestination destination in ShellDestination.values) {
        expect(
          destination.selectedIcon,
          isNot(destination.icon),
          reason: '${destination.name} would be indistinguishable when active',
        );
      }
    });

    test('icons keep the outline/filled pairing the rules page requires', () {
      // The Lucide mapping resolved to Material: home, dumbbell, bar-chart-2,
      // trophy, circle-user. Профіль is account_circle, not person — the rules
      // page asks for the rounded frame.
      expect(
        ShellDestination.values.map((ShellDestination d) => d.icon).toList(),
        <IconData>[
          Icons.home_outlined,
          Icons.fitness_center_outlined,
          Icons.bar_chart_outlined,
          Icons.emoji_events_outlined,
          Icons.account_circle_outlined,
        ],
      );
      expect(
        ShellDestination.values
            .map((ShellDestination d) => d.selectedIcon)
            .toList(),
        <IconData>[
          Icons.home,
          Icons.fitness_center,
          Icons.bar_chart,
          Icons.emoji_events,
          Icons.account_circle,
        ],
      );
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
