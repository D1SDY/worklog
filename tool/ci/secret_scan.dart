/// Scans agent-authored text for credential-shaped strings before it is
/// published, as a chokepoint every such file passes through — not a
/// verdict that a file is safe.
///
/// This is defence in depth, not a proof of safety. It does **not** catch:
/// - base64- or URL-encoded tokens, since the literal prefix bytes are gone
/// - tokens split by a space rather than a line break
/// - any credential shape not in [secretPatterns]
library;

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
    pattern: RegExp('sk-ant-oat[A-Za-z0-9_-]{10,}', caseSensitive: false),
  ),
  SecretPattern(
    name: 'anthropic-api-key',
    pattern: RegExp('sk-ant-[A-Za-z0-9_-]{20,}', caseSensitive: false),
  ),
  SecretPattern(
    name: 'notion-token',
    pattern: RegExp('(?:ntn_|secret_)[A-Za-z0-9]{30,}', caseSensitive: false),
  ),
  SecretPattern(
    name: 'github-token',
    pattern: RegExp(
      '(?:ghp_|gho_|ghs_|ghu_|github_pat_)[A-Za-z0-9_]{20,}',
      caseSensitive: false,
    ),
  ),
  SecretPattern(
    name: 'env-dump',
    pattern: RegExp(r'^[A-Z][A-Z0-9_]{3,}=.+$', multiLine: true),
  ),
  SecretPattern(
    name: 'private-key-header',
    pattern: RegExp('-----BEGIN.*?PRIVATE KEY-----', caseSensitive: false),
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

/// Runs every entry in [secretPatterns] over [text] and returns the accepted
/// matches, sorted by position, with an earlier-listed (more specific)
/// pattern winning whenever two patterns match the same span.
List<_Match> _findMatches(String text) {
  final List<_Match> candidates = <_Match>[];
  for (int priority = 0; priority < secretPatterns.length; priority++) {
    final SecretPattern secretPattern = secretPatterns[priority];
    for (final RegExpMatch match in secretPattern.pattern.allMatches(text)) {
      candidates.add(
        _Match(
          patternName: secretPattern.name,
          start: match.start,
          end: match.end,
          priority: priority,
        ),
      );
    }
  }

  candidates.sort((_Match a, _Match b) {
    final int startCompare = a.start.compareTo(b.start);
    return startCompare != 0 ? startCompare : a.priority.compareTo(b.priority);
  });

  final List<_Match> accepted = <_Match>[];
  int claimedUntil = -1;
  for (final _Match match in candidates) {
    if (match.start < claimedUntil) {
      continue;
    }
    claimedUntil = match.end;
    accepted.add(match);
  }
  return accepted;
}

typedef _StrippedCopy = ({String text, List<int> originalOffsets});

/// Returns [content] with every `\r\n` and `\n` removed, alongside a map
/// from each character of the result back to its offset in [content].
///
/// Only line-break sequences are removed. An ordinary space is left alone,
/// so two words that were separated by a space rather than wrapped across a
/// line are never joined into a false positive.
_StrippedCopy _stripLineBreaks(String content) {
  final StringBuffer buffer = StringBuffer();
  final List<int> originalOffsets = <int>[];
  int i = 0;
  while (i < content.length) {
    if (content.startsWith('\r\n', i)) {
      i += 2;
      continue;
    }
    if (content[i] == '\n') {
      i += 1;
      continue;
    }
    buffer.write(content[i]);
    originalOffsets.add(i);
    i += 1;
  }
  return (text: buffer.toString(), originalOffsets: originalOffsets);
}

/// Finds every credential-shaped string in [content], checking every entry
/// in [secretPatterns] against [content] as given and again against a copy
/// with line breaks removed, so a token wrapped by an editor or renderer is
/// still caught.
///
/// When two patterns match at the same position, only the more specific one
/// (earlier in [secretPatterns]) is reported. A hit found only in the
/// line-break-stripped copy is reported at the line where its match begins
/// in [content]; a stripped-copy match that maps back to a span already
/// reported from [content] as given is not reported twice.
List<SecretHit> scanForSecrets(String content) {
  final List<_Match> rawMatches = _findMatches(content);
  final List<SecretHit> hits = <SecretHit>[
    for (final _Match match in rawMatches) _toHit(content, match),
  ];

  final _StrippedCopy stripped = _stripLineBreaks(content);
  for (final _Match match in _findMatches(stripped.text)) {
    final int originalStart = stripped.originalOffsets[match.start];
    final bool alreadyReported = rawMatches.any(
      (_Match raw) => originalStart >= raw.start && originalStart < raw.end,
    );
    if (alreadyReported) {
      continue;
    }
    hits.add(
      SecretHit(
        patternName: match.patternName,
        line: _lineNumber(content, originalStart),
        excerpt: _excerpt(stripped.text, match),
      ),
    );
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

    String content;
    try {
      content = file.readAsStringSync();
    } on Object catch (error) {
      stderr.writeln('$path: could not be read as text (${error.runtimeType})');
      exit(2);
    }

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
