import 'package:flutter/material.dart' show Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/loan/providers/caution_provider.dart';
import 'package:titan/loan/providers/edit_selected_items_provider.dart';
import 'package:titan/loan/providers/start_provider.dart';
import 'package:titan/loan/router.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../loan_fixtures.dart';

/// Decrementing one line of a MULTI-item selection keeps the end date and the
/// caution derived from the remaining selection; the single-item test only
/// ever decremented to zero, which takes the clearing branch instead.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('dropping one of two selected items keeps the derived totals', (
    tester,
  ) async {
    await loadAppFonts();
    final loaner = loanerFixture(
      id: 'loaner-1',
      name: 'Asso Matériel',
      groupManagerId: 'grp-1',
    );
    final tent = itemFixture(
      id: 'item-1',
      name: 'Tente 2 places',
      totalQuantity: 4,
      suggestedCaution: 3000,
      suggestedLendingDuration: 3,
    );
    final rope = itemFixture(
      id: 'item-2',
      name: 'Corde',
      totalQuantity: 2,
      suggestedCaution: 500,
      suggestedLendingDuration: 5,
    );

    final container = scaffold.makeContainer(myLoaners: [loaner]);
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    when(() => scaffold.repository.loansUsersMeLoanersGet())
        .thenAnswer((_) async => chopperListResponse([loaner]));
    when(
      () => scaffold.repository.loansLoanersLoanerIdItemsGet(
        loanerId: any(named: 'loanerId'),
      ),
    ).thenAnswer((_) async => chopperListResponse([tent, rope]));
    when(
      () => scaffold.repository.loansLoanersLoanerIdLoansGet(
        loanerId: 'loaner-1',
      ),
    ).thenAnswer((_) async => chopperListResponse(<Loan>[]));
    when(
      () => scaffold.repository.loansLoanersLoanerIdLoansGet(
        loanerId: 'loaner-1',
        returned: true,
      ),
    ).thenAnswer((_) async => chopperListResponse(<Loan>[]));

    // A start date is what lets the notifier derive the end at all.
    container.read(startProvider.notifier).setStart('1/15/2026');

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${LoanRouter.root}${LoanRouter.admin}${LoanRouter.addEditLoan}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 40);

    final plusIcon = find.byWidgetPredicate(
      (w) => w is HeroIcon && w.icon == HeroIcons.plus,
    );
    expect(plusIcon, findsNWidgets(2));

    await tester.tap(plusIcon.at(0));
    await settle(tester, frames: 6);
    await tester.tap(plusIcon.at(1));
    await settle(tester, frames: 6);
    expect(container.read(editSelectedListProvider), [1, 1]);
    final bothCaution = container.read(cautionProvider).text;
    expect(bothCaution, isNot(''));

    // One minus leaves the OTHER item selected, so the totals are recomputed
    // from what is left instead of being cleared.
    await tester.tap(
      find
          .byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.minus)
          .at(0),
    );
    await settle(tester, frames: 6);

    expect(container.read(editSelectedListProvider), [0, 1]);
    expect(container.read(cautionProvider).text, isNot(''));
    expect(container.read(cautionProvider).text, isNot(bothCaution));
    expect(find.byType(Text), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
