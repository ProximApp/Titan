import 'package:flutter/material.dart' show Offset;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/loan/router.dart';
import 'package:titan/loan/ui/pages/admin_page/loan_card.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../../shared/app_scaffold.dart';
import '../loan_fixtures.dart';

/// The populated halves of the loan main page, which the empty-state shell
/// never reaches: the ongoing and returned sections only render once
/// `loansUsersMeGet` answers with data, and both sort and split by
/// `Loan.returned` before painting the two horizontal lists.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'a populated loan list splits ongoing and returned loans and opens the detail',
    (tester) async {
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
      final returned = loanFixture(
        id: 'l-2',
        borrower: coreUserSimpleFixture(
          id: 'u-2',
          firstname: 'John',
          name: 'Smith',
        ),
        loaner: loaner,
        notes: 'Brought it back on time',
        returned: true,
        returnedDate: DateTime(2026, 1, 9),
      );

      final container = scaffold.makeContainer(myLoaners: [loaner]);
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      // The refresh answers a different list, so the pull-to-refresh is not
      // only exercised — it visibly changes what the page paints.
      var loans = <Loan>[ongoing, returned];
      when(() => scaffold.repository.loansUsersMeGet())
          .thenAnswer((_) async => chopperListResponse(loans));
      when(() => scaffold.repository.loansUsersMeLoanersGet())
          .thenAnswer((_) async => chopperListResponse([loaner]));

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: LoanRouter.root,
        pumpAndSettle: false,
      );
      await settle(tester, frames: 30);

      // One loan in each section, each with its own count header.
      expect(find.textContaining('1 loan ongoing'), findsOneWidget);
      expect(find.textContaining('1 loan returned'), findsOneWidget);
      expect(find.byType(LoanCard), findsNWidgets(2));

      // Pull-to-refresh reloads the list: the ongoing loan is gone from the
      // backend answer, so the ongoing section disappears (the placeholder
      // branch takes its place) while the returned one stays.
      loans = [returned];
      await tester.drag(find.byType(Refresher), const Offset(0, 1500));
      await settle(tester, frames: 30);
      verify(() => scaffold.repository.loansUsersMeGet()).called(2);
      expect(find.textContaining('1 loan ongoing'), findsNothing);
      expect(find.textContaining('1 loan returned'), findsOneWidget);
      expect(find.byType(LoanCard), findsOneWidget);

      // The card's own onTap only routes when isAdmin/isHistory, so a plain
      // tap on the card must NOT navigate.
      await tester.tap(find.byType(LoanCard));
      await settle(tester, frames: 10);
      expect(find.byType(LoanCard), findsOneWidget);

      final info = find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.informationCircle,
      );
      expect(info, findsOneWidget);
      await tester.tap(info);
      await settle(tester, frames: 30);

      expect(
        find.textContaining('Brought it back on time'),
        findsOneWidget,
        reason: 'the info icon must have opened ITS loan',
      );
    },
  );
}
