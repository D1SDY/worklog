import 'package:flutter_test/flutter_test.dart';

import '../../../tool/ci/coverage_check.dart';

void main() {
  group('lineRate', () {
    test('sums LF and LH across records', () {
      const String lcov = '''
SF:lib/a.dart
LF:10
LH:8
end_of_record
SF:lib/b.dart
LF:10
LH:7
end_of_record
''';

      expect(lineRate(lcov), closeTo(75.0, 0.001));
    });

    test('returns 100 when there is nothing to cover', () {
      expect(lineRate(''), 100.0);
    });

    test('excludes generated files from the rate', () {
      const String lcov = '''
SF:lib/a.dart
LF:10
LH:10
end_of_record
SF:lib/a.g.dart
LF:100
LH:0
end_of_record
''';

      expect(lineRate(lcov), 100.0);
    });

    test('excludes freezed files from the rate', () {
      const String lcov = '''
SF:lib/a.dart
LF:4
LH:2
end_of_record
SF:lib/a.freezed.dart
LF:100
LH:0
end_of_record
''';

      expect(lineRate(lcov), closeTo(50.0, 0.001));
    });

    test('handles Windows path separators in SF records', () {
      const String lcov = '''
SF:lib\\ui\\a.g.dart
LF:50
LH:0
end_of_record
SF:lib\\ui\\b.dart
LF:2
LH:2
end_of_record
''';

      expect(lineRate(lcov), 100.0);
    });
  });

  group('hasCoverageData', () {
    test('returns false for an empty report', () {
      expect(hasCoverageData(''), isFalse);
    });

    test('returns false when the only record is excluded', () {
      const String lcov = '''
SF:lib/a.g.dart
LF:100
LH:0
end_of_record
''';

      expect(hasCoverageData(lcov), isFalse);
    });

    test('returns true for a normal report with one real record', () {
      const String lcov = '''
SF:lib/a.dart
LF:10
LH:8
end_of_record
''';

      expect(hasCoverageData(lcov), isTrue);
    });

    test('returns false when the only record has LF:0', () {
      const String lcov = '''
SF:lib/a.dart
LF:0
LH:0
end_of_record
''';

      expect(hasCoverageData(lcov), isFalse);
    });

    test('returns true when a real record follows an excluded one', () {
      const String lcov = '''
SF:lib/a.g.dart
LF:100
LH:0
end_of_record
SF:lib/b.dart
LF:2
LH:2
end_of_record
''';

      expect(hasCoverageData(lcov), isTrue);
    });
  });

  group('meetsFloor', () {
    test('passes when the rate equals the floor', () {
      expect(meetsFloor(95.0, 95.0), isTrue);
    });

    test('passes when the rate exceeds the floor', () {
      expect(meetsFloor(96.4, 95.0), isTrue);
    });

    test('fails when the rate is below the floor', () {
      expect(meetsFloor(94.9, 95.0), isFalse);
    });
  });

  group('parseFloor', () {
    test('reads a bare number', () {
      expect(parseFloor('95'), 95.0);
    });

    test('tolerates surrounding whitespace and a trailing newline', () {
      expect(parseFloor(' 87.5 \n'), 87.5);
    });

    test('throws on a non-numeric floor file', () {
      expect(() => parseFloor('ninety'), throwsFormatException);
    });
  });
}
