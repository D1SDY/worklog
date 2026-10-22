import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _origin = 'https://d1sdy.github.io';

String _inlineScripts(String path) {
  final String html = File(path).readAsStringSync();
  return RegExp(r'<script>([\s\S]*?)</script>')
      .allMatches(html)
      .map((RegExpMatch match) => match.group(1)!)
      .where((String script) => !script.contains('{{'))
      .join('\n');
}

String _bootstrapSource({String version = '123'}) {
  return File('web/flutter_bootstrap.js')
      .readAsStringSync()
      .replaceAll('{{flutter_js}}', '')
      .replaceAll('{{flutter_build_config}}', '')
      .replaceAll(
        '{{flutter_service_worker_version}}',
        '"$version" /* deprecated */',
      );
}

dynamic _node(String program) {
  final ProcessResult result;
  try {
    result = Process.runSync('node', <String>['-e', program]);
  } on ProcessException catch (error) {
    fail('test/web needs node on PATH to run the PWA scripts: $error');
  }
  if (result.exitCode != 0) {
    fail('node exited with ${result.exitCode}:\n${result.stderr}');
  }
  return jsonDecode(result.stdout as String);
}

dynamic _call(String scripts, String expression) {
  return _node('$scripts\nprocess.stdout.write(JSON.stringify($expression));');
}

Map<String, dynamic> _launch({
  String deployedVersion = '123',
  String lastAttempt = 'null',
  int visibilityEvents = 0,
  int hiddenEvents = 0,
  String responses = '',
}) {
  final String program =
      '''
const state = { fetches: 0, reloads: 0, loadOptions: null, listeners: [], storage: {}, warnings: [] };
const lastAttempt = $lastAttempt;
if (lastAttempt !== null) {
  state.storage['worklog.reloadAttempt'] = JSON.stringify(lastAttempt);
}
globalThis.window = { location: { reload() { state.reloads++; } } };
globalThis.document = {
  baseURI: '$_origin/worklog/',
  visibilityState: 'visible',
  getElementById(id) { return { id }; },
  addEventListener(type, listener) { state.listeners.push(listener); },
};
globalThis.sessionStorage = {
  getItem(key) { return key in state.storage ? state.storage[key] : null; },
  setItem(key, value) { state.storage[key] = value; },
};
const responses = [$responses];
globalThis.console.warn = (...args) => { state.warnings.push(args.join(' ')); };
globalThis.fetch = async () => {
  state.fetches++;
  await new Promise((resolve) => setTimeout(resolve, 20));
  const next = responses.length > 0
    ? responses.shift()
    : { status: 200, body: 'const buildVersion = "$deployedVersion" /* x */;' };
  if (next.reject) {
    throw new Error('offline');
  }
  return { ok: next.status >= 200 && next.status < 300, status: next.status, text: async () => next.body };
};
globalThis._flutter = {
  buildConfig: { builds: [{ compileTarget: 'dart2js', mainJsPath: 'main.dart.js' }, {}] },
  loader: { load(options) { state.loadOptions = options; } },
};
${_bootstrapSource()}
for (let i = 0; i < $visibilityEvents; i++) {
  state.listeners.forEach((listener) => listener());
}
setTimeout(() => {
  document.visibilityState = 'hidden';
  for (let i = 0; i < $hiddenEvents; i++) {
    state.listeners.forEach((listener) => listener());
  }
  document.visibilityState = 'visible';
}, 60);
setTimeout(() => {
  if (responses.length > 0) {
    state.listeners.forEach((listener) => listener());
  }
}, 80);
setTimeout(async () => {
  let engineConfig = null;
  await state.loadOptions.onEntrypointLoaded({
    initializeEngine: async (config) => {
      engineConfig = config;
      return { runApp: async () => {} };
    },
  });
  process.stdout.write(JSON.stringify({
    fetches: state.fetches,
    reloads: state.reloads,
    mainJsPath: _flutter.buildConfig.builds[0].mainJsPath,
    loadOptionKeys: Object.keys(state.loadOptions),
    hostElementId: engineConfig.hostElement.id,
    attempt: JSON.parse(state.storage['worklog.reloadAttempt'] || 'null'),
    warnings: state.warnings,
  }));
}, 200);
''';
  return _node(program) as Map<String, dynamic>;
}

void main() {
  final String notFoundScripts = _inlineScripts('web/404.html');
  final String indexScripts = _inlineScripts('web/index.html');

  group('web/404.html redirect', () {
    const Map<String, String?> cases = <String, String?>{
      '/worklog/statistics': '/worklog/?__route=%2Fstatistics',
      '/worklog/pr-3/statistics': '/worklog/pr-3/?__route=%2Fstatistics',
      '/worklog/training/exercise/42':
          '/worklog/?__route=%2Ftraining%2Fexercise%2F42',
      '/worklog/pr-abc/training': '/worklog/?__route=%2Fpr-abc%2Ftraining',
      '/worklog/': null,
      '/worklog/pr-3/': null,
      '/worklog/pr-3': null,
    };

    for (final MapEntry<String, String?> entry in cases.entries) {
      test('${entry.key} → ${entry.value ?? 'no redirect'}', () {
        expect(
          _call(
            notFoundScripts,
            "worklogRedirectTarget('${entry.key}', '', '')",
          ),
          entry.value,
        );
      });
    }

    test('carries the query string and the fragment along', () {
      expect(
        _call(
          notFoundScripts,
          "worklogRedirectTarget('/worklog/pr-3/training', '?day=3&q=a+b', '#set-2')",
        ),
        '/worklog/pr-3/?__route=%2Ftraining%3Fday%3D3%26q%3Da%2Bb#set-2',
      );
    });

    test('links a dead end back to the site root', () {
      expect(
        _call(notFoundScripts, "worklogSiteRoot('/worklog/pr-42/anything')"),
        '/worklog/',
      );
    });
  });

  group('web/index.html deep-link restore', () {
    const String base = '$_origin/worklog/pr-3/';

    String? restore(String search, [String hash = '']) {
      return _call(
        indexScripts,
        "worklogRestoredUrl(${jsonEncode(search)}, ${jsonEncode(hash)}, '$base')",
      ) as String?;
    }

    test('leaves a normal launch alone', () {
      expect(restore(''), isNull);
    });

    test("leaves the app's own query parameters alone", () {
      expect(restore('?p=7&q=squat'), isNull);
    });

    test('restores the route, its query and its fragment', () {
      expect(
        restore('?__route=%2Ftraining%3Fday%3D3', '#set-2'),
        '${base}training?day=3#set-2',
      );
    });

    const Map<String, String> hostile = <String, String>{
      'another origin': '?__route=https%3A%2F%2Fexample.com%2Fpwned',
      'a backslash-relative origin': '?__route=%5C%5Cexample.com%2Fx',
      'a dot-dot escape from the base href':
          '?__route=%2F..%2F..%2Fpr-4%2Ftraining',
      'a javascript: URL': '?__route=javascript%3Aalert(1)',
    };

    for (final MapEntry<String, String> entry in hostile.entries) {
      test('never leaves the deployment for ${entry.key}', () {
        final String restored = restore(entry.value)!;
        expect(restored, startsWith(base));
      });
    }

    test('falls back to the deployment root when it cannot stay inside', () {
      expect(restore(hostile['another origin']!), base);
      expect(restore(hostile['a dot-dot escape from the base href']!), base);
    });
  });

  group('404.html → index.html round trip', () {
    const List<String> links = <String>[
      '/worklog/statistics',
      '/worklog/pr-3/statistics?range=30d#chart',
      '/worklog/training?q=a%20b',
      '/worklog/pr-3/%D1%82%D1%80%D0%B5%D0%BD%D1%83%D0%B2%D0%B0%D0%BD%D0%BD%D1%8F',
    ];

    for (final String link in links) {
      test('lands back on $link', () {
        final String program =
            '''
$notFoundScripts
$indexScripts
const original = new URL('$_origin$link');
const redirect = new URL(
  worklogRedirectTarget(original.pathname, original.search, original.hash),
  original,
);
const base = new URL(redirect.pathname, redirect).href;
process.stdout.write(JSON.stringify(
  worklogRestoredUrl(redirect.search, redirect.hash, base),
));
''';
        expect(_node(program), '$_origin$link');
      });
    }
  });

  group('web/flutter_bootstrap.js', () {
    test('starts Flutter in #app without a service worker', () {
      final Map<String, dynamic> run = _launch();
      expect(run['loadOptionKeys'], <String>['onEntrypointLoaded']);
      expect(run['hostElementId'], 'app');
    });

    test('cache-busts main.dart.js with the build version', () {
      expect(_launch()['mainJsPath'], 'main.dart.js?v=123');
    });

    test('does not reload when the deployed build is the running one', () {
      final Map<String, dynamic> run = _launch();
      expect(run['fetches'], 1);
      expect(run['reloads'], 0);
    });

    test('reloads into a newer deployed build and records the attempt', () {
      final Map<String, dynamic> run = _launch(deployedVersion: '456');
      expect(run['reloads'], 1);
      expect((run['attempt'] as Map<String, dynamic>)['version'], '456');
    });

    test('does not reload again right after an attempt for that build', () {
      final Map<String, dynamic> run = _launch(
        deployedVersion: '456',
        lastAttempt: "{ version: '456', at: Date.now() - 60 * 1000 }",
      );
      expect(run['reloads'], 0);
    });

    test('retries once the CDN cache window has passed', () {
      final Map<String, dynamic> run = _launch(
        deployedVersion: '456',
        lastAttempt: "{ version: '456', at: Date.now() - 11 * 60 * 1000 }",
      );
      expect(run['reloads'], 1);
    });

    test('a newer build than the last attempt reloads immediately', () {
      final Map<String, dynamic> run = _launch(
        deployedVersion: '789',
        lastAttempt: "{ version: '456', at: Date.now() }",
      );
      expect(run['reloads'], 1);
    });

    test('does not check when the app goes to the background', () {
      final Map<String, dynamic> run = _launch(hiddenEvents: 3);
      expect(run['fetches'], 1);
    });

    test('coalesces foreground events while a check is in flight', () {
      final Map<String, dynamic> run = _launch(
        deployedVersion: '456',
        visibilityEvents: 5,
      );
      expect(run['fetches'], 1);
      expect(run['reloads'], 1);
    });

    test('warns instead of reloading when the deployment is gone', () {
      final Map<String, dynamic> run = _launch(
        responses: "{ status: 404, body: '<title>Page not found · GitHub Pages</title>' }",
      );
      expect(run['reloads'], 0);
      expect(run['warnings'], <dynamic>[contains('answered 404')]);
    });

    test('warns when the served page carries no build version', () {
      final Map<String, dynamic> run = _launch(
        responses: "{ status: 200, body: '<html>maintenance</html>' }",
      );
      expect(run['reloads'], 0);
      expect(run['warnings'], <dynamic>[contains('no build version')]);
    });

    test('keeps checking after a failed check', () {
      final Map<String, dynamic> run = _launch(
        responses: "{ reject: true }, { status: 200, body: 'const buildVersion = \"456\";' }",
      );
      expect(run['fetches'], 2);
      expect(run['reloads'], 1);
      expect(run['warnings'], <dynamic>[contains('could not check')]);
    });

    test('reads the version from a served index.html, not its own regex', () {
      final String servedIndex = _bootstrapSource(version: '999');
      expect(
        _call(
          _bootstrapSource(),
          'worklogBuildToReloadFor("123", ${jsonEncode(servedIndex)}, null, 0)',
        ),
        '999',
      );
    });
  });
}
