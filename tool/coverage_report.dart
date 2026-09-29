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
        record
          ..writeln('LF:$found')
          ..writeln('LH:$hit')
          ..writeln(rawLine);
        filtered.write(record);
      }
      currentPath = '';
    }
  }

  var totalFound = 0;
  var totalHit = 0;
  // module -> [found, hit, fileCount]
  final modules = <String, List<int>>{};
  files.forEach((path, counts) {
    totalFound += counts[0];
    totalHit += counts[1];
    final parts = path.split('/');
    final module = parts.length > 2 ? parts[1] : '.';
    final entry = modules.putIfAbsent(module, () => [0, 0, 0]);
    entry[0] += counts[0];
    entry[1] += counts[1];
    entry[2]++;
  });

  final percentage = totalFound > 0 ? 100.0 * totalHit / totalFound : 0.0;

  final lines = <String>[
    '## Coverage report',
    '',
    '**Total: ${percentage.toStringAsFixed(1)}%** '
        '(${_thousands(totalHit)}/${_thousands(totalFound)} executable lines '
        'across ${files.length} files, generated code excluded)',
    '',
    '| Module | Coverage | Lines hit | Files |',
    '|---|---|---|---|',
  ];
  final sortedModules = modules.keys.toList()
    ..sort(
      (a, b) => _moduleRate(modules[a]!).compareTo(_moduleRate(modules[b]!)),
    );
  for (final module in sortedModules) {
    final m = modules[module]!;
    final rate = m[0] > 0 ? 100.0 * m[1] / m[0] : 0.0;
    lines.add(
      '| $module | ${rate.toStringAsFixed(1)}% '
      '| ${_thousands(m[1])}/${_thousands(m[0])} | ${m[2]} |',
    );
  }
  final report = lines.join('\n');
  stdout.writeln(report);

  if (summaryPath != null) {
    File(summaryPath)
      ..createSync(recursive: true)
      ..writeAsStringSync('$report\n');
  }
  if (lcovOutPath != null) {
    File(lcovOutPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(filtered.toString());
  }

  if (percentage < minimum) {
    stderr.writeln(
      'Coverage ${percentage.toStringAsFixed(1)}% is below the required '
      '${minimum.toStringAsFixed(1)}% ratchet floor (COVERAGE_MIN / --min=).',
    );
    exitCode = 1;
  }
}

double _moduleRate(List<int> m) => m[0] > 0 ? m[1] / m[0] : 0.0;

String _thousands(int n) {
  final s = n.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final remaining = s.length - i;
    buffer.write(s[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return buffer.toString();
}
