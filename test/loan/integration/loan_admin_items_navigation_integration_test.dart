import 'package:flutter/material.dart' show IconButton;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/router.dart';
import 'package:titan/loan/ui/pages/admin_page/item_card.dart';
import 'package:titan/loan/ui/pages/admin_page/loaners_items.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../loan_fixtures.dart';

/// The two navigation handlers of `loaners_items` — the plus tile (add mode:
/// it stores `Item.empty()` before routing) and a card's pencil (edit mode:
/// it stores the tapped item). Both are round trips, because the form only
/// tells the two modes apart by what the handler stored: the route is the
/// same `/loan/admin/add_edit_item`.
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

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Finder heroIcon(HeroIcons icon) => find.byWidgetPredicate(
    (w) => w is HeroIcon && w.icon == icon,
    description: 'HeroIcon($icon)',
  );

  testWidgets('the plus tile opens the add form and a pencil the edit form', (
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
    ).thenAnswer((_) async => chopperListResponse([tent]));
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

    // Plus tile → add mode.
    await tester.tap(
      find.descendant(
        of: find.byType(LoanersItems),
        matching: heroIcon(HeroIcons.plus),
      ),
    );
    await settle(tester, frames: 40);
    expect(find.text('Add an object'), findsOneWidget);

    // Back to the admin page (TopBar chevron).
    await tester.tap(find.byType(IconButton));
    await settle(tester, frames: 40);
    expect(find.text('Add an object'), findsNothing);
    expect(find.textContaining('Tente 2 places'), findsOneWidget);

    // Pencil → edit mode, prefilled with the tapped item.
    final card = find.descendant(
      of: find.byType(LoanersItems),
      matching: find.byType(ItemCard),
    );
    await tester.tap(
      find.descendant(of: card, matching: heroIcon(HeroIcons.pencil)),
    );
    await settle(tester, frames: 40);
    expect(find.text('Edit the object'), findsOneWidget);
    expect(find.text('Tente 2 places'), findsOneWidget);
  });
}
