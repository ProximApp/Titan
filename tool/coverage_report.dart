// Coverage report, ratchet gate and generated-code filter for the Dart lcov
// output of `flutter test --coverage`.
//
// Pure `dart:io` — no external dependency, runs with plain `dart run` in CI
// right after the test step. The parsing and the arithmetic live in
// tool/coverage_lcov.dart so they are unit-tested without spawning this file;
// what stays here is the file work and the CLI surface.
//
// Generated code is excluded everywhere (report, gate and the filtered lcov
// written with --lcov-out), so Codecov and the uploaded artifact show the same
// honest numbers as the report:
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

import 'coverage_lcov.dart';

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

  final report = parseLcov(lcovFile.readAsStringSync());
  if (report.files.isEmpty) {
    stderr.writeln('No included files in $lcovPath');
    exitCode = 2;
    return;
  }

  final overall = report.coverage;
  // The ratchet floor gates the OVERALL percentage (COVERAGE_MIN / --min=),
  // which is what this tool has always checked. The per-file rows in the
  // summary below are informational: a single low-coverage file (flappybird
  // pages, chart painters) must not redden CI at the overall baseline.
  final underMin = !report.meets(minimum);
  stdout.writeln('files: ${report.files.length}');
  stdout.writeln('lines: ${report.totalFound} found, ${report.totalHit} hit');
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
    lines.add('- **files:** ${report.files.length}');
    lines.add(
      '- **lines:** ${report.totalFound} found, ${report.totalHit} hit',
    );
    lines.add('- **coverage:** ${overall.toStringAsFixed(2)}%');
    if (underMin) {
      lines.add('- **minimum not met:** $minimum%');
    }
    lines.add('');
    lines.add('## Per-file coverage');
    lines.add('');
    lines.add('| file | found | hit | % |');
    lines.add('| --- | --- | --- | --- |');
    for (final file
        in report.files.toList()..sort((a, b) => a.path.compareTo(b.path))) {
      lines.add(
        '| `${file.path}` | ${file.found} | ${file.hit} | '
        '${file.ratio.toStringAsFixed(2)}% |',
      );
    }
    summary.writeAsStringSync('${lines.join('\n')}\n');
    stdout.writeln('summary: $summaryPath');
  }

  if (lcovOutPath != null) {
    final out = File(lcovOutPath);
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(report.filteredLcov);
    stdout.writeln('filtered lcov: $lcovOutPath');
  }
}
