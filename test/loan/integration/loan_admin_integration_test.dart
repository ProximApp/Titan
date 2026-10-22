import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/providers/loaner_id_provider.dart';
import 'package:titan/loan/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';

/// The loan admin gate derives from the user's loaner list: a non-empty
/// list means admin. Pre-seeding the provider is the same async-gate trap
/// as the mypayment/booking gates.
void main() {
  late IntegrationScaffold scaffold;

  final loaner = loanerFixture(
    id: 'loaner-1',
    name: 'Asso Matériel',
    groupManagerId: 'grp-1',
  );
  final item = itemFixture(
    id: 'item-1',
    name: 'Tente 2 places',
    loanerId: 'loaner-1',
    totalQuantity: 4,
    loanedQuantity: 1,
    suggestedCaution: 3000,
    suggestedLendingDuration: 3,
  );
  final secondLoaner = loanerFixture(
    id: 'loaner-2',
    name: 'Atelier',
    groupManagerId: 'grp-2',
  );
  final secondItem = itemFixture(
    id: 'item-2',
    name: 'Perceuse',
    loanerId: 'loaner-2',
    totalQuantity: 2,
    loanedQuantity: 0,
    suggestedCaution: 1000,
    suggestedLendingDuration: 5,
  );
  final emptyLoaner = loanerFixture(
    id: 'loaner-3',
    name: 'Réserve',
    groupManagerId: 'grp-3',
  );

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'deep link to /loan/admin lists the loaner items for a loaner manager',
    (tester) async {
      final container = scaffold.makeContainer(myLoaners: [loaner]);
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      when(() => scaffold.repository.loansUsersMeLoanersGet())
          .thenAnswer((_) async => chopperListResponse([loaner]));
      when(
        () => scaffold.repository.loansLoanersLoanerIdItemsGet(
          loanerId: 'loaner-1',
        ),
      ).thenAnswer((_) async => chopperListResponse([item]));
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
      await settle(tester);

      // The item card renders with the real item data from the endpoint.
      expect(find.textContaining('Tente 2 places'), findsOneWidget);
    },
  );

  testWidgets('switching loaners loads and shows that loaner data', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      myLoaners: [loaner, secondLoaner, emptyLoaner],
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);

    when(() => scaffold.repository.loansUsersMeLoanersGet()).thenAnswer(
      (_) async => chopperListResponse([loaner, secondLoaner, emptyLoaner]),
    );
    when(
      () => scaffold.repository.loansLoanersLoanerIdItemsGet(
        loanerId: any(named: 'loanerId'),
      ),
    ).thenAnswer((inv) async {
      final requestedLoaner = inv.namedArguments[#loanerId] as String;
      if (requestedLoaner == secondLoaner.id) {
        return chopperListResponse([secondItem]);
      }
      if (requestedLoaner == emptyLoaner.id) {
        return chopperListResponse(<Item>[]);
      }
      return chopperListResponse([item]);
    });
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
    await settle(tester, frames: 20);

    expect(find.textContaining('Tente 2 places'), findsOneWidget);
    await tester.ensureVisible(find.text('Atelier'));
    await tester.tap(find.text('Atelier'));
    await settle(tester, frames: 20);

    expect(find.textContaining('Perceuse'), findsOneWidget);
    expect(find.textContaining('Tente 2 places'), findsNothing);
    expect(container.read(loanerIdProvider), secondLoaner.id);
    verify(
      () => scaffold.repository.loansLoanersLoanerIdItemsGet(
        loanerId: secondLoaner.id,
      ),
    ).called(greaterThan(0));
    verify(
      () => scaffold.repository.loansLoanersLoanerIdLoansGet(
        loanerId: secondLoaner.id,
        returned: any(named: 'returned'),
      ),
    ).called(greaterThan(0));

    // Re-selecting a loaner with loaded-but-empty active and history lists
    // exercises the auto-reload path; its item list is already populated.
    await tester.ensureVisible(find.text('Atelier'));
    await tester.tap(find.text('Atelier'));
    await settle(tester, frames: 20);

    // A loaded empty item list also triggers auto-load on selection, while
    // the empty loan/history lists take their corresponding reload branches.
    await tester.ensureVisible(find.text('Réserve'));
    await tester.tap(find.text('Réserve'));
    await settle(tester, frames: 20);
    expect(container.read(loanerIdProvider), emptyLoaner.id);
    await tester.ensureVisible(find.text('Réserve'));
    await tester.tap(find.text('Réserve'));
    await settle(tester, frames: 20);

    verify(
      () => scaffold.repository.loansLoanersLoanerIdItemsGet(
        loanerId: emptyLoaner.id,
      ),
    ).called(greaterThan(0));
    verify(
      () => scaffold.repository.loansLoanersLoanerIdLoansGet(
        loanerId: emptyLoaner.id,
        returned: any(named: 'returned'),
      ),
    ).called(greaterThan(0));
  });
}
