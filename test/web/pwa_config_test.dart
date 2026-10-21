import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/ui/core/theme/app_tokens.dart';

String _hex(Color color) {
  final int rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

Size _pngSize(File file) {
  final ByteData header = ByteData.sublistView(file.readAsBytesSync(), 16, 24);
  return Size(header.getUint32(0).toDouble(), header.getUint32(4).toDouble());
}

void main() {
  final Map<String, dynamic> manifest = jsonDecode(
    File('web/manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final String indexHtml = File('web/index.html').readAsStringSync();
  final String notFoundHtml = File('web/404.html').readAsStringSync();
  final String developWorkflow = File('.github/workflows/develop.yml')
      .readAsStringSync();

  group('web/manifest.json', () {
    test('names and describes the app instead of the Flutter template', () {
      expect(manifest['name'], 'Workout Logger');
      expect(manifest['short_name'], 'Worklog');
      expect(manifest['description'], isNot(contains('Flutter')));
      expect(manifest['lang'], 'uk');
    });

    test('background and theme colour are the --bg-primary token', () {
      expect(manifest['background_color'], _hex(AppColors.bgPrimary));
      expect(manifest['theme_color'], _hex(AppColors.bgPrimary));
    });

    test('installs as a standalone portrait app scoped to its deployment', () {
      expect(manifest['display'], 'standalone');
      expect(manifest['orientation'], 'portrait');
      expect(manifest['start_url'], './');
      expect(manifest['scope'], './');
    });

    test('every declared icon exists at its declared size', () {
      final List<dynamic> icons = manifest['icons'] as List<dynamic>;
      expect(
        icons.map((dynamic icon) => (icon as Map<String, dynamic>)['purpose']),
        containsAll(<String>['any', 'maskable']),
      );
      for (final dynamic icon in icons) {
        final Map<String, dynamic> entry = icon as Map<String, dynamic>;
        final File file = File('web/${entry['src']}');
        final List<String> size = (entry['sizes'] as String).split('x');
        expect(file.existsSync(), isTrue, reason: '${entry['src']} missing');
        expect(
          _pngSize(file),
          Size(double.parse(size[0]), double.parse(size[1])),
          reason: '${entry['src']} is not ${entry['sizes']}',
        );
      }
    });
  });

  group('web/index.html', () {
    test('launches fullscreen from the iOS home screen', () {
      expect(indexHtml, contains('name="apple-mobile-web-app-capable"'));
      expect(indexHtml, contains('content="black-translucent"'));
      expect(indexHtml, contains('viewport-fit=cover'));
      expect(indexHtml, contains('href="icons/apple-touch-icon.png"'));
      expect(
        _pngSize(File('web/icons/apple-touch-icon.png')),
        const Size(180, 180),
      );
    });

    test(
      'keeps the Flutter view inside the notch and home-indicator insets',
      () {
        for (final String side in <String>['top', 'right', 'bottom', 'left']) {
          expect(indexHtml, contains('$side: env(safe-area-inset-$side, 0px)'));
        }
        expect(indexHtml, contains('<div id="app"></div>'));
      },
    );

    test('paints the inset strips with the surfaces they border', () {
      expect(
        indexHtml,
        contains(
          'linear-gradient(to bottom, ${_hex(AppColors.bgPrimary)} 50%, '
          '${_hex(AppColors.bgSecondary)} 50%)',
        ),
      );
      expect(
        indexHtml,
        contains('name="theme-color" content="${_hex(AppColors.bgPrimary)}"'),
      );
    });
  });

  group('web/404.html', () {
    test('uses the --bg-primary and text-primary tokens', () {
      expect(
        notFoundHtml,
        contains('name="theme-color" content="${_hex(AppColors.bgPrimary)}"'),
      );
      expect(
        notFoundHtml,
        contains('background: ${_hex(AppColors.bgPrimary)};'),
      );
      expect(notFoundHtml, contains('color: ${_hex(AppColors.textPrimary)};'));
      expect(notFoundHtml, contains('color: ${_hex(AppColors.accentBlue)};'));
      expect(notFoundHtml, contains('gap: ${AppSpacing.lg.toInt()}px;'));
    });
  });

  group('.github/workflows/develop.yml', () {
    test('deploys every push to develop to the site root', () {
      expect(developWorkflow, contains('branches: [develop]'));
      expect(
        developWorkflow,
        contains('flutter build web --release --base-href "/worklog/"'),
      );
      expect(developWorkflow, contains('ref: gh-pages'));
    });

    test('blocks the deploy on analyze and test failures', () {
      expect(developWorkflow, contains('flutter analyze --fatal-infos'));
      expect(developWorkflow, contains('flutter test --coverage'));
      expect(developWorkflow, contains('needs: verify'));
    });

    test('keeps the pull request previews when replacing the root', () {
      expect(developWorkflow, contains("! -name 'pr-*'"));
      expect(developWorkflow, contains('! -name .nojekyll'));
    });

    test('does not finish until GitHub Pages serves the new build', () {
      expect(developWorkflow, contains('pages: write'));
      expect(developWorkflow, contains('pages/builds'));
      expect(
        developWorkflow,
        contains("grep -o 'buildVersion = \"[0-9]*\"' build/web/index.html"),
      );
    });
  });
}
