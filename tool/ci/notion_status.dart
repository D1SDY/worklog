import 'dart:convert';
import 'dart:io';

import 'notion_probe.dart';

/// Sprint Backlog statuses, in workflow order.
const List<String> storyStatuses = <String>[
  'Backlog',
  'To Do',
  'In Progress',
  'In Test',
  'Delivered',
  'Deployed',
];

/// The story ID a branch belongs to, or null if it is not a story branch.
///
/// Story branches are named `story/<ID>-<slug>`, e.g.
/// `story/WORLOG-001-app-navigation-shell` → `WORLOG-001`.
String? storyIdFromBranch(String branch) {
  final RegExpMatch? match = RegExp(r'^story/([A-Z]+-\d+)(?:-|$)')
      .firstMatch(branch);
  return match?.group(1);
}

/// Whether a story at [current] should move to [target].
///
/// Only forward moves are made: a merge must never drag a story that is
/// already further along (e.g. `Deployed`) back to `Delivered`. An unknown
/// [current] (empty, or renamed in Notion) is treated as behind [target].
/// An unknown [target] throws [ArgumentError] rather than silently guessing.
bool shouldAdvance({required String? current, required String target}) {
  final int to = storyStatuses.indexOf(target);
  if (to < 0) {
    throw ArgumentError.value(target, 'target', 'not a Sprint Backlog status');
  }
  return storyStatuses.indexOf(current ?? '') < to;
}

/// Body of a database query matching the page whose `Story ID` is [storyId].
Map<String, Object> storyQueryBody(String storyId) {
  return <String, Object>{
    'filter': <String, Object>{
      'property': 'Story ID',
      'rich_text': <String, String>{'equals': storyId},
    },
    'page_size': 2,
  };
}

/// Body of a page update setting `Status` to [status].
///
/// [propertyType] is the property's Notion type as read from the page —
/// `status` or `select` — since the two take differently shaped values.
Map<String, Object> statusPatchBody({
  required String propertyType,
  required String status,
}) {
  if (propertyType != 'status' && propertyType != 'select') {
    throw ArgumentError.value(
      propertyType,
      'propertyType',
      'must be "status" or "select"',
    );
  }
  return <String, Object>{
    'properties': <String, Object>{
      'Status': <String, Object>{
        propertyType: <String, String>{'name': status},
      },
    },
  };
}

/// The `Status` property's type and current value on a fetched [page].
({String type, String? name}) readStatus(Map<String, dynamic> page) {
  final Map<String, dynamic> properties =
      page['properties'] as Map<String, dynamic>;
  final Map<String, dynamic> status =
      properties['Status'] as Map<String, dynamic>;
  final String type = status['type'] as String;
  final Map<String, dynamic>? value = status[type] as Map<String, dynamic>?;
  return (type: type, name: value?['name'] as String?);
}

Future<Map<String, dynamic>> _send(
  String method,
  String url,
  String token,
  Map<String, Object> body,
) async {
  final HttpClient client = HttpClient();
  try {
    final HttpClientRequest request = await client.openUrl(
      method,
      Uri.parse(url),
    );
    request.headers
      ..set('Authorization', 'Bearer $token')
      ..set('Notion-Version', '2022-06-28')
      ..contentType = ContentType.json;
    request.write(jsonEncode(body));
    final HttpClientResponse response = await request.close();
    final String text = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw HttpException(
        'Notion API returned HTTP ${response.statusCode} for $method $url: '
        '$text',
      );
    }
    return jsonDecode(text) as Map<String, dynamic>;
  } finally {
    client.close(force: true);
  }
}

/// Retries [call] with [defaultBackoff], rethrowing the last error.
Future<T> _withRetry<T>(Future<T> Function() call) async {
  late T result;
  Object? lastError;
  final bool ok = await probeWithRetry(
    attempt: () async {
      try {
        result = await call();
        return true;
      } on Object catch (error) {
        lastError = error;
        rethrow;
      }
    },
    sleep: (Duration d) => Future<void>.delayed(d),
  );
  if (!ok) {
    throw lastError ?? StateError('Notion request did not succeed');
  }
  return result;
}

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln('usage: notion_status.dart <branch> <target-status>');
    exit(2);
  }

  final String branch = args[0];
  final String target = args[1];
  if (!storyStatuses.contains(target)) {
    stderr.writeln(
      'usage: notion_status.dart <branch> <target-status>: '
      'target must be one of ${storyStatuses.join(', ')}, got "$target"',
    );
    exit(2);
  }

  final String? storyId = storyIdFromBranch(branch);
  if (storyId == null) {
    stdout.writeln('$branch is not a story branch; nothing to update');
    return;
  }

  final String token = Platform.environment['NOTION_TOKEN'] ?? '';
  final String databaseId = Platform.environment['NOTION_SPRINT_DB_ID'] ?? '';
  if (token.isEmpty || databaseId.isEmpty) {
    stderr.writeln('NOTION_TOKEN and NOTION_SPRINT_DB_ID must both be set');
    exit(1);
  }

  final Map<String, dynamic> query = await _withRetry(
    () => _send(
      'POST',
      'https://api.notion.com/v1/databases/$databaseId/query',
      token,
      storyQueryBody(storyId),
    ),
  );
  final List<dynamic> results = query['results'] as List<dynamic>;
  if (results.length != 1) {
    stderr.writeln(
      'Expected exactly one Sprint Backlog page with Story ID $storyId, '
      'found ${results.length}',
    );
    exit(1);
  }

  final Map<String, dynamic> page = results.single as Map<String, dynamic>;
  final ({String type, String? name}) status = readStatus(page);
  if (!shouldAdvance(current: status.name, target: target)) {
    stdout.writeln('$storyId is already ${status.name}; not moving to $target');
    return;
  }

  await _withRetry(
    () => _send(
      'PATCH',
      'https://api.notion.com/v1/pages/${page['id']}',
      token,
      statusPatchBody(propertyType: status.type, status: target),
    ),
  );
  stdout.writeln('$storyId: ${status.name ?? '(none)'} → $target');
}
