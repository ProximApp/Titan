import 'package:flutter_test/flutter_test.dart';

import '../../../tool/coverage_lcov.dart';

/// Two live lib records, one generated, one l10n, one outside lib/.
const _sample =
    'SF:lib/a.dart\n'
    'DA:1,1\n'
    'DA:2,0\n'
    'LF:2\n'
    'LH:1\n'
    'end_of_record\n'
    'SF:lib/generated/g.dart\n'
    'DA:1,0\n'
    'DA:2,0\n'
    'LF:2\n'
    'LH:0\n'
    'end_of_record\n'
    'SF:lib/l10n/l.dart\n'
    'DA:1,1\n'
    'LF:1\n'
    'LH:1\n'
    'end_of_record\n'
    'SF:test/t.dart\n'
    'DA:1,1\n'
    'LF:1\n'
    'LH:1\n'
    'end_of_record\n';

void main() {
  group('parseLcov', () {
    test('keeps lib/ and drops generated, l10n and non-lib records', () {
      final report = parseLcov(_sample);

      expect(report.files.map((f) => f.path), ['lib/a.dart']);
      expect(report.totalFound, 2);
      expect(report.totalHit, 1);
    });

    test('recounts found and hit from the DA lines, not from LF/LH', () {
      // The record lies about its own totals: three DA lines, one hit, while
      // LF/LH claim 99. The parser must trust the lines it can count.
      final report = parseLcov(
        'SF:lib/lying.dart\n'
        'DA:1,0\n'
        'DA:2,1\n'
        'DA:3,7\n'
        'LF:99\n'
        'LH:98\n'
        'end_of_record\n',
      );

      expect(report.totalFound, 3);
      expect(report.totalHit, 2);
      expect(report.coverage, closeTo(66.67, 0.01));
    });

    test('the filtered lcov carries only included records, retotalled', () {
      final report = parseLcov(_sample);

      expect(report.filteredLcov, contains('SF:lib/a.dart'));
      expect(report.filteredLcov, contains('LF:2'));
      expect(report.filteredLcov, contains('LH:1'));
      // Nothing generated, nothing localized, nothing outside lib/.
      expect(report.filteredLcov, isNot(contains('generated')));
      expect(report.filteredLcov, isNot(contains('l10n')));
      expect(report.filteredLcov, isNot(contains('SF:test/t.dart')));
    });

    test('a DA line with a checksum still counts as one line', () {
      final report = parseLcov(
        'SF:lib/a.dart\nDA:7,3,deadbeef\nend_of_record\n',
      );

      expect(report.totalFound, 1);
      expect(report.totalHit, 1);
    });

    test('a record with no DA lines is dropped rather than counted as full', () {
      // A file listed but never exercisable (annotation-only, all consts) would
      // otherwise score 100% of zero lines and inflate the total.
      final report = parseLcov('SF:lib/empty.dart\nFN:1,foo\nend_of_record\n');

      expect(report.files, isEmpty);
    });

    test('an empty file is an empty report, and the CLI rejects it', () {
      final report = parseLcov('');

      expect(report.files, isEmpty);
      expect(report.totalFound, 0);
      // 100% of nothing: harmless here, because coverage_report.dart exits 2
      // on an empty report instead of passing the gate.
      expect(report.coverage, 100.0);
    });
  });

  group('ratchet arithmetic', () {
    test('an exact floor is met, a hundredth above it is not', () {
      final report = parseLcov(
        'SF:lib/a.dart\nDA:1,1\nDA:2,0\nend_of_record\n',
      );

      expect(report.coverage, 50.0);
      expect(report.meets(50), isTrue);
      expect(report.meets(50.01), isFalse);
    });

    test('coverage aggregates every kept file', () {
      final report = parseLcov(
        'SF:lib/a.dart\nDA:1,1\nDA:2,0\nend_of_record\n'
        'SF:lib/b.dart\nDA:1,1\nDA:2,1\nDA:3,1\nDA:4,0\nend_of_record\n',
      );

      expect(report.files, hasLength(2));
      expect(report.totalFound, 6);
      expect(report.totalHit, 4);
      expect(report.files[0].missed, 1);
      expect(report.files[1].ratio, 75.0);
    });
  });
}
