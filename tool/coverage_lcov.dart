// Pure lcov parsing and coverage arithmetic, extracted from
// tool/coverage_report.dart so the numbers CI gates on can be asserted by a
// normal test run instead of by spawning the CLI. No dart:io here — the
// caller does the file work.
//
// The filters are the same ones the report, the gate and `--lcov-out` have
// always applied, so the report and the uploaded lcov cannot disagree:
//   - lib/generated/  (swagger models & API client)
//   - lib/l10n/       (flutter_gen app_localizations)
import 'dart:convert';

/// Records that are reported and gated: `lib/` only, minus generated code and
/// the generated localizations.
const defaultExcludedPrefixes = ['lib/generated/', 'lib/l10n/'];

/// One lcov record that survived the filters.
class LcovFile {
  const LcovFile({required this.path, required this.found, required this.hit});

  final String path;
  final int found;
  final int hit;

  int get missed => found - hit;

  double get ratio => found == 0 ? 100.0 : 100.0 * hit / found;
}

/// Every included record, in lcov order, plus the filtered lcov text the CLI
/// writes with `--lcov-out`.
class LcovReport {
  const LcovReport({required this.files, required this.filteredLcov});

  final List<LcovFile> files;
  final String filteredLcov;

  int get totalFound => files.fold(0, (sum, file) => sum + file.found);

  int get totalHit => files.fold(0, (sum, file) => sum + file.hit);

  /// Hit lines over found lines. An empty report reads as 100%, which is what
  /// the CLI reported before this was extracted; the empty case is rejected one
  /// level up instead, so the gate cannot pass by having parsed nothing.
  double get coverage =>
      totalFound == 0 ? 100.0 : 100.0 * totalHit / totalFound;

  bool meets(double minimum) => coverage >= minimum;
}

/// Parses lcov [content], keeping only `lib/` records that are not generated
/// and that actually carry coverage data.
///
/// `LF:`/`LH:` are ignored on the way in and recomputed from the `DA:` lines on
/// the way out, so a stale or hand-edited pair in the input cannot leak into
/// the filtered lcov or the totals.
LcovReport parseLcov(
  String content, {
  List<String> excludedPrefixes = defaultExcludedPrefixes,
}) {
  final files = <LcovFile>[];
  final filtered = StringBuffer();
  var currentPath = '';
  var found = 0;
  var hit = 0;
  final record = StringBuffer();

  for (final line in const LineSplitter().convert(content)) {
    if (line.startsWith('SF:')) {
      currentPath = line.substring(3);
      found = 0;
      hit = 0;
      record
        ..clear()
        ..writeln(line);
    } else if (line.startsWith('DA:')) {
      // DA:<line>,<hits>[,<checksum>]
      final hits = int.parse(line.split(',')[1]);
      found++;
      if (hits > 0) hit++;
      record.writeln(line);
    } else if (line.startsWith('LF:') || line.startsWith('LH:')) {
      // Recomputed below; dropped here so the filtered lcov carries only what
      // the DA lines say.
    } else if (line.startsWith('end_of_record')) {
      final included =
          currentPath.startsWith('lib/') &&
          !excludedPrefixes.any(currentPath.startsWith);
      if (included && found > 0) {
        files.add(LcovFile(path: currentPath, found: found, hit: hit));
        filtered
          ..writeln(record.toString())
          ..writeln('LF:$found')
          ..writeln('LH:$hit')
          ..writeln('end_of_record');
      }
      record.clear();
      currentPath = '';
    } else {
      // FN:/FNDA:/BRDA:/… — carried through untouched.
      record.writeln(line);
    }
  }

  return LcovReport(files: files, filteredLcov: filtered.toString());
}
