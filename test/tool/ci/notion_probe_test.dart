import 'dart:convert';
import 'dart:io';

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

  group('notionUrlFor', () {
    test('builds the pages endpoint for a page', () {
      expect(
        notionUrlFor(kind: 'page', id: 'abc123'),
        'https://api.notion.com/v1/pages/abc123',
      );
    });

    test('builds the databases endpoint for a database', () {
      expect(
        notionUrlFor(kind: 'database', id: 'abc123'),
        'https://api.notion.com/v1/databases/abc123',
      );
    });

    test('throws ArgumentError for an unrecognised kind', () {
      expect(
        () => notionUrlFor(kind: 'block', id: 'abc123'),
        throwsArgumentError,
      );
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

  group('probeFailureReason', () {
    test('reports a missing token', () {
      final String reason = probeFailureReason(
        tokenEmpty: true,
        kind: 'page',
        id: 'page-1',
      );

      expect(reason, contains('NOTION_TOKEN'));
    });

    test(
      'reports the status code for a 401 without claiming an empty token',
      () {
        final String reason = probeFailureReason(
          tokenEmpty: false,
          kind: 'page',
          id: 'page-1',
          statusCode: 401,
        );

        expect(reason, contains('401'));
        expect(reason, isNot(contains('empty')));
      },
    );

    test('reports the status code and page id for a 404', () {
      final String reason = probeFailureReason(
        tokenEmpty: false,
        kind: 'page',
        id: 'page-1',
        statusCode: 404,
      );

      expect(reason, contains('404'));
      expect(reason, contains('page-1'));
    });

    test('carries a thrown exception through', () {
      final String reason = probeFailureReason(
        tokenEmpty: false,
        kind: 'page',
        id: 'page-1',
        thrown: const SocketException('Connection refused'),
      );

      expect(reason, contains('Connection refused'));
    });

    test('falls back to a neutral message when nothing was recorded', () {
      final String reason = probeFailureReason(
        tokenEmpty: false,
        kind: 'page',
        id: 'page-1',
      );

      expect(reason, 'Notion request did not succeed');
    });

    test('names which resource failed so a database and a page 404 differ', () {
      final String databaseReason = probeFailureReason(
        tokenEmpty: false,
        kind: 'database',
        id: 'same-id',
        statusCode: 404,
      );
      final String pageReason = probeFailureReason(
        tokenEmpty: false,
        kind: 'page',
        id: 'same-id',
        statusCode: 404,
      );

      expect(databaseReason, isNot(equals(pageReason)));
      expect(databaseReason, contains('database'));
      expect(pageReason, contains('page'));
    });
  });
}
