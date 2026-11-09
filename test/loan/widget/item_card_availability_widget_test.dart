import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/loan/ui/pages/admin_page/item_card.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// [ItemCard]'s availability line — the one number an admin reads before
/// deciding whether an item can still be lent out.
///
/// `availableQuantity = totalQuantity - loanedQuantity` is plain arithmetic,
/// but the branch it feeds is not cosmetic: at zero the card must say
/// "Unavailable" (and turn red), and it must never claim stock that is already
/// out. The card sweep mounts this widget for LAYOUT only, so no test reached
/// either arm, and the plural branch is invisible in English (`loanAvailable`
/// and `loanAvailableMultiple` are both "Available"), which is exactly why a
/// wrong quantity would go unnoticed — the count is the only signal.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Item item({
    String name = 'Tente 2 places',
    int total = 4,
    int loaned = 1,
    int caution = 30,
  }) => Item.empty().copyWith(
    id: 'item-1',
    name: name,
    totalQuantity: total,
    loanedQuantity: loaned,
    suggestedCaution: caution,
    suggestedLendingDuration: 3,
  );

  Future<void> mount(
    WidgetTester tester,
    Item theItem, {
    bool showButtons = false,
    VoidCallback? onEdit,
    Future Function()? onDelete,
  }) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: Center(
          child: ItemCard(
            item: theItem,
            showButtons: showButtons,
            onEdit: onEdit ?? () {},
            onDelete: onDelete ?? () async {},
          ),
        ),
      ),
      container,
      locale: const Locale('en', 'US'),
      appFonts: true,
    );
  }

  testWidgets('the card reports the remaining quantity, not the total', (
    tester,
  ) async {
    // 4 owned, 1 out: the admin must see 3, because the total would let them
    // lend a fourth one that does not exist on the shelf.
    await mount(tester, item(total: 4, loaned: 1));

    expect(find.text('3 Available'), findsOneWidget);
    expect(find.text('4 Available'), findsNothing);
    // The caution is printed with two decimals and a euro sign.
    expect(find.text('30.00 €'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a single remaining item still reads as available', (
    tester,
  ) async {
    // The boundary between the plural and singular label, which English
    // renders identically — the count is what distinguishes them.
    await mount(tester, item(total: 4, loaned: 3));

    expect(find.text('1 Available'), findsOneWidget);
    expect(find.text('Unavailable'), findsNothing);
  });

  testWidgets('a fully loaned-out item is unavailable', (tester) async {
    await mount(tester, item(total: 4, loaned: 4));

    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.textContaining('Available'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the admin buttons wire edit and delete', (tester) async {
    var edits = 0;
    var deletes = 0;
    await mount(
      tester,
      item(),
      showButtons: true,
      onEdit: () => edits++,
      onDelete: () async => deletes++,
    );

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.pencil,
      ),
    );
    await tester.pump();
    expect(edits, 1);

    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.trash),
    );
    await tester.pump();
    expect(deletes, 1);
  });
}
