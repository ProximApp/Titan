import 'dart:ui' as ui;

import 'package:chopper/chopper.dart' as chopper;
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';
import '../mypayment_fixtures.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';
import 'package:titan/mypayment/ui/pages/request_history_page/request_history_page.dart';

Request$ request(String id, String name, RequestStatus status, int total) =>
    Request$(
      id: id,
      walletId: 'wallet-1',
      creation: DateTime(2026, 1, 5, 12, 30),
      expirationDate: DateTime(2026, 12, 31),
      total: total,
      storeId: 'store-1',
      name: name,
      module: 'mypayment',
      objectId: 'object-1',
      status: status,
    );

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('request history page lists the past requests', (tester) async {
    stubUsedRequests(
      scaffold,
      requests: [request('r-1', 'Soda', RequestStatus.accepted, 500)],
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/mypayment/requestHistory',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    expect(find.text('Activities'), findsOneWidget);
    // The request card renders the request name and its amount (fr locale).
    expect(find.text('Soda'), findsOneWidget);
    expect(find.textContaining('5,00'), findsWidgets);
  });

  testWidgets('request history page shows the empty message with no request', (
    tester,
  ) async {
    stubUsedRequests(scaffold);

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/mypayment/requestHistory',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    expect(find.text('No payment requests'), findsOneWidget);
  });

  testWidgets('pull to refresh reloads the paid requests', (tester) async {
    when(
      () => scaffold.repository.mypaymentRequestsGet(
        used: any(named: 'used'),
      ),
    ).thenAnswer((_) async => chopperListResponse(<Request$>[]));

    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'user-1'),
    );
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(tester, const RequestHistoryPage(), container);
    await settle(tester, frames: 20);

    clearInteractions(scaffold.repository);
    await tester.drag(find.byType(Refresher).first, const Offset(0, 400));
    await settle(tester, frames: 24);

    verify(() => scaffold.repository.mypaymentRequestsGet(used: true)).called(1);
  });

  testWidgets('a live proposal opens the payment sheet and reloads on close', (
    tester,
  ) async {
    // The payment sheet only fits on a phone-tall viewport; the default test
    // surface clips its buttons.
    tester.view.physicalSize = const ui.Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    stubUsedRequests(
      scaffold,
      requests: [request('r-1', 'Soda', RequestStatus.proposed, 500)],
    );
    final proposal = request('r-1', 'Soda', RequestStatus.proposed, 500);
    when(
      () => scaffold.repository.mypaymentRequestsGet(),
    ).thenAnswer((_) async => chopperListResponse([proposal]));
    when(
      () => scaffold.repository.mypaymentRequestsRequestIdRefusePost(
        requestId: any(named: 'requestId'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/mypayment/requestHistory',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    // A proposed, still-valid request is the only card that opens the payment
    // sheet; the accepted one in the first test goes to the read-only detail.
    await tester.tap(find.text('Soda'));
    await settle(tester, frames: 30);
    expect(find.text('Confirm your purchase'), findsOneWidget);

    await tester.tap(find.text('Refuse'));
    await settle(tester, frames: 40);

    expect(find.text('Confirm your purchase'), findsNothing);
    expect(find.text('Payment request refused'), findsOneWidget);
    // The page reloads once the sheet closes, so the card shows the new status.
    verify(
      () => scaffold.repository.mypaymentRequestsGet(used: true),
    ).called(2);

    // The toast arms a 2.5s PausableTimer for its auto-close; step frames so
    // the test does not end with it pending.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  });


  testWidgets('confirming without a device key is refused on the spot', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final proposal = request('r-1', 'Soda', RequestStatus.proposed, 500);
    stubUsedRequests(scaffold, requests: [proposal]);
    when(
      () => scaffold.repository.mypaymentRequestsGet(),
    ).thenAnswer((_) async => chopperListResponse([proposal]));

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(deviceKeyId: null),
      initialPath: '/mypayment/requestHistory',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    await tester.tap(find.text('Soda'));
    await settle(tester, frames: 30);
    await tester.tap(find.text('Confirm Payment'));
    await settle(tester, frames: 30);

    // No key on this device: nothing is signed, nothing is accepted, and the
    // sheet closes with the reason.
    expect(find.text('Confirm your purchase'), findsNothing);
    expect(find.text('Error processing payment request'), findsOneWidget);
    verifyNever(
      () => scaffold.repository.mypaymentRequestsRequestIdAcceptPost(
        requestId: any(named: 'requestId'),
        body: any(named: 'body'),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  });

  testWidgets('a refused acceptance says so and closes the sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final proposal = request('r-1', 'Soda', RequestStatus.proposed, 500);
    stubUsedRequests(scaffold, requests: [proposal]);
    when(
      () => scaffold.repository.mypaymentRequestsGet(),
    ).thenAnswer((_) async => chopperListResponse([proposal]));
    when(
      () => scaffold.repository.mypaymentRequestsRequestIdAcceptPost(
        requestId: any(named: 'requestId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response(http.Response('{"detail": "no"}', 400), null),
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(deviceKeyId: 'device-1'),
      initialPath: '/mypayment/requestHistory',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    await tester.tap(find.text('Soda'));
    await settle(tester, frames: 30);
    await tester.tap(find.text('Confirm Payment'));
    await settle(tester, frames: 40);

    // The signature was made, the backend refused it: same error copy, no
    // success callback, and the sheet is gone either way.
    expect(find.text('Confirm your purchase'), findsNothing);
    expect(find.text('Error processing payment request'), findsOneWidget);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  });


  testWidgets('a refused refusal says so with the same copy', (tester) async {
    tester.view.physicalSize = const ui.Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final proposal = request('r-1', 'Soda', RequestStatus.proposed, 500);
    stubUsedRequests(scaffold, requests: [proposal]);
    when(
      () => scaffold.repository.mypaymentRequestsGet(),
    ).thenAnswer((_) async => chopperListResponse([proposal]));
    when(
      () => scaffold.repository.mypaymentRequestsRequestIdRefusePost(
        requestId: any(named: 'requestId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response(http.Response('{"detail": "no"}', 400), null),
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/mypayment/requestHistory',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    await tester.tap(find.text('Soda'));
    await settle(tester, frames: 30);
    await tester.tap(find.text('Refuse'));
    await settle(tester, frames: 40);

    expect(find.text('Confirm your purchase'), findsNothing);
    expect(find.text('Error processing payment request'), findsOneWidget);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  });

}
