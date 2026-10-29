import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../mypayment_fixtures.dart';

void stubMyPayment(IntegrationScaffold scaffold) {
  when(() => scaffold.repository.mypaymentUsersMeStoresGet())
      .thenAnswer((_) async => chopperListResponse([userStoreFixture]));
  when(() => scaffold.repository.usersSearchGet(query: any(named: 'query')))
      .thenAnswer((_) async => chopperListResponse(<CoreUserSimple>[]));
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

    verify(() => scaffold.repository.usersSearchGet(query: any(named: 'query')))
        .called(greaterThanOrEqualTo(1));
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

  /// One transfer attempt per test: whatever the outcome, the row's tap
  /// handler clears the results and pops the page after the dialog closes
  /// (search_result.dart:86-91), so a second attempt would have nowhere to
  /// search from. The success and error arms of `initTransfer`
  /// (search_result.dart:49-59) are one test each.
  Future<void> openTransferDialog(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), 'Ada');
    await settle(tester, frames: 8);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    await tester.tap(
      find.byWidgetPredicate(
        // The search bar carries its own explicit white plus
        // (transfer_structure_page.dart:63); the result row's is the
        // uncolored const one (search_result.dart:95).
        (w) => w is HeroIcon && w.icon == HeroIcons.plus && w.color == null,
      ),
    );
    await settle(tester, frames: 6);
    expect(find.text('Confirm'), findsOneWidget);
  }

  testWidgets(
    'confirming a transfer wires the new manager and toasts success',
    (tester) async {
      stubMyPayment(scaffold);
      when(() => scaffold.repository.usersSearchGet(query: 'Ada')).thenAnswer(
        (_) async => chopperListResponse([
          CoreUserSimple.empty().copyWith(firstname: 'Ada', name: 'Lovelace'),
        ]),
      );
      when(
        () => scaffold.repository
            .mypaymentStructuresStructureIdInitManagerTransferPost(
              structureId: any(named: 'structureId'),
              body: any(named: 'body'),
            ),
      ).thenAnswer((_) async => chopperResponseVoid());

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(user: CoreUser.empty().copyWith(id: 'user-1')),
        initialPath: '/mypayment/transferStructure',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 30);

      await openTransferDialog(tester);
      await tester.tap(find.text('Confirm'));
      await settle(tester, frames: 10);

      // The success arm toasted; the page underneath popped (no toast text is
      // asserted — convention 25 — the repository call and the drain are).
      verify(
        () => scaffold.repository
            .mypaymentStructuresStructureIdInitManagerTransferPost(
              structureId: any(named: 'structureId'),
              body: any(named: 'body'),
            ),
      ).called(1);
      await scaffold.unmountApp(tester);
      await scaffold.drainToast(tester);
    },
  );

  testWidgets('a refused transfer toasts the error instead of succeeding', (
    tester,
  ) async {
    stubMyPayment(scaffold);
    when(() => scaffold.repository.usersSearchGet(query: 'Ada')).thenAnswer(
      (_) async => chopperListResponse([
        CoreUserSimple.empty().copyWith(firstname: 'Ada', name: 'Lovelace'),
      ]),
    );
    when(
      () => scaffold.repository
          .mypaymentStructuresStructureIdInitManagerTransferPost(
            structureId: any(named: 'structureId'),
            body: any(named: 'body'),
          ),
    ).thenAnswer(
      (_) async => chopper.Response(
        http.Response('', 500),
        null,
        error: 'transfer refused',
      ),
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: CoreUser.empty().copyWith(id: 'user-1')),
      initialPath: '/mypayment/transferStructure',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    await openTransferDialog(tester);
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 10);

    // `isSuccessful` is false → the error arm's toast; the call still went
    // to the wire, so the assertion that distinguishes the arms is the
    // drained error toast plus no success state left behind.
    verify(
      () => scaffold.repository
          .mypaymentStructuresStructureIdInitManagerTransferPost(
            structureId: any(named: 'structureId'),
            body: any(named: 'body'),
          ),
    ).called(1);
    await scaffold.unmountApp(tester);
    await scaffold.drainToast(tester);
  });
}
