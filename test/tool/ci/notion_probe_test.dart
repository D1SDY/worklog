import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/ci/notion_probe.dart';

void main() {
  group('probeWithRetry', () {
    test(
      'returns true without sleeping when the first attempt succeeds',
      () async {
        final List<Duration> slept = <Duration>[];

        final bool ok = await probeWithRetry(
          attempt: () async => true,
          sleep: (Duration d) async => slept.add(d),
        );

        expect(ok, isTrue);
        expect(slept, isEmpty);
      },
    );

    test('retries and succeeds on the third attempt', () async {
      int calls = 0;
      final List<Duration> slept = <Duration>[];

      final bool ok = await probeWithRetry(
        attempt: () async {
          calls += 1;
          return calls == 3;
        },
        sleep: (Duration d) async => slept.add(d),
      );

      expect(ok, isTrue);
      expect(calls, 3);
      expect(slept, <Duration>[Duration(seconds: 5), Duration(seconds: 20)]);
    });

    test('gives up after four attempts and three sleeps', () async {
      int calls = 0;
      final List<Duration> slept = <Duration>[];

      final bool ok = await probeWithRetry(
        attempt: () async {
          calls += 1;
          return false;
        },
        sleep: (Duration d) async => slept.add(d),
      );

      expect(ok, isFalse);
      expect(calls, 4);
      expect(slept, <Duration>[
        Duration(seconds: 5),
        Duration(seconds: 20),
        Duration(seconds: 60),
      ]);
    });

    test('treats a thrown attempt as a failed attempt', () async {
      int calls = 0;

      final bool ok = await probeWithRetry(
        attempt: () async {
          calls += 1;
          throw StateError('boom');
        },
        sleep: (Duration d) async {},
      );

      expect(ok, isFalse);
      expect(calls, 4);
    });
  });

  group('blockedVerdictJson', () {
    test('produces a parseable infrastructure blocker', () {
      final String json = blockedVerdictJson(
        role: 'ba',
        target: 'story page',
        error: '401 unauthorized',
      );
      final Map<String, dynamic> decoded =
          jsonDecode(json) as Map<String, dynamic>;
      final List<dynamic> findings = decoded['findings'] as List<dynamic>;
      final Map<String, dynamic> finding =
          findings.single as Map<String, dynamic>;

      expect(decoded['role'], 'ba');
      expect(decoded['verdict'], 'BLOCK');
      expect(finding['severity'], 'BLOCKER');
      expect(finding['category'], 'infrastructure');
      expect(finding['why'], contains('401 unauthorized'));
    });
  });
}
