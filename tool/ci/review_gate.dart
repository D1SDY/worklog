import 'dart:convert';
import 'dart:io';

/// Severities that block the gate.
const List<String> blockingSeverities = <String>['BLOCKER', 'MAJOR'];

/// The roles that must each produce a verdict file.
const List<String> reviewRoles = <String>['ba', 'qa', 'design'];

/// A single review finding.
class Finding {
  const Finding({
    required this.severity,
    required this.category,
    required this.file,
    required this.line,
    required this.summary,
    required this.why,
  });

  factory Finding.fromJson(Map<String, dynamic> json) => Finding(
    severity: json['severity'] as String? ?? 'BLOCKER',
    category: json['category'] as String? ?? 'code',
    file: json['file'] as String? ?? '',
    line: json['line'] as int? ?? 0,
    summary: json['summary'] as String? ?? '',
    why: json['why'] as String? ?? '',
  );

  final String severity;
  final String category;
  final String file;
  final int line;
  final String summary;
  final String why;

  bool get blocks => blockingSeverities.contains(severity);

  bool get isInfrastructure => category == 'infrastructure';
}

/// One reviewer's verdict.
class RoleReview {
  const RoleReview({required this.role, required this.findings});

  final String role;
  final List<Finding> findings;

  String get verdict =>
      findings.any((Finding f) => f.blocks) ? 'BLOCK' : 'PASS';

  bool get blocksOnInfrastructure =>
      findings.any((Finding f) => f.blocks && f.isInfrastructure);
}

/// What the gate job should do.
class GateDecision {
  const GateDecision({
    required this.approved,
    required this.infrastructureBlocked,
    required this.capReached,
    required this.runAutofix,
    required this.nextIteration,
    required this.labelsToAdd,
    required this.labelsToRemove,
    required this.summary,
  });

  final bool approved;
  final bool infrastructureBlocked;
  final bool capReached;
  final bool runAutofix;
  final int nextIteration;
  final List<String> labelsToAdd;
  final List<String> labelsToRemove;
  final String summary;
}

/// The highest `iteration-N` label already on the PR, or 0.
int currentIteration(List<String> labels) {
  int highest = 0;
  for (final String label in labels) {
    final RegExpMatch? match = RegExp(r'^iteration-(\d+)$')
        .firstMatch(label.trim());
    if (match != null) {
      final int value = int.parse(match.group(1)!);
      if (value > highest) {
        highest = value;
      }
    }
  }
  return highest;
}

/// Reads one reviewer's verdict file. A missing or unparseable file is an
/// infrastructure blocker — a crashed reviewer must never read as a pass.
RoleReview parseReview(String role, String? contents) {
  Finding unreadable(String reason) => Finding(
    severity: 'BLOCKER',
    category: 'infrastructure',
    file: '.review/$role.json',
    line: 0,
    summary: 'No usable verdict from the $role reviewer',
    why: reason,
  );

  if (contents == null || contents.trim().isEmpty) {
    return RoleReview(
      role: role,
      findings: <Finding>[unreadable('The verdict file is missing or empty.')],
    );
  }

  try {
    final Map<String, dynamic> json =
        jsonDecode(contents) as Map<String, dynamic>;
    final List<dynamic> raw = json['findings'] as List<dynamic>? ?? <dynamic>[];
    return RoleReview(
      role: role,
      findings: raw
          .map((dynamic e) => Finding.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  } on Object catch (error) {
    return RoleReview(
      role: role,
      findings: <Finding>[
        unreadable('The verdict file could not be parsed: $error'),
      ],
    );
  }
}

/// Aggregates the three reviews into a gate decision.
GateDecision decide({
  required List<RoleReview> reviews,
  required int iteration,
  int maxIterations = 3,
}) {
  const List<String> stale = <String>[
    'needs-fix',
    'ready-for-approval',
    'review-blocked',
    'review-cap-reached',
  ];

  final bool infrastructure = reviews.any(
    (RoleReview r) => r.blocksOnInfrastructure,
  );
  final bool blocked = reviews.any((RoleReview r) => r.verdict == 'BLOCK');

  if (infrastructure) {
    return GateDecision(
      approved: false,
      infrastructureBlocked: true,
      capReached: false,
      runAutofix: false,
      nextIteration: iteration,
      labelsToAdd: const <String>['review-blocked'],
      labelsToRemove: stale,
      summary:
          'Blocked on infrastructure. The dev agent cannot fix this; '
          'a human needs to repair the environment and re-run.',
    );
  }

  if (!blocked) {
    return GateDecision(
      approved: true,
      infrastructureBlocked: false,
      capReached: false,
      runAutofix: false,
      nextIteration: iteration,
      labelsToAdd: const <String>['ready-for-approval'],
      labelsToRemove: stale,
      summary: 'All three reviewers passed. Awaiting human approval.',
    );
  }

  if (iteration >= maxIterations) {
    return GateDecision(
      approved: false,
      infrastructureBlocked: false,
      capReached: true,
      runAutofix: false,
      nextIteration: iteration,
      labelsToAdd: const <String>['review-cap-reached'],
      labelsToRemove: stale,
      summary:
          'Reached $maxIterations review iterations with findings '
          'outstanding. Stopping for human arbitration.',
    );
  }

  final int next = iteration + 1;
  return GateDecision(
    approved: false,
    infrastructureBlocked: false,
    capReached: false,
    runAutofix: true,
    nextIteration: next,
    labelsToAdd: <String>['needs-fix', 'iteration-$next'],
    labelsToRemove: stale,
    summary:
        'Blocking findings outstanding. Starting fix iteration $next '
        'of $maxIterations.',
  );
}

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln(
      'usage: review_gate.dart <review-dir> <comma-separated-labels>',
    );
    exit(2);
  }

  final Directory dir = Directory(args[0]);
  final List<String> labels = args[1]
      .split(',')
      .where((String l) => l.trim().isNotEmpty)
      .toList();

  final List<RoleReview> reviews = reviewRoles.map((String role) {
    final File file = File('${dir.path}/$role.json');
    return parseReview(
      role,
      file.existsSync() ? file.readAsStringSync() : null,
    );
  }).toList();

  final GateDecision decision = decide(
    reviews: reviews,
    iteration: currentIteration(labels),
  );

  final StringBuffer out = StringBuffer()
    ..writeln('approved=${decision.approved}')
    ..writeln('run_autofix=${decision.runAutofix}')
    ..writeln('labels_to_add=${decision.labelsToAdd.join(',')}')
    ..writeln('labels_to_remove=${decision.labelsToRemove.join(',')}')
    ..writeln('summary=${decision.summary.replaceAll('\n', ' ')}');

  stdout.write(out.toString());

  for (final RoleReview review in reviews) {
    stderr.writeln(
      '${review.role}: ${review.verdict} '
      '(${review.findings.length} findings)',
    );
  }
}
