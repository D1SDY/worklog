import 'package:flutter_test/flutter_test.dart';

import '../../../tool/ci/review_gate.dart';

RoleReview pass(String role) =>
    RoleReview(role: role, findings: const <Finding>[]);

RoleReview blocking(String role, {String category = 'code'}) => RoleReview(
  role: role,
  findings: <Finding>[
    Finding(
      severity: 'BLOCKER',
      category: category,
      file: 'lib/a.dart',
      line: 1,
      summary: 's',
      why: 'w',
    ),
  ],
);

void main() {
  group('currentIteration', () {
    test('is zero when no iteration label is present', () {
      expect(currentIteration(<String>['needs-fix']), 0);
    });

    test('reads the highest iteration label', () {
      expect(currentIteration(<String>['iteration-1', 'iteration-2']), 2);
    });

    test('ignores labels that merely start with the prefix', () {
      expect(currentIteration(<String>['iteration-cap-note']), 0);
    });
  });

  group('RoleReview.verdict', () {
    test('is PASS with no findings', () {
      expect(pass('ba').verdict, 'PASS');
    });

    test('is PASS when every finding is MINOR or NIT', () {
      final RoleReview review = RoleReview(
        role: 'ba',
        findings: <Finding>[
          Finding(
            severity: 'MINOR',
            category: 'code',
            file: 'a',
            line: 1,
            summary: 's',
            why: 'w',
          ),
          Finding(
            severity: 'NIT',
            category: 'code',
            file: 'a',
            line: 2,
            summary: 's',
            why: 'w',
          ),
        ],
      );

      expect(review.verdict, 'PASS');
    });

    test('is BLOCK on a MAJOR', () {
      final RoleReview review = RoleReview(
        role: 'qa',
        findings: <Finding>[
          Finding(
            severity: 'MAJOR',
            category: 'code',
            file: 'a',
            line: 1,
            summary: 's',
            why: 'w',
          ),
        ],
      );

      expect(review.verdict, 'BLOCK');
    });

    test('is BLOCK on a BLOCKER', () {
      expect(blocking('qa').verdict, 'BLOCK');
    });
  });

  group('parseReview', () {
    test('treats a missing file as an infrastructure blocker', () {
      final RoleReview review = parseReview('qa', null);

      expect(review.verdict, 'BLOCK');
      expect(review.findings.single.category, 'infrastructure');
    });

    test('treats unparseable JSON as an infrastructure blocker', () {
      final RoleReview review = parseReview('qa', 'not json');

      expect(review.verdict, 'BLOCK');
      expect(review.findings.single.category, 'infrastructure');
    });

    test('reads findings from a well-formed file', () {
      const String json =
          '{"role":"ba","verdict":"BLOCK","findings":'
          '[{"severity":"BLOCKER","category":"code","file":"lib/a.dart",'
          '"line":7,"summary":"s","why":"w"}]}';

      final RoleReview review = parseReview('ba', json);

      expect(review.findings.single.line, 7);
      expect(review.verdict, 'BLOCK');
    });
  });

  group('decide', () {
    test('approves when all three reviewers pass', () {
      final GateDecision decision = decide(
        reviews: <RoleReview>[pass('ba'), pass('qa'), pass('design')],
        iteration: 0,
      );

      expect(decision.approved, isTrue);
      expect(decision.runAutofix, isFalse);
      expect(decision.labelsToAdd, contains('ready-for-approval'));
      expect(decision.labelsToRemove, contains('needs-fix'));
    });

    test('runs autofix and advances the iteration on a code block', () {
      final GateDecision decision = decide(
        reviews: <RoleReview>[pass('ba'), blocking('qa'), pass('design')],
        iteration: 0,
      );

      expect(decision.approved, isFalse);
      expect(decision.runAutofix, isTrue);
      expect(decision.nextIteration, 1);
      expect(
        decision.labelsToAdd,
        containsAll(<String>['needs-fix', 'iteration-1']),
      );
    });

    test('stops without autofix once the cap is reached', () {
      final GateDecision decision = decide(
        reviews: <RoleReview>[pass('ba'), blocking('qa'), pass('design')],
        iteration: 3,
      );

      expect(decision.capReached, isTrue);
      expect(decision.runAutofix, isFalse);
      expect(decision.labelsToAdd, contains('review-cap-reached'));
    });

    test('an infrastructure block skips autofix', () {
      final GateDecision decision = decide(
        reviews: <RoleReview>[
          blocking('ba', category: 'infrastructure'),
          pass('qa'),
          pass('design'),
        ],
        iteration: 0,
      );

      expect(decision.infrastructureBlocked, isTrue);
      expect(decision.runAutofix, isFalse);
      expect(decision.labelsToAdd, contains('review-blocked'));
    });

    test('an infrastructure block does not consume an iteration', () {
      final GateDecision decision = decide(
        reviews: <RoleReview>[
          blocking('ba', category: 'infrastructure'),
          pass('qa'),
          pass('design'),
        ],
        iteration: 2,
      );

      expect(decision.nextIteration, 2);
      expect(decision.labelsToAdd, isNot(contains('iteration-3')));
    });

    test('infrastructure wins when both kinds of block are present', () {
      final GateDecision decision = decide(
        reviews: <RoleReview>[
          blocking('ba', category: 'infrastructure'),
          blocking('qa'),
          pass('design'),
        ],
        iteration: 0,
      );

      expect(decision.infrastructureBlocked, isTrue);
      expect(decision.runAutofix, isFalse);
    });

    test('a crashed reviewer never reads as a pass', () {
      final GateDecision decision = decide(
        reviews: <RoleReview>[
          pass('ba'),
          parseReview('qa', null),
          pass('design'),
        ],
        iteration: 0,
      );

      expect(decision.approved, isFalse);
      expect(decision.infrastructureBlocked, isTrue);
    });

    test('clears stale verdict labels on every decision', () {
      final GateDecision decision = decide(
        reviews: <RoleReview>[pass('ba'), pass('qa'), pass('design')],
        iteration: 1,
      );

      expect(
        decision.labelsToRemove,
        containsAll(<String>['needs-fix', 'review-blocked']),
      );
    });
  });
}
