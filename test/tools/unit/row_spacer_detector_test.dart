import 'package:flutter_test/flutter_test.dart';

import '../../shared/row_spacer_detector.dart';

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
/// This test is the rule that stops the fourth one from shipping: every
/// `Row` of that shape under `lib/` must be listed in [knownHazards] with a
/// reason, so the NEXT one fails here instead of overflowing on a device.
/// The fix for a listed site is always the same shape — wrap the
/// `Column`/`Text` in `Expanded` (add `maxLines: 1` + ellipsis when the
/// child is a one-line title) and drop the now-pointless `Spacer` — and
/// when a site gets it, the stale-entry test below fails until the pin is
/// removed with the fix.
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
            'Fix the row (wrap the child in Expanded, drop the Spacer), or '
            'if the row is genuinely safe, add its key to knownHazards in '
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
      // The guard against the detector itself rotting: a dead regex or a
      // mangled `_unconstrained` set reports FEWER findings, and fewer
      // findings is exactly what an empty unlisted-list would celebrate.
      // The two kinds pin the two branches of the family — ledger #47/#48's
      // label Column and the CustomButton-style Text.
      expect(
        all,
        isNotEmpty,
        reason: 'the scan found nothing at all: it is broken',
      );
      expect(
        all.map((h) => h.child).toSet(),
        containsAll(<String>['Column', 'Text']),
        reason: 'one half of the family stopped being detected',
      );
      expect(
        all.length,
        knownHazards.length,
        reason:
            'the detector and its pin list must agree on the count, or one '
            'of them moved without the other',
      );
    });
  });
}

/// Every site the detector flags today, with why it is still standing.
///
/// NONE of these is safe — each is the defect the rule exists to catch,
/// read and pinned rather than fixed, in the same spirit as the ledger's
/// `KNOWN BUG` pins: the fix is one shape for all of them (Expanded child,
/// one-line ellipsis for titles, drop the Spacer) but it changes what users
/// see, so it lands as its own round. What the pin buys: the NEXT Row of
/// this shape fails here instead of shipping.
const knownHazards = <String, String>{
  // --- Page headers: a 24pt localized title, a Spacer, an action button.
  // The title is the unbounded child; a longer locale than the French one
  // ships is all it takes.
  'lib/admin/ui/pages/association_page/association_page.dart AssociationPage Text':
      'Header `adminAssociations` (24pt) + Spacer + add button; fits today, '
      'unbounded by construction.',
  'lib/admin/ui/pages/groups/groups_page/groups_page.dart GroupsPage Text':
      'Header `adminGroupsManagement` + Spacer + add button; same shape as '
      'association_page.',
  'lib/admin/ui/pages/membership/association_membership_detail_page/association_membership_detail_page.dart AssociationMembershipEditorPage Text':
      'Header `"Members (n)"` — the count grows with the filtered list, so '
      'the unbounded side is also the moving side.',
  'lib/admin/ui/pages/membership/association_membership_page/association_membership_page.dart AssociationMembershipsPage Text':
      'Header `adminAssociationMembership` — one of the longest FR titles '
      'in the admin family, + Spacer + add button.',
  'lib/admin/ui/pages/structure_page/structure_page.dart StructurePage Text':
      'Header `adminStructures` + Spacer + add button; same shape as '
      'association_page.',
  'lib/feed/ui/pages/main_page/main_page.dart FeedMainPage Text':
      'Header `feedNews` + Spacer + filter IconButton.',
  'lib/phonebook/ui/pages/admin_page/admin_page.dart AdminPage Text':
      'Header `phonebookAssociations` + Spacer + conditional add button.',
  'lib/tickets/ui/pages/tickets_main_page.dart TicketsMainPage Text':
      'Header `ticketsTitle` + Spacer + spread `if` action buttons; the '
      'spread is skipped by the scan but does not bound the title.',
  'lib/vote/ui/pages/admin_page/admin_page.dart AdminPage Text':
      'Section header `votePretendance` (18pt) + Spacer + conditional add '
      'button.',
  'lib/vote/ui/pages/list_pages/list_member.dart ListMember Text':
      'Members header `voteMembers` + Spacer + add button.',
  'lib/vote/ui/pages/main_page/main_page.dart VoteMainPage Text':
      'Collection-`if` admin title + Spacer + userGroup button — the title '
      'is conditional but still unbounded.',

  // --- Cards and rows where the unbounded child is data, not a title.
  'lib/amap/ui/pages/main_page/delivery_ui.dart DeliveryUi Text':
      'Delivery row with TWO unbounded Texts (date + trailing label) around '
      'a Spacer; dates and amounts are the adversarial strings.',
  'lib/mypayment/ui/pages/devices_page/add_device_button.dart AddDeviceButton Text':
      '20pt bold label flanked by TWO Spacers beside the icon Stack — the '
      'label looks centred but nothing bounds it.',
  'lib/mypayment/ui/pages/store_admin_page/search_result.dart SearchResult Text':
      'Search-result row: `getName()` + Spacer + WaitingButton. Names are '
      'exactly the string ledger #47 overflowed on.',
  'lib/mypayment/ui/pages/store_admin_page/seller_right_card.dart SellerRightCard Text':
      'Rights row: icon + SizedBox(15) + label + Spacer + Checkbox; the '
      'label is unbounded.',
  'lib/mypayment/ui/pages/structure_admin_page/admin_store_card.dart AdminStoreCard Text':
      'Store-name Text + Spacer + edit gesture; a long store name overflows '
      'the card header.',
  'lib/raffle/ui/pages/main_page/raffle_card.dart RaffleWidget Column':
      'Stats row leading with the Spacer, then an unbounded Column '
      '(count + label) — same family with the roles reversed.',
  'lib/seed-library/ui/pages/add_edit_species_page/add_edit_species_page.dart AddEditSpeciesPage Column':
      'Month-picker row: leading Spacer + Column whose DropdownButton makes '
      'the column as wide as its widest month option.',
  'lib/ph/ui/pages/admin_page/admin_ph_card.dart AdminPhCard Column':
      'The field Column is a direct Row child beside a Spacer — and this '
      'card ALREADY overflows at 320px, pinned in '
      'fixed_width_cards_test._320overflow. This detector reproduces '
      'that pinned symptom\'s cause; the fix here is Expanded.',
};
