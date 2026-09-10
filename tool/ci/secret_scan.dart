import 'dart:io';

/// A named shape that identifies one kind of credential-shaped string.
///
/// Patterns never compare against real secret values; they match by shape
/// alone, so the scanner works with no secret in its own environment.
class SecretPattern {
  const SecretPattern({required this.name, required this.pattern});

  final String name;
  final RegExp pattern;
}

/// One place in a scanned file where a credential-shaped string was found.
///
/// [excerpt] never contains the matched text. A scanner that echoes the
/// secret it caught into a public CI log recreates the problem it exists to
/// prevent.
class SecretHit {
  const SecretHit({
    required this.patternName,
    required this.line,
    required this.excerpt,
  });

  final String patternName;
  final int line;
  final String excerpt;
}

class _Match {
  const _Match({
    required this.patternName,
    required this.start,
    required this.end,
    required this.priority,
  });

  final String patternName;
  final int start;
  final int end;
  final int priority;
}

/// Patterns checked in specificity order. When two patterns match at the
/// same starting position, the one listed first wins and is reported under
/// its own name.
final List<SecretPattern> secretPatterns = <SecretPattern>[
  SecretPattern(
    name: 'anthropic-oauth-token',
    pattern: RegExp('sk-ant-oat[A-Za-z0-9_-]{10,}'),
  ),
  SecretPattern(
    name: 'anthropic-api-key',
    pattern: RegExp('sk-ant-[A-Za-z0-9_-]{20,}'),
  ),
  SecretPattern(
    name: 'notion-token',
    pattern: RegExp('(?:ntn_|secret_)[A-Za-z0-9]{30,}'),
  ),
  SecretPattern(
    name: 'github-token',
    pattern: RegExp('(?:ghp_|gho_|ghs_|ghu_|github_pat_)[A-Za-z0-9_]{20,}'),
  ),
  SecretPattern(
    name: 'env-dump',
    pattern: RegExp(r'^[A-Z][A-Z0-9_]{3,}=.+$', multiLine: true),
  ),
  SecretPattern(
    name: 'private-key-header',
    pattern: RegExp('-----BEGIN.*?PRIVATE KEY-----'),
  ),
];

int _lineStart(String content, int offset) {
  if (offset == 0) {
    return 0;
  }
  final int newlineIndex = content.lastIndexOf('\n', offset - 1);
  return newlineIndex == -1 ? 0 : newlineIndex + 1;
}

int _lineNumber(String content, int offset) {
  int line = 1;
  for (int i = 0; i < offset; i++) {
    if (content[i] == '\n') {
      line++;
    }
  }
  return line;
}

String _excerpt(String content, _Match match) {
  final int lineStart = _lineStart(content, match.start);
  final String leading = content.substring(lineStart, match.start);
  final String context = leading.length <= 12
      ? leading
      : leading.substring(leading.length - 12);
  return '$context[redacted]';
}

SecretHit _toHit(String content, _Match match) => SecretHit(
  patternName: match.patternName,
  line: _lineNumber(content, match.start),
  excerpt: _excerpt(content, match),
);

/// Finds every credential-shaped string in [content], checking every entry
/// in [secretPatterns].
///
/// When two patterns match at the same position, only the more specific one
/// (earlier in [secretPatterns]) is reported.
List<SecretHit> scanForSecrets(String content) {
  final List<_Match> matches = <_Match>[];
  for (int priority = 0; priority < secretPatterns.length; priority++) {
    final SecretPattern secretPattern = secretPatterns[priority];
    for (final RegExpMatch match in secretPattern.pattern.allMatches(content)) {
      matches.add(
        _Match(
          patternName: secretPattern.name,
          start: match.start,
          end: match.end,
          priority: priority,
        ),
      );
    }
  }

  matches.sort((_Match a, _Match b) {
    final int startCompare = a.start.compareTo(b.start);
    return startCompare != 0 ? startCompare : a.priority.compareTo(b.priority);
  });

  final List<SecretHit> hits = <SecretHit>[];
  int claimedUntil = -1;
  for (final _Match match in matches) {
    if (match.start < claimedUntil) {
      continue;
    }
    claimedUntil = match.end;
    hits.add(_toHit(content, match));
  }
  return hits;
}

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: secret_scan.dart <file>...');
    exit(2);
  }

  bool foundAny = false;
  for (final String path in args) {
    final File file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('no such file: $path');
      exit(2);
    }

    final String content = file.readAsStringSync();
    for (final SecretHit hit in scanForSecrets(content)) {
      foundAny = true;
      stderr.writeln('$path:${hit.line}: ${hit.patternName} ${hit.excerpt}');
    }
  }

  if (foundAny) {
    stderr.writeln('FAIL: credential-shaped content found');
    exit(1);
  }

  stdout.writeln('secret_scan: clean');
}
