import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/loan/router.dart';
import 'package:titan/loan/ui/pages/admin_page/loan_card.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../loan_fixtures.dart';

/// The user main page's ongoing strip paints `LoanCard` without handlers, and
/// that card's info button is the only affordance: it seeds the loan and
/// routes to the user-side detail. The populated test only ever tapped the
/// info button of a RETURNED card, so this arm stayed dark.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the ongoing card opens its own loan detail', (tester) async {
    final loaner = loanerFixture(
      id: 'loaner-1',
      name: 'Asso Matériel',
      groupManagerId: 'grp-1',
    );
    final ongoing = loanFixture(
      id: 'l-1',
      borrower: coreUserSimpleFixture(
        id: 'u-1',
        firstname: 'Jane',
        name: 'Doe',
      ),
      loaner: loaner,
      notes: 'Return before Friday',
      returned: false,
    );
    final other = loanFixture(
      id: 'l-2',
      borrower: coreUserSimpleFixture(id: 'u-2', firstname: 'John', name: 'S'),
      loaner: loaner,
      notes: 'Another ongoing loan',
      returned: false,
    );

    final container = scaffold.makeContainer(myLoaners: [loaner]);
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    when(() => scaffold.repository.loansUsersMeGet())
        .thenAnswer((_) async => chopperListResponse([ongoing, other]));
    when(() => scaffold.repository.loansUsersMeLoanersGet())
        .thenAnswer((_) async => chopperListResponse([loaner]));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: LoanRouter.root,
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);
    expect(find.byType(LoanCard), findsNWidgets(2));

    // Each card carries its own info button; the first one must open ITS loan.
    final info = find.byWidgetPredicate(
      (w) => w is HeroIcon && w.icon == HeroIcons.informationCircle,
    );
    expect(info, findsNWidgets(2));
    await tester.tap(info.first);
    await settle(tester, frames: 30);

    expect(find.textContaining('Return before Friday'), findsOneWidget);
    expect(find.textContaining('Another ongoing loan'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
