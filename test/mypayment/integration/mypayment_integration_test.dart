import 'dart:async';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/has_accepted_tos_provider.dart';
import 'package:titan/mypayment/providers/payment_requests_provider.dart';
import 'package:titan/mypayment/providers/should_display_tos_dialog.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../mypayment_fixtures.dart';

import 'dart:ui' as ui;

import 'package:titan/tools/ui/layouts/refresher.dart';
import 'package:titan/mypayment/ui/pages/main_page/main_page.dart';

Structure managerStructure(String userId) => Structure.empty().copyWith(
  managerUserId: userId,
  // myStructuresProvider matches on managerUser.id, not managerUserId.
  managerUser: CoreUserSimple.empty().copyWith(id: userId),
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  group('MyPayment main page', () {
    // NOTE on ordering: qlevar_router 1.12.4 silently drops the first
    // mid-test QR.to() to a route that is not yet mounted when an earlier
    // test already ran in the same isolate. The navigation test is kept
    // first; the remaining tests only assert on already-mounted routes.
    testWidgets('stats card button navigates to the stats page', (
      tester,
    ) async {
      stubMainPage(
        scaffold,
        historyList: [history('h-1', HistoryDirection.debited, 250)],
      );

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(),
        initialPath: '/mypayment',
      );
      await settle(tester);

      // The tappable surface is the WaitingButton wrapping the icon; the
      // label sits below it as a sibling, outside the hit target.
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.chartPie,
        ),
      );
      await settle(tester, frames: 16);

      expect(QR.currentPath, '/mypayment/stats');
      // The month bar renders the current month's total (fr locale, ʍ
      // currency) — proof the stats page itself mounted, not just that the
      // route changed.
      expect(find.textContaining('ʍ'), findsWidgets);
    });

    testWidgets('renders the wallet balance and the latest transactions', (
      tester,
    ) async {
      stubMainPage(
        scaffold,
        historyList: [
          history('h-1', HistoryDirection.debited, 250),
          history('h-2', HistoryDirection.credited, 1000),
        ],
      );

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(),
        initialPath: '/mypayment',
      );
      await settle(tester);

      expect(find.text('Personal balance'), findsOneWidget);
      // AccountCard formats balance/100 with the ʍ currency symbol in the
      // fr locale (the app default).
      expect(find.textContaining('25,10'), findsOneWidget);
      expect(find.textContaining('ʍ'), findsWidgets);
      expect(find.text('Latest transactions'), findsOneWidget);
      expect(find.text('BDE'), findsWidgets);
      // Only the credited transaction carries a "+" sign.
      expect(find.textContaining('+ 10,00'), findsOneWidget);
    });

    testWidgets('shows the TOS acceptance page when versions differ', (
      tester,
    ) async {
      stubMainPage(scaffold);
      when(() => scaffold.repository.mypaymentUsersMeTosGet()).thenAnswer(
        (_) async => chopperResponse(
          tos().copyWith(acceptedTosVersion: 0, latestTosVersion: 2),
        ),
      );
      Future<chopper.Response<TOSSignatureResponse>> tosPostAnswer(_) async =>
          chopperResponse(tos());
      when(
        () => scaffold.repository.mypaymentUsersMeTosPost(
          body: any(named: 'body'),
        ),
      ).thenAnswer(tosPostAnswer);

      final container = scaffold.makeContainer();
      // hasAcceptedTosProvider is autoDispose and nothing listens to it
      // while the TOS branch is up, but the app still updates it after the
      // accept round-trip; hold a listener so the update lands on a live
      // notifier instead of a disposed one.
      container.listen(hasAcceptedTosProvider, (_, _) {});

      await scaffold.pumpApp(tester, container, initialPath: '/mypayment');
      await settle(tester);

      expect(find.text('New Terms of Service'), findsOneWidget);
      expect(find.textContaining('Some terms'), findsOneWidget);

      await tester.tap(find.text('Accept'));
      await settle(tester, frames: 16);

      verify(
        () => scaffold.repository.mypaymentUsersMeTosPost(
          body: any(named: 'body'),
        ),
      ).called(1);
      // The dialog is dismissed and the account branch mounts.
      expect(find.text('Personal balance'), findsOneWidget);
    });

    testWidgets('a terms dialog raised before the terms land accepts nothing', (
      tester,
    ) async {
      stubMainPage(scaffold);
      // The terms read never answers, and the flag that mounts the dialog is
      // pinned on. That is the one state where the dialog exists while
      // `tosProvider` is still loading — the `orElse` arms of the description
      // and of the accept handler.
      when(() => scaffold.repository.mypaymentUsersMeTosGet()).thenAnswer(
        (_) => Completer<chopper.Response<TOSSignatureResponse>>().future,
      );
      final container = scaffold.makeContainer(
        providerOverrides: [
          shouldDisplayTosDialogProvider.overrideWith(
            () => FakeShouldDisplayTosDialog(true),
          ),
        ],
      );
      container.listen(hasAcceptedTosProvider, (_, _) {});

      await scaffold.pumpApp(tester, container, initialPath: '/mypayment');
      await settle(tester);

      // The dialog is up with an empty description: there is no terms text to
      // quote yet.
      expect(find.text('New Terms of Service'), findsOneWidget);
      expect(find.textContaining('Some terms'), findsNothing);

      await tester.tap(find.text('Accept'));
      await settle(tester, frames: 16);

      // Nothing was signed (no version to accept), and the dialog stays up
      // rather than claiming an acceptance that never happened.
      verifyNever(
        () => scaffold.repository.mypaymentUsersMeTosPost(
          body: any(named: 'body'),
        ),
      );
      expect(find.text('New Terms of Service'), findsOneWidget);
    });

    testWidgets('a proposed request pops the payment sheet on its own', (
      tester,
    ) async {
      tester.view.physicalSize = const ui.Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final pending = Request$(
        id: 'r-1',
        walletId: 'wallet-1',
        creation: DateTime(2026, 1, 5, 12, 30),
        expirationDate: DateTime.now().add(const Duration(hours: 2)),
        total: 500,
        storeId: 'store-1',
        name: 'Soda',
        module: 'mypayment',
        objectId: 'object-1',
        status: RequestStatus.proposed,
      );
      stubMainPage(scaffold, requests: [pending]);
      // A fresh list per read, so the reload is a NEW AsyncData: an identical
      // one would be equal and the sweep would not re-run.
      when(() => scaffold.repository.mypaymentRequestsGet())
          .thenAnswer((_) async => chopperListResponse([pending]));

      final container = scaffold.makeContainer();
      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/mypayment',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 40);

      // Nobody tapped anything: the page sweeps its requests, finds this one
      // live, and opens the sheet itself.
      expect(find.text('Confirm your purchase'), findsOneWidget);
      expect(find.text('Soda'), findsWidgets);

      // A reload of the requests (what accepting/refusing elsewhere does)
      // re-runs the sweep over the ids it already showed. This one is STILL
      // proposed, so the sweep has to re-check its expiry instead of
      // short-circuiting.
      container.refresh(paymentRequestsProvider);
      await settle(tester, frames: 20);
      expect(find.text('Confirm your purchase'), findsOneWidget);
    });

    testWidgets('flip card shows the store card for structure admins', (
      tester,
    ) async {
      stubMainPage(scaffold);
      when(() => scaffold.repository.mypaymentStructuresGet()).thenAnswer(
        (_) async => chopperListResponse([managerStructure('user-1')]),
      );

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(user: CoreUser.empty().copyWith(id: 'user-1')),
        initialPath: '/mypayment',
      );
      await settle(tester);

      // The account card is up front; the store card is on the back face.
      expect(find.text('Personal balance'), findsOneWidget);
      expect(find.text('Store balance'), findsNothing);

      // The toggle icon drives the flip animation from the account face to
      // the store face.
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.arrowsRightLeft,
        ),
      );
      await settle(tester, frames: 16);

      expect(find.text('Store balance'), findsOneWidget);
      expect(find.text('Personal balance'), findsNothing);
    });
  });

  testWidgets('pull to refresh reloads the stores and the wallet', (
    tester,
  ) async {
    stubMainPage(scaffold);
    when(() => scaffold.repository.mypaymentUsersMeStoresGet())
        .thenAnswer((_) async => chopperListResponse(<UserStore>[]));

    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'user-1'),
    );
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      const PaymentMainPage(),
      container,
      surface: const ui.Size(1920, 1080),
    );
    await settle(tester, frames: 20);

    clearInteractions(scaffold.repository);
    await tester.drag(find.byType(Refresher).first, const Offset(0, 400));
    await settle(tester, frames: 24);

    verify(() => scaffold.repository.mypaymentUsersMeStoresGet()).called(1);
    verify(() => scaffold.repository.mypaymentUsersMeWalletGet())
        .called(greaterThan(0));
  });

  testWidgets('pull to refresh reloads the wallet history behind the chart', (
    tester,
  ) async {
    stubMainPage(scaffold);

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: CoreUser.empty().copyWith(id: 'user-1')),
      initialPath: '/mypayment/stats',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    clearInteractions(scaffold.repository);
    await tester.drag(find.byType(Refresher).first, const Offset(0, 400));
    await settle(tester, frames: 24);

    verify(() => scaffold.repository.mypaymentUsersMeWalletHistoryGet())
        .called(1);
  });
}
