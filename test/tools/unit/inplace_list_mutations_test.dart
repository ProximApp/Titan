import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../shared/inplace_list_mutation_detector.dart';

/// The ratchet for ledger #12's family, generalised.
///
/// `tools/widget/fixed_width_cards_test.dart` is the standing sweep for a
/// card that hardcodes a width beside flex children. `tool/detect_inplace_sorts.py`
/// is a manual command for the `.sort(` half of ledger #12. Neither guards
/// anything automatically. This does: it fails when a mutating list/set call in
/// `lib/` has a receiver the detector cannot resolve to a copy, to a class's own
/// field, to a notifier's API or to a platform object.
///
/// [verifiedSafe] is the whole of the accepted remainder, each entry with the
/// reason it was read and accepted. A site that is not in it is a finding, so
/// the list has to be re-read every time it changes — that is the cost, and
/// it is the point: the alternative is the status quo, where 12 defects sat
/// across 6 files and four of them never notified a listener at all.
void main() {
  group('in-place list mutation ratchet', () {
    late List<InplaceMutation> all;

    setUpAll(() {
      all = findInplaceListMutations();
    });

    List<InplaceMutation> review() =>
        all.where((m) => m.bucket == Bucket.review).toList();

    test('every unresolved receiver is a known, justified site', () {
      final unlisted = review()
          .where((m) => !verifiedSafe.containsKey(m.id))
          .map((m) => '  ${m.id}  receiver=${m.receiver}')
          .toList();

      expect(
        unlisted,
        isEmpty,
        reason:
            'these sites mutate a collection the surrounding code does not own.\n'
            'Copy the receiver first (`List.of(x)`, `[...x]`, `x.toList()`), or\n'
            'if it is genuinely safe, add it to `verifiedSafe` in\n'
            'test/tools/unit/inplace_list_mutations_test.dart with a reason.\n'
            '${unlisted.join('\n')}',
      );
    });

    test('every accepted site carries a reason', () {
      final unreasoned = verifiedSafe.entries
          .where((e) => e.value.trim().isEmpty)
          .map((e) => '  ${e.key}')
          .toList();

      expect(
        unreasoned,
        isEmpty,
        reason:
            'an exemption with no reason is indistinguishable from a finding '
            'nobody got round to reading',
      );
    });

    test('no accepted site has gone stale', () {
      final found = {for (final m in review()) m.id};
      final stale = verifiedSafe.keys
          .where((id) => !found.contains(id))
          .map((id) => '  $id')
          .toList();

      expect(
        stale,
        isEmpty,
        reason:
            'these entries name sites the detector no longer finds — the call '
            'was fixed, renamed or deleted, so the exemption is just dead '
            'weight that hides a future regression at the same place',
      );
    });

    test('the detector still finds candidates at all', () {
      // The guard against the detector itself rotting. Two of its regexes were
      // once spliced with `r'...$_fragment...'` — and a Dart RAW string does
      // NOT interpolate, so both compiled to patterns containing the literal
      // text `$fragment`, matched nothing, and took the findings from 21 to
      // 115 with no error anywhere. A silently-dead regex is worse than no
      // regex, so the total is pinned.
      expect(all.length, greaterThan(100));
      expect(
        all.map((m) => m.bucket).toSet(),
        containsAll(Bucket.values),
        reason: 'a bucket with no members means its classifier is dead',
      );
    });
  });

  group('the Dart port agrees with the Python tool', () {
    test('row for row', () {
      final result = Process.runSync('python3', [
        'tool/detect_inplace_list_mutations.py',
        '--dump',
      ]);
      if (result.exitCode == -1 || result.stderr.toString().isNotEmpty) {
        markTestSkipped(
          'python3 is unavailable here, so the two detectors cannot be '
          'cross-checked. The `still finds candidates` test above covers the '
          'same failure mode (a dead regex) without needing Python.',
        );
        return;
      }

      final python = (result.stdout as String)
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .map((l) => l.trim().split(RegExp(r'\s+')).take(2).join(' '))
          .toSet();
      final dart = findInplaceListMutations()
          .map((m) => '${m.bucket.name} ${m.id}')
          .toSet();

      final onlyPython = python.difference(dart).toList()..sort();
      final onlyDart = dart.difference(python).toList()..sort();

      expect(
        onlyPython,
        isEmpty,
        reason: 'the Python tool finds sites the Dart port does not',
      );
      expect(
        onlyDart,
        isEmpty,
        reason: 'the Dart port finds sites the Python tool does not',
      );
      expect(dart.length, greaterThan(100));
    });
  });
}

/// The accepted remainder: every REVIEW site, with why it is safe.
///
/// Grouped by shape rather than by file, because the shapes are the lesson —
/// four different files each had "a local named something the declaration
/// scan could not see".
const verifiedSafe = <String, String>{
  // --- Not a collection at all: a DateTime. `now.add(Duration(...))` is the
  // single most common false positive in the codebase, and it is why the
  // detector has a NONLIST bucket rather than relying on names.
  'lib/home/providers/days_provider.dart:10':
      '`now` is a DateTime local, not a list. `DateTime.add` has nothing to do '
      'with list mutation.',
  'lib/service/tools/setup.dart:51':
      '`now` is a DateTime local: `now.add(const Duration(days: 30))`. '
      '(Ledger #36 moved this line: the topics notifier is now read inside '
      'the authorized branch, so the comment explaining it sits above it.)',
  'lib/loan/ui/pages/admin_page/on_going_loan.dart:136':
      '`e.end` is a DateTime field of the loan model: `e.end.add(...)`.',

  // --- Platform objects, not Dart lists. The controller ones are the
  // TextEditingController behind each of the four date fields.
  'lib/admin/ui/pages/membership/association_membership_detail_page/search_filters.dart:140':
      '`startMaximal` is a useTextEditingController(); `clear()` is its API.',
  'lib/admin/ui/pages/membership/association_membership_detail_page/search_filters.dart:141':
      '`startMinimal` is a useTextEditingController().',
  'lib/admin/ui/pages/membership/association_membership_detail_page/search_filters.dart:142':
      '`endMaximal` is a useTextEditingController().',
  'lib/admin/ui/pages/membership/association_membership_detail_page/search_filters.dart:143':
      '`endMinimal` is a useTextEditingController().',
  'lib/seed-library/ui/pages/plant_deposit_page/plant_deposit_page.dart:293':
      '`seedQuantity` is a useTextEditingController(); `clear()` empties the '
      'field, which is the point.',
  'lib/seed-library/ui/pages/plant_deposit_page/plant_deposit_page.dart:294':
      '`notes` is a useTextEditingController().',
  'lib/mypayment/ui/pages/devices_page/devices_page.dart:193':
      '`keyService` is the KeyService; `clear()` is its own method for '
      'unregistering the device, not a collection mutation.',
  'lib/service/local_notification_service.dart:223':
      '`onNotificationClick` is a StreamController; `add` feeds the stream.',

  // --- A fresh copy the declaration scan cannot see, because the RHS is a
  // ternary or spans lines.
  'lib/admin/ui/components/association_picker_modal.dart:53':
      '`filtered` is `query.isEmpty ? [...associations] : '
      'associations.where(...).toList()` — both arms are copies.',
  'lib/event/ui/pages/admin_page/list_event.dart:41':
      '`filteredEvents` is `events.where(...).toList()` in both arms of the '
      '`isHistory` ternary, so the sort mutates a copy.',
  'lib/purchases/ui/pages/scan_page/scan_page.dart:115':
      '`a` is the accumulator of `fold([], (a, b) => a..addAll(b))`; the seed '
      'is a fresh literal.',

  // --- A local whose declaration is a literal on the same statement, but whose
  // type argument contains a `>` that the `<...>[]` pattern cannot span.
  'lib/super_admin/ui/pages/permissions/permissions.dart:127':
      '`result` is `final result = <MapEntry<String, List<String>>>[];` — a '
      'local list. The nested `>>` defeats the declaration pattern, which '
      'is a known gap rather than a reason to accept a risk.',
  'lib/super_admin/ui/pages/permissions/permissions.dart:129':
      'Same `result` local as line 127.',

  // --- Flutter's own diagnostics builder, which is an argument parameter.
  'lib/tools/ui/heroicons.dart:95':
      '`properties` is the DiagnosticPropertiesBuilder parameter Flutter '
      'hands debugFillProperties; adding to it is its whole contract.',
  'lib/tools/ui/heroicons.dart:96': 'Same `properties` builder parameter.',
  'lib/tools/ui/heroicons.dart:99': 'Same `properties` builder parameter.',
  'lib/tools/ui/heroicons.dart:100': 'Same `properties` builder parameter.',

  // --- Verified in ledger #12 alongside the 21 sort fixes, re-confirmed here.
  'lib/phonebook/tools/function.dart:42':
      '`list` is a parameter that this function has already copied into a new '
      'list before sorting; confirmed by reading the whole body when '
      'ledger #12 fixed the other 21 sort sites.',
};
