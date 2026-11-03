import 'package:flutter_test/flutter_test.dart';

import '../../shared/inplace_list_mutation_detector.dart';

/// The ratchet for ledger #12's family, generalised.
///
/// `tools/widget/fixed_width_cards_test.dart` is the standing sweep for a
/// card that hardcodes a width beside flex children. The `.sort(` half of
/// ledger #12 was swept by hand and its fixes are recorded in the ledger;
/// nothing guarded it automatically. This does: it fails when a mutating list/set call in
/// `lib/` has a receiver the detector cannot resolve to a copy, to a class's own
/// field, to a notifier's API or to a platform object.
///
/// There is NO exemption list, and no way to add one: the ratchet used to
/// carry 28 of them, one per shape the detector could not resolve — a
/// DateTime local, a controller from `useTextEditingController`, a fold
/// accumulator, a ternary of copies. Every one of those shapes now has a rule
/// in the detector that PROVES it is not a finding, so the list was emptied
/// and then deleted along with the vacuous "it is still empty" test that
/// guarded it (a `const` empty map can never fail `isEmpty`). Fix the
/// receiver (copy it) or teach the detector the shape; the rule is the thing
/// that lasts.
void main() {
  group('in-place list mutation ratchet', () {
    late List<InplaceMutation> all;

    setUpAll(() {
      all = findInplaceListMutations();
    });

    List<InplaceMutation> review() =>
        all.where((m) => m.bucket == Bucket.review).toList();

    test('every unresolved receiver is resolved, not exempted', () {
      final unlisted = review()
          .map((m) => '  ${m.id}  receiver=${m.receiver}')
          .toList();

      expect(
        unlisted,
        isEmpty,
        reason:
            'these sites mutate a collection the surrounding code does not own.\n'
            'Copy the receiver first (`List.of(x)`, `[...x]`, `x.toList()`) —\n'
            'or teach `test/shared/inplace_list_mutation_detector.dart` to '
            'resolve this shape. There is '
            'no allowlist to add to: the exemption list was retired.\n'
            '${unlisted.join('\n')}',
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
        containsAll(Bucket.values.where((b) => b != Bucket.review)),
        reason: 'a bucket with no members means its classifier is dead',
      );
      // `review` is the finding bucket and it is meant to be empty — but a
      // detector that stopped recognising anything would empty it too, so the
      // total-and-bucket pin above is what tells those two apart.
      expect(
        all.where((m) => m.bucket == Bucket.review),
        isEmpty,
        reason: 'every receiver in `lib/` must resolve to a proven-safe shape',
      );
    });
  });
}
