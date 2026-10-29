// Coverage report, ratchet gate and generated-code filter for the Dart lcov
// output of `flutter test --coverage`.
//
// Pure `dart:io` — no external dependency, runs with plain `dart run` in CI
// right after the test step. Generated code is excluded everywhere (report,
// gate and the filtered lcov written with --lcov-out), so Codecov and the
// uploaded artifact show the same honest numbers as the report:
//   - lib/generated/  (swagger models & API client)
//   - lib/l10n/       (flutter_gen app_localizations)
//
// Usage:
//   dart run tool/coverage_report.dart \
//     [--lcov=coverage/lcov.info] \
//     [--min=22]                \  # fail (exit 1) below this percentage
//     [--summary=coverage/summary.md] \  # also write the markdown report
//     [--lcov-out=coverage/lcov.filtered.info]
import 'dart:io';

const _excludedPrefixes = ['lib/generated/', 'lib/l10n/'];

void main(List<String> args) {
  var lcovPath = 'coverage/lcov.info';
  var minimum = 0.0;
  String? summaryPath;
  String? lcovOutPath;
  for (final arg in args) {
    if (arg.startsWith('--lcov=')) {
      lcovPath = arg.substring('--lcov='.length);
    } else if (arg.startsWith('--min=')) {
      minimum = double.parse(arg.substring('--min='.length));
    } else if (arg.startsWith('--summary=')) {
      summaryPath = arg.substring('--summary='.length);
    } else if (arg.startsWith('--lcov-out=')) {
      lcovOutPath = arg.substring('--lcov-out='.length);
    } else {
      stderr.writeln('Unknown argument: $arg');
      exitCode = 2;
      return;
    }
  }

  final lcovFile = File(lcovPath);
  if (!lcovFile.existsSync()) {
    stderr.writeln('Coverage file not found: $lcovPath');
    stderr.writeln('Run `flutter test --coverage` first.');
    exitCode = 2;
    return;
  }

  // path -> [found, hit]
  final files = <String, List<int>>{};
  final filtered = StringBuffer();
  var currentPath = '';
  var found = 0;
  var hit = 0;
  var record = StringBuffer();

  for (final rawLine in lcovFile.readAsLinesSync()) {
    if (rawLine.startsWith('SF:')) {
      currentPath = rawLine.substring(3);
      found = 0;
      hit = 0;
      record
        ..clear()
        ..writeln(rawLine);
    } else if (rawLine.startsWith('DA:')) {
      // DA:<line>,<hits>[,<checksum>]
      final hits = int.parse(rawLine.split(',')[1]);
      found++;
      if (hits > 0) hit++;
      record.writeln(rawLine);
    } else if (rawLine.startsWith('LF:') || rawLine.startsWith('LH:')) {
      // Recomputed below; drop the original ones.
      continue;
    } else if (rawLine.startsWith('end_of_record')) {
      final included =
          currentPath.startsWith('lib/') &&
          !_excludedPrefixes.any(currentPath.startsWith);
      if (included && found > 0) {
        files[currentPath] = [found, hit];
        filtered
          ..writeln(record.toString())
          ..writeln('LF:$found')
          ..writeln('LH:$hit')
          ..writeln('end_of_record');
      }
      record.clear();
      currentPath = '';
    } else {
      record.writeln(rawLine);
    }
  }

  if (files.isEmpty) {
    stderr.writeln('No included files in $lcovPath');
    exitCode = 2;
    return;
  }

  var totalFound = 0;
  var totalHit = 0;
  var underMin = false;
  for (final entry in files.entries) {
    final found = entry.value[0];
    final hit = entry.value[1];
    totalFound += found;
    totalHit += hit;
  }

  final overall = totalFound == 0 ? 100.0 : 100.0 * totalHit / totalFound;
  // The ratchet floor gates the OVERALL percentage (COVERAGE_MIN / --min=),
  // which is what this tool has always checked. The per-file rows in the
  // summary below are informational: a single low-coverage file (flappybird
  // pages, chart painters) must not redden CI at the overall baseline.
  underMin = overall < minimum;
  stdout.writeln('files: ${files.length}');
  stdout.writeln('lines: $totalFound found, $totalHit hit');
  stdout.writeln('coverage: ${overall.toStringAsFixed(2)}%');
  if (underMin) {
    stdout.writeln(
      'MINIMUM NOT MET: ${overall.toStringAsFixed(2)}% is below the required '
      '$minimum% ratchet floor.',
    );
    exitCode = 1;
  } else {
    exitCode = 0;
  }

  if (summaryPath != null) {
    final summary = File(summaryPath);
    summary.parent.createSync(recursive: true);
    final lines = <String>[];
    lines.add('# Coverage summary');
    lines.add('');
    lines.add('- **files:** ${files.length}');
    lines.add('- **lines:** $totalFound found, $totalHit hit');
    lines.add('- **coverage:** ${overall.toStringAsFixed(2)}%');
    if (underMin) {
      lines.add('- **minimum not met:** $minimum%');
    }
    lines.add('');
    lines.add('## Per-file coverage');
    lines.add('');
    lines.add('| file | found | hit | % |');
    lines.add('| --- | --- | --- | --- |');
    for (final entry
        in files.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
      final found = entry.value[0];
      final hit = entry.value[1];
      final ratio = found == 0 ? 100.0 : 100.0 * hit / found;
      lines.add(
        '| `${entry.key}` | $found | $hit | ${ratio.toStringAsFixed(2)}% |',
      );
    }
    summary.writeAsStringSync(lines.join('\n') + '\n');
    stdout.writeln('summary: $summaryPath');
  }

  if (lcovOutPath != null) {
    final out = File(lcovOutPath);
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(filtered.toString());
    stdout.writeln('filtered lcov: $lcovOutPath');
  }
}
