import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/ui/pages/creation_edit_page/user_cash_ui.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/repository_test_support.dart' show chopperError;

/// The balance card's add-amount form (`/tombola/admin`): an empty amount is
/// refused by the validator, and a PATCH the backend rejects reports the
/// update error instead of silently doing nothing.
///
/// Own file for the deep-link rule (convention 11).
final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [
    CoreGroupSimple(
      name: 'admin_raffle',
      id: '0a25cb76-4b63-4fd3-b939-da6d9feabf28',
    ),
  ],
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the balance form validates then reports a refused update', (
    tester,
  ) async {
    when(() => scaffold.repository.tombolaRafflesGet())
        .thenAnswer((_) async => chopperListResponse(<RaffleComplete>[]));
    when(() => scaffold.repository.groupsGet())
        .thenAnswer((_) async => chopperResponse(<CoreGroupSimple>[]));
    when(() => scaffold.repository.tombolaUsersCashGet()).thenAnswer(
      (_) async => chopperListResponse([
        AppModulesRaffleSchemasRaffleCashComplete.empty().copyWith(
          userId: 'u-1',
          balance: 1000,
          user: CoreUserSimple.empty().copyWith(
            id: 'u-1',
            firstname: 'Anne',
            name: 'Martin',
          ),
        ),
      ]),
    );
    when(
      () => scaffold.repository.tombolaUsersUserIdCashPatch(
        userId: any(named: 'userId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperError<void>(500));

    scaffold.setWideSurface(tester);
    final container = scaffold.makeContainer(user: adminUser);
    addTearDown(container.dispose);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tombola/admin',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);
    expect(find.byType(UserCashUi), findsOneWidget);

    // Flip the card to its add-amount face.
    await tester.tap(find.byType(UserCashUi));
    await settle(tester, frames: 20);

    // Empty amount: the form refuses, nothing is sent.
    await tester.tap(
      find.descendant(
        of: find.byType(UserCashUi),
        matching: find.byIcon(Icons.add),
      ),
    );
    await settle(tester, frames: 8);
    expect(find.text('Add'), findsOneWidget);
    verifyNever(
      () => scaffold.repository.tombolaUsersUserIdCashPatch(
        userId: any(named: 'userId'),
        body: any(named: 'body'),
      ),
    );

    // A real amount: the PATCH is attempted and its refusal is reported.
    await tester.enterText(find.byType(TextFormField), '10');
    await settle(tester, frames: 4);
    await scaffold.unfocus(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(UserCashUi),
        matching: find.byIcon(Icons.add),
      ),
    );
    await settle(tester, frames: 20);

    verify(
      () => scaffold.repository.tombolaUsersUserIdCashPatch(
        userId: 'u-1',
        body: any(named: 'body'),
      ),
    ).called(1);
    expect(find.text('Error during update'), findsOneWidget);
    await scaffold.drainToast(tester);
  });
}
