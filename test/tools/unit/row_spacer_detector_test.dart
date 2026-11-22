import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../shared/row_spacer_detector.dart';
import '../row_spacer_fixtures.dart';

/// The ratchet for ledger #47/#48's defect family — the shape behind the
/// advert, scan-card and `CustomButton` overflows: a `Row` that puts a
/// `Spacer` next to a `Column`/`Text` with no width bound of its own.
///
/// `Row` hands every non-flex child unbounded width, so the label sizes to
/// its intrinsic width and never wraps to the row; the `Spacer` can only
/// take slack that no longer exists once that width passes the row's, and
/// the whole row goes past the right edge. That is exactly how
/// `AdminAdvertCard` shipped 37px over, how purchases' scan `TicketCard`
/// shipped 149px over, and how the header `CustomButton` pair shipped
/// 236px over — three fixes of one family, each made by hand after the fact.
///
/// [knownHazards] is EMPTY: all 18 sites it used to pin are fixed in `lib/`
/// with the one shape the pin described — the unbounded child goes in an
/// `Expanded` (`maxLines: 1` + `TextOverflow.ellipsis` for a one-line
/// title), so it takes the width that is left instead of pushing the row
/// past the edge. A new Row of this shape still fails here, and the fix the
/// message asks for is the one that cleared the list.
void main() {
  group('Row+Spacer unconstrained-child ratchet', () {
    late List<RowSpacerHazard> all;

    setUpAll(() {
      all = findRowSpacerHazards();
    });

    test('every hazard the detector finds is known and reasoned', () {
      final unlisted = all
          .where((h) => !knownHazards.containsKey('$h'))
          .map((h) => '  $h (line ${h.line})')
          .toList();

      expect(
        unlisted,
        isEmpty,
        reason:
            'a Row puts a Spacer next to a Column/Text that has no width '
            'bound of its own — ledger #47/#48\'s overflow family, the shape '
            'that shipped AdminAdvertCard 37px, the scan TicketCard 149px '
            'and the header CustomButton pair 236px past the right edge. '
            'Fix the row: wrap the child in `Expanded` (one-line titles take '
            '`maxLines: 1` + `TextOverflow.ellipsis`) so it is bounded by '
            'the width that is left. Only if the row is genuinely safe add '
            'its key to knownHazards in '
            'test/tools/unit/row_spacer_detector_test.dart with a reason. '
            'The new sites are listed above.\n'
            '${unlisted.join('\n')}',
      );
    });

    test('every known hazard carries a reason', () {
      final unreasoned = knownHazards.entries
          .where((e) => e.value.trim().isEmpty)
          .map((e) => '  ${e.key}')
          .toList();

      expect(
        unreasoned,
        isEmpty,
        reason:
            'a pin with no reason is indistinguishable from a hazard nobody '
            'got round to reading',
      );
    });

    test('no known hazard has gone stale', () {
      final found = all.map((h) => '$h').toSet();
      final stale = knownHazards.keys
          .where((k) => !found.contains(k))
          .map((k) => '  $k')
          .toList();

      expect(
        stale,
        isEmpty,
        reason:
            'these pins name Rows the detector no longer finds — the row was '
            'fixed, renamed or deleted, so the pin is now dead weight that '
            'would hide a fresh regression at the same place. Remove the '
            'entry together with the fix that made it stale.\n'
            '${stale.join('\n')}',
      );
    });

    test('the detector still finds both child kinds', () {
      // The guard against the detector itself rotting. `lib/` reports 0
      // hazards now, and 0 is also what a BROKEN scan reports — a dead regex,
      // a mangled `_unconstrained` set or a bracket walk that never opens a
      // children list would empty the list and the empty `knownHazards`
      // assertion above would celebrate it. So the scan is pointed at a
      // fixture holding one of each family member and both must come back.
      final root = Directory.systemTemp.createTempSync('row_spacer_ratchet');
      addTearDown(() => root.deleteSync(recursive: true));
      Directory('${root.path}/lib').createSync(recursive: true);
      File('${root.path}/lib/fixture.dart')
          .writeAsStringSync(rowSpacerFixtureSource);

      final found = findRowSpacerHazards(root: root.path);

      expect(
        found.map((h) => h.className).toSet(),
        containsAll(<String>['WithText', 'WithColumn']),
        reason: 'the scan stopped attributing a Row to its enclosing class',
      );
      expect(
        found.map((h) => h.child).toSet(),
        containsAll(<String>['Column', 'Text']),
        reason: 'one half of the family stopped being detected',
      );
    });

    test('the fix shape is classified clean', () {
      // The other half of liveness: the scan must NOT flag the shape the
      // failure message prescribes. `Expanded`/`Flexible` around the child,
      // and a `Spacer` with no unconstrained sibling, are both safe — a
      // detector that flagged them would push the next fix in the wrong
      // direction.
      final root = Directory.systemTemp.createTempSync('row_spacer_safe');
      addTearDown(() => root.deleteSync(recursive: true));
      Directory('${root.path}/lib').createSync(recursive: true);
      File('${root.path}/lib/fixture.dart')
          .writeAsStringSync(rowSpacerFixtureSource);

      final found = findRowSpacerHazards(root: root.path);

      expect(
        found
            .map((h) => h.className)
            .toSet()
            .intersection(safeRowSpacerClasses),
        isEmpty,
        reason:
            'the scan flagged a row that the prescribed fix already bounds — '
            'Expanded/Flexible children and Spacer-free rows are safe',
      );
    });
  });
}

/// The pin list — EMPTY, and it stays that way while the fix fits.
///
/// It used to hold 18 sites, each with the reason it was read and pinned
/// rather than repaired: eleven page headers (`Text` title + `Spacer` +
/// action button, where a longer locale than the French one ships is all it
/// takes), five card rows where the unbounded child is data rather than a
/// title (a date, a store name, a user name, a rights label), and two whose
/// roles were reversed (`RaffleWidget`'s stats columns, the month-picker row
/// on the species editor).
///
/// Every one is now fixed in `lib/` with the shape this list prescribed: the
/// unbounded child sits in an `Expanded`, one-line titles carrying
/// `maxLines: 1` + `TextOverflow.ellipsis`, and the `Spacer` that only existed
/// to push a button right is dropped where the `Expanded` does that job itself
/// (kept where a title is conditional, since the `else` branch still needs it).
///
/// An entry here is for a row where that fix is not the right one. It must
/// carry its reason, and the staleness test above deletes it the moment the
/// row is fixed — which is how this list went from 18 to 0.
const knownHazards = <String, String>{};
