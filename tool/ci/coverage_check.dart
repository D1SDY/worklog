import 'dart:io';

/// Substrings that mark a source file as generated and therefore excluded from
/// the coverage rate.
const List<String> excludedPatterns = <String>[
  '.g.dart',
  '.freezed.dart',
  '.mocks.dart',
];

/// The percentage of instrumented lines that are covered, ignoring generated
/// files. Returns 100 when there is nothing to cover.
double lineRate(String lcov) {
  int found = 0;
  int hit = 0;
  bool excluded = false;

  for (final String line in lcov.split('\n')) {
    final String record = line.trim();
    if (record.startsWith('SF:')) {
      final String path = record.substring(3).replaceAll(r'\', '/');
      excluded = excludedPatterns.any(path.endsWith);
    } else if (record == 'end_of_record') {
      excluded = false;
    } else if (excluded) {
      continue;
    } else if (record.startsWith('LF:')) {
      found += int.parse(record.substring(3));
    } else if (record.startsWith('LH:')) {
      hit += int.parse(record.substring(3));
    }
  }

  if (found == 0) {
    return 100;
  }
  return hit * 100 / found;
}

/// Whether [rate] satisfies [floor].
bool meetsFloor(double rate, double floor) => rate >= floor;

/// Parses the contents of `.github/coverage-floor`.
double parseFloor(String contents) {
  final double? value = double.tryParse(contents.trim());
  if (value == null) {
    throw FormatException('coverage floor is not a number', contents);
  }
  return value;
}

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln('usage: coverage_check.dart <lcov-path> <floor-path>');
    exit(2);
  }

  final File lcovFile = File(args[0]);
  if (!lcovFile.existsSync()) {
    stderr.writeln('no coverage report at ${args[0]}');
    exit(1);
  }

  final double rate = lineRate(lcovFile.readAsStringSync());
  final double floor = parseFloor(File(args[1]).readAsStringSync());

  stdout.writeln(
    'coverage ${rate.toStringAsFixed(1)}% (floor ${floor.toStringAsFixed(1)}%)',
  );

  if (!meetsFloor(rate, floor)) {
    stderr.writeln('FAIL: coverage is below the floor');
    exit(1);
  }
}
