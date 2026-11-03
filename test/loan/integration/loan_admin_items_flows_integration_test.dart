import 'package:flutter/material.dart' show Offset, TextField;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/router.dart';
import 'package:titan/loan/ui/pages/admin_page/item_card.dart';
import 'package:titan/loan/ui/pages/admin_page/loaners_items.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';
import 'package:titan/tools/ui/widgets/custom_dialog_box.dart';

import '../../shared/app_scaffold.dart';
import '../loan_fixtures.dart';

/// The in-page interactions of `loaners_items` that no mount test reaches:
/// the search bar's filter-and-clear round trip (which swaps the loaners
/// map entry for a filtered copy and restores the full list) and the delete
/// confirmation dialog with its real DELETE round trip. No navigation, so
/// the whole file rides on one deep link.
void main() {
  late IntegrationScaffold scaffold;

  final loaner = loanerFixture(
    id: 'loaner-1',
    name: 'Asso Matériel',
    groupManagerId: 'grp-1',
  );
  final tent = itemFixture(
    id: 'item-1',
    name: 'Tente 2 places',
    loanerId: 'loaner-1',
    totalQuantity: 4,
  );
  final drill = itemFixture(
    id: 'item-2',
    name: 'Perceuse',
    loanerId: 'loaner-1',
    totalQuantity: 1,
  );

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Finder heroIcon(HeroIcons icon) => find.byWidgetPredicate(
    (w) => w is HeroIcon && w.icon == icon,
    description: 'HeroIcon($icon)',
  );

  testWidgets('the item search filters and restores the item strip', (
    tester,
  ) async {
    final container = scaffold.makeContainer(myLoaners: [loaner]);
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    when(() => scaffold.repository.loansUsersMeLoanersGet())
        .thenAnswer((_) async => chopperListResponse([loaner]));
    when(
      () => scaffold.repository.loansLoanersLoanerIdItemsGet(
        loanerId: any(named: 'loanerId'),
      ),
    ).thenAnswer((_) async => chopperListResponse([tent, drill]));
    when(
      () => scaffold.repository.loansLoanersLoanerIdLoansGet(
        loanerId: any(named: 'loanerId'),
        returned: any(named: 'returned'),
      ),
    ).thenAnswer((_) async => chopperListResponse(<Loan>[]));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${LoanRouter.root}${LoanRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 40);

    expect(find.textContaining('Tente 2 places'), findsOneWidget);
    expect(find.textContaining('Perceuse'), findsOneWidget);

    // Filter down to the tent, then clear: both states of onChanged.
    // The admin page hosts three search bars (items, ongoing, history);
    // this one has to be the ITEMS bar or the filter below tests the wrong
    // list.
    final search = find.descendant(
      of: find.byType(LoanersItems),
      matching: find.byType(TextField),
    );
    expect(search, findsOneWidget);
    await tester.enterText(search, 'tente');
    await settle(tester, frames: 4);
    expect(find.textContaining('Tente 2 places'), findsOneWidget);
    expect(find.textContaining('Perceuse'), findsNothing);

    await tester.enterText(search, '');
    await settle(tester, frames: 4);
    expect(find.textContaining('Tente 2 places'), findsOneWidget);
    expect(find.textContaining('Perceuse'), findsOneWidget);

    // The delete path: trash → confirm dialog → DELETE → gone from the strip.
    var deletes = 0;
    when(
      () => scaffold.repository.loansLoanersLoanerIdItemsItemIdDelete(
        loanerId: any(named: 'loanerId'),
        itemId: any(named: 'itemId'),
      ),
    ).thenAnswer((inv) async {
      deletes++;
      expect(inv.namedArguments[#itemId], 'item-2');
      return chopperResponseVoid();
    });

    final drillCard = find.ancestor(
      of: find.textContaining('Perceuse'),
      matching: find.byType(ItemCard),
    );
    await tester.tap(
      find.descendant(of: drillCard, matching: heroIcon(HeroIcons.trash)),
    );
    await settle(tester, frames: 4);
    expect(find.byType(CustomDialogBox), findsOneWidget);
    expect(find.text('Delete the object?'), findsOneWidget);

    // Cancel first: nothing is sent and the card survives.
    await tester.tap(
      find.descendant(
        of: find.byType(CustomDialogBox),
        matching: find.text('Cancel'),
      ),
    );
    await settle(tester, frames: 4);
    expect(find.byType(CustomDialogBox), findsNothing);
    expect(deletes, 0);
    expect(find.textContaining('Perceuse'), findsOneWidget);

    // Confirm for real.
    await tester.tap(
      find.descendant(of: drillCard, matching: heroIcon(HeroIcons.trash)),
    );
    await settle(tester, frames: 4);
    await tester.tap(
      find.descendant(
        of: find.byType(CustomDialogBox),
        matching: find.text('Confirm'),
      ),
    );
    await settle(tester, frames: 10);

    expect(deletes, 1);
    expect(find.textContaining('Perceuse'), findsNothing);
    expect(find.textContaining('Tente 2 places'), findsOneWidget);

    // Pull-to-refresh reloads the whole admin state for the selected
    // loaner: items, ongoing loans and history, each repainted from its
    // notifier copy.
    await tester.drag(find.byType(Refresher), const Offset(0, 1500));
    await settle(tester, frames: 30);
    verify(
      () => scaffold.repository.loansLoanersLoanerIdItemsGet(
        loanerId: 'loaner-1',
      ),
    ).called(greaterThan(1));
    verify(
      () => scaffold.repository.loansLoanersLoanerIdLoansGet(
        loanerId: 'loaner-1',
        returned: any(named: 'returned'),
      ),
    ).called(greaterThan(1));
    // The refreshed item list is painted again (delete did NOT come back).
    expect(find.textContaining('Perceuse'), findsNothing);
    expect(find.textContaining('Tente 2 places'), findsOneWidget);
    await scaffold.drainToast(tester);
  });
}
