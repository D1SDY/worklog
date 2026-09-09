import 'dart:convert';
import 'dart:io';

/// Delays between the initial attempt and each retry.
const List<Duration> defaultBackoff = <Duration>[
  Duration(seconds: 5),
  Duration(seconds: 20),
  Duration(seconds: 60),
];

/// Runs [attempt] once, then retries once per entry in [backoff], sleeping the
/// corresponding delay first. Returns true on the first success.
Future<bool> probeWithRetry({
  required Future<bool> Function() attempt,
  required Future<void> Function(Duration) sleep,
  List<Duration> backoff = defaultBackoff,
}) async {
  for (int i = 0; i <= backoff.length; i++) {
    if (i > 0) {
      await sleep(backoff[i - 1]);
    }
    try {
      if (await attempt()) {
        return true;
      }
    } on Object {
      continue;
    }
  }
  return false;
}

/// A verdict file recording that [role] could not reach [target].
String blockedVerdictJson({
  required String role,
  required String target,
  required String error,
}) {
  final Map<String, Object> verdict = <String, Object>{
    'role': role,
    'verdict': 'BLOCK',
    'findings': <Map<String, Object>>[
      <String, Object>{
        'severity': 'BLOCKER',
        'category': 'infrastructure',
        'file': '.github/mcp/$role.json',
        'line': 0,
        'summary': 'Could not reach $target in Notion',
        'why':
            'The review was not run. Reviewing without the acceptance '
            'criteria or the UI rules would report success for the wrong '
            'reason. Underlying error: $error',
      },
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(verdict);
}

/// Explains why the probe failed, from what was actually observed.
///
/// Exactly one of [statusCode] or [thrown] is expected to be set by a caller
/// that got as far as making a request; [tokenEmpty] takes precedence since
/// no request was even attempted in that case. When none of the three is
/// set, the message stays neutral rather than repeating a stale guess.
String probeFailureReason({
  required bool tokenEmpty,
  required String pageId,
  int? statusCode,
  Object? thrown,
}) {
  if (tokenEmpty) {
    return 'NOTION_TOKEN is empty';
  }
  if (statusCode != null) {
    return 'Notion API returned HTTP $statusCode for page $pageId';
  }
  if (thrown != null) {
    return thrown.toString();
  }
  return 'Notion request did not succeed';
}

Future<int> _fetchStatusCode(String pageId, String token) async {
  final HttpClient client = HttpClient();
  try {
    final HttpClientRequest request = await client.getUrl(
      Uri.parse('https://api.notion.com/v1/pages/$pageId'),
    );
    request.headers
      ..set('Authorization', 'Bearer $token')
      ..set('Notion-Version', '2022-06-28');
    final HttpClientResponse response = await request.close();
    await response.drain<void>();
    return response.statusCode;
  } finally {
    client.close(force: true);
  }
}

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln('usage: notion_probe.dart <role> <page-id> <review-dir>');
    exit(2);
  }

  final String role = args[0];
  final String pageId = args[1];
  final Directory reviewDir = Directory(args[2])..createSync(recursive: true);
  final String token = Platform.environment['NOTION_TOKEN'] ?? '';

  String lastError = probeFailureReason(
    tokenEmpty: token.isEmpty,
    pageId: pageId,
  );
  final bool ok = token.isEmpty
      ? false
      : await probeWithRetry(
          attempt: () async {
            try {
              final int statusCode = await _fetchStatusCode(pageId, token);
              if (statusCode == 200) {
                return true;
              }
              lastError = probeFailureReason(
                tokenEmpty: false,
                pageId: pageId,
                statusCode: statusCode,
              );
              return false;
            } on Object catch (error) {
              lastError = probeFailureReason(
                tokenEmpty: false,
                pageId: pageId,
                thrown: error,
              );
              rethrow;
            }
          },
          sleep: (Duration d) => Future<void>.delayed(d),
        );

  if (!ok) {
    File('${reviewDir.path}/$role.json').writeAsStringSync(
      blockedVerdictJson(role: role, target: 'page $pageId', error: lastError),
    );
    stderr.writeln('Notion unreachable after 4 attempts: $lastError');
  }

  final String? outputPath = Platform.environment['GITHUB_OUTPUT'];
  if (outputPath != null) {
    File(outputPath).writeAsStringSync('ok=$ok\n', mode: FileMode.append);
  }
  stdout.writeln('ok=$ok');
}
