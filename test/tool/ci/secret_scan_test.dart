import 'package:flutter_test/flutter_test.dart';

import '../../../tool/ci/secret_scan.dart';

void main() {
  group('scanForSecrets', () {
    test('finds nothing in ordinary review prose', () {
      const String content = '''
### Review gate

All three reviewers passed. The bottom nav matches the rules file and the
Ukrainian labels are correct. Coverage is 100% against a floor of 95.
''';

      expect(scanForSecrets(content), isEmpty);
    });

    test('detects an anthropic api key', () {
      final List<SecretHit> hits = scanForSecrets(
        'token: sk-ant-api03-AAAABBBBCCCCDDDDEEEEFFFF',
      );

      expect(hits, hasLength(1));
      expect(hits.single.patternName, 'anthropic-api-key');
    });

    test('reports an oauth token under the more specific name', () {
      final List<SecretHit> hits = scanForSecrets(
        'sk-ant-oat01-AAAABBBBCCCCDDDD',
      );

      expect(hits, hasLength(1));
      expect(hits.single.patternName, 'anthropic-oauth-token');
    });

    test('detects a notion token in either prefix form', () {
      expect(
        scanForSecrets('ntn_${'a' * 40}').single.patternName,
        'notion-token',
      );
      expect(
        scanForSecrets('secret_${'b' * 40}').single.patternName,
        'notion-token',
      );
    });

    test('detects a github token', () {
      expect(
        scanForSecrets('gho_${'c' * 30}').single.patternName,
        'github-token',
      );
    });

    test('detects an env dump line', () {
      const String content = '''
Here is the output you asked for:
NOTION_TOKEN=something
''';

      expect(scanForSecrets(content).single.patternName, 'env-dump');
    });

    test(
      'does not treat ordinary prose with an equals sign as an env dump',
      () {
        expect(scanForSecrets('The assertion x = 4 holds.'), isEmpty);
      },
    );

    test('detects a private key header', () {
      expect(
        scanForSecrets('-----BEGIN RSA PRIVATE KEY-----').single.patternName,
        'private-key-header',
      );
    });

    test('reports a 1-indexed line number', () {
      const String content =
          'clean line\nanother clean line\nsk-ant-api03-AAAABBBBCCCCDDDDEEEE';

      expect(scanForSecrets(content).single.line, 3);
    });

    test('never puts the matched secret in the excerpt', () {
      const String secret = 'sk-ant-api03-SUPERSECRETVALUE12345';
      final List<SecretHit> hits = scanForSecrets('key is $secret now');

      expect(hits.single.excerpt, contains('[redacted]'));
      expect(hits.single.excerpt, isNot(contains('SUPERSECRETVALUE')));
      expect(hits.single.excerpt, isNot(contains(secret)));
    });

    test('finds every hit across multiple lines', () {
      const String content =
          'sk-ant-api03-AAAABBBBCCCCDDDDEEEE\nfine\ngho_cccccccccccccccccccccccccccccc';

      expect(scanForSecrets(content), hasLength(2));
    });

    test('detects an uppercased anthropic api key', () {
      final List<SecretHit> hits = scanForSecrets(
        'SK-ANT-API03-AAAABBBBCCCCDDDDEEEEFFFF',
      );

      expect(hits, hasLength(1));
      expect(hits.single.patternName, 'anthropic-api-key');
    });

    test('detects a mixed-case anthropic api key', () {
      final List<SecretHit> hits = scanForSecrets(
        'Sk-Ant-Api03-AAAABBBBCCCCDDDDEEEEFFFF',
      );

      expect(hits, hasLength(1));
      expect(hits.single.patternName, 'anthropic-api-key');
    });

    test('detects an uppercased anthropic oauth token', () {
      final List<SecretHit> hits = scanForSecrets(
        'SK-ANT-OAT01-AAAABBBBCCCCDDDD',
      );

      expect(hits, hasLength(1));
      expect(hits.single.patternName, 'anthropic-oauth-token');
    });

    test('detects an uppercased github token', () {
      expect(
        scanForSecrets('GHO_${'C' * 30}').single.patternName,
        'github-token',
      );
    });

    test('detects a mixed-case github token', () {
      expect(
        scanForSecrets('Gho_${'cC' * 15}').single.patternName,
        'github-token',
      );
    });

    test('detects a token split across a line break', () {
      final List<SecretHit> hits = scanForSecrets(
        'sk-ant-api03-AAAA\nBBBBCCCCDDDDEEEEFFFF',
      );

      expect(hits, hasLength(1));
      expect(hits.single.patternName, 'anthropic-api-key');
      expect(hits.single.line, 1);
      expect(hits.single.excerpt, isNot(contains('AAAA')));
      expect(hits.single.excerpt, isNot(contains('BBBB')));
    });

    test('detects a token split across a CRLF', () {
      final List<SecretHit> hits = scanForSecrets(
        'sk-ant-api03-AAAA\r\nBBBBCCCCDDDDEEEEFFFF',
      );

      expect(hits, hasLength(1));
      expect(hits.single.patternName, 'anthropic-api-key');
      expect(hits.single.line, 1);
    });

    test('does not join space-separated prose into a false positive', () {
      expect(
        scanForSecrets(
          'use sk-ant- prefixed keys\nand then AAAABBBBCCCCDDDDEEEE',
        ),
        isEmpty,
      );
    });
  });
}
