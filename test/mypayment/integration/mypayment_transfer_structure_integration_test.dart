import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

void stubMyPayment(IntegrationScaffold scaffold) {
  when(
    () => scaffold.repository.mypaymentUsersMeStoresGet(),
  ).thenAnswer((_) async => chopperListResponse([myPaymentStore]));
  when(
    () => scaffold.repository.usersSearchGet(query: any(named: 'query')),
  ).thenAnswer((_) async => chopperListResponse(<CoreUserSimple>[]));
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('transfer structure page renders the accountable search', (
    tester,
  ) async {
    stubMyPayment(scaffold);

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: CoreUser.empty().copyWith(id: 'user-1')),
      initialPath: '/mypayment/transferStructure',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    expect(find.text('Next responsible'), findsOneWidget);

    // Typing a query hits the user search endpoint and renders results.
    await tester.enterText(find.byType(TextField), 'Ada');
    await settle(tester, frames: 6);

    verify(
      () => scaffold.repository.usersSearchGet(query: any(named: 'query')),
    ).called(greaterThanOrEqualTo(1));
  });

  testWidgets('transfer structure page lists the search results', (
    tester,
  ) async {
    stubMyPayment(scaffold);
    // Stubbed after stubMyPayment on purpose: mocktail keeps the last
    // matching stub, and this one must win over the empty-list default.
    when(() => scaffold.repository.usersSearchGet(query: 'Ada')).thenAnswer(
      (_) async => chopperListResponse([
        CoreUserSimple.empty().copyWith(firstname: 'Ada', name: 'Lovelace'),
      ]),
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: CoreUser.empty().copyWith(id: 'user-1')),
      initialPath: '/mypayment/transferStructure',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    await tester.enterText(find.byType(TextField), 'Ada');
    await settle(tester, frames: 8);

    // The search result row renders the user's name (getName():
    // "firstname name" when there is no nickname).
    expect(find.text('Ada Lovelace'), findsOneWidget);
  });
}
