import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../shared/collection_guard_detector.dart';
import '../collection_guard_fixtures.dart';

/// The standing ratchet for unguarded collection lookups.
///
/// The empty-input sweep that produced these fixes was a one-time pass; this
/// file is what makes a new bare `firstWhere` fail tomorrow. Three rules, all
/// proven on a synthetic fixture. The Dart detector is the only
/// implementation, so a rule change has one place to land.
void main() {
  group('unguarded collection lookup ratchet', () {
    late List<CollectionGuardHazard> all;

    setUpAll(() {
      all = findCollectionGuards();
    });

    test('every unguarded lookup is known and reasoned', () {
      final unlisted = all
          .where((hazard) => !knownGuards.containsKey('$hazard'))
          .map((hazard) => '  $hazard (line ${hazard.line})')
          .toList();

      expect(
        unlisted,
        isEmpty,
        reason:
            'a lookup can throw when the element is absent — `Bad state: No '
            'element` out of a build, a comparator or a tap handler. Use '
            '`firstWhere(..., orElse: ...)`, `firstWhereOrNull`, or replace '
            '`where(...).first` with a guarded lookup. Only if the site is '
            'provably safe (an `any(hasError)` check above it, an enclosing '
            'try) add its key to knownGuards in '
            'test/tools/unit/collection_guard_ratchet_test.dart with the '
            'reason:\n${unlisted.join('\n')}',
      );
    });

    test('every known guard carries a reason', () {
      final unreasoned = knownGuards.entries
          .where((entry) => entry.value.trim().isEmpty)
          .map((entry) => '  ${entry.key}')
          .toList();

      expect(unreasoned, isEmpty, reason: 'a pin with no reason is debt');
    });

    test('no known guard has gone stale', () {
      final found = all.map((hazard) => '$hazard').toSet();
      final stale = knownGuards.keys
          .where((key) => !found.contains(key))
          .map((key) => '  $key')
          .toList();

      expect(
        stale,
        isEmpty,
        reason:
            'these pins name lookups the detector no longer finds — the site '
            'was fixed, renamed or deleted, so the pin now hides a fresh '
            'regression at the same place. Delete it with the fix.\n'
            '${stale.join('\n')}',
      );
    });

    test('each rule still flags its unsafe fixture and only it', () {
      Directory? root;
      addTearDown(() {
        if (root != null) root.deleteSync(recursive: true);
      });
      root = _writeFixture();

      final found = findCollectionGuards(root: root.path);
      final byFile = {
        for (final hazard in found) _fileName(hazard.source): hazard.rule,
      };

      expect(
        byFile,
        unsafeCollectionGuards,
        reason: 'a rule stopped flagging its own shape, or flagged a safe one',
      );
      expect(found.map((h) => h.rule).toSet(), {
        bareFirstWhere,
        whereChainFirst,
        unwrappedOptional,
      });
    });
  });
}

Directory _writeFixture() {
  final root = Directory.systemTemp.createTempSync('collection_guards');
  final lib = Directory('${root.path}/lib')..createSync(recursive: true);
  for (final entry in collectionGuardFixtureFiles.entries) {
    File('${lib.path}/${entry.key}').writeAsStringSync(entry.value);
  }
  return root;
}

String _fileName(String source) => source.split('/').last;

/// The pin list for sites that are genuinely safe. Keys are the detector's
/// own `path rule` rows, and every key must still be found by the scan.
const knownGuards = <String, String>{
  'lib/tools/ui/builders/async_child.dart bareFirstWhere':
      'guarded one line above by `values.any((value) => value.hasError)`: '
      'when this lookup runs, the list provably holds an error.',
  'lib/tools/logs/file_logger_output.dart bareFirstWhere':
      'inside the try whose catch returns a Log.error row, so an unknown '
      'level is recorded instead of escaping.',
};
