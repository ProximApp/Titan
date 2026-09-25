import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/has_accepted_tos_provider.dart';
import 'package:titan/tools/ui/heroicons.dart';

import 'app_scaffold.dart';

chopper.Response<T> chopperResponse<T>(T body) =>
    chopper.Response(http.Response('body', 200), body);

chopper.Response<List<T>> chopperListResponse<T>(List<T> body) =>
    chopper.Response(http.Response('body', 200), body);

Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Wallet wallet(int balance) => Wallet.empty().copyWith(balance: balance);

History history(String id, HistoryDirection direction, int total) =>
    History.empty().copyWith(
      id: id,
      type: HistoryType.directTransaction,
      direction: direction,
      otherWalletName: 'BDE',
      total: total,
      creation: DateTime(2026, 1, 5, 12, 30),
      status: TransactionStatus.confirmed,
    );

TOSSignatureResponse tos() => TOSSignatureResponse.empty().copyWith(
  acceptedTosVersion: 0,
  latestTosVersion: 0,
  tosContent: 'Some terms',
);

Structure structure(String userId) => Structure.empty().copyWith(
  managerUserId: userId,
  // myStructuresProvider matches on managerUser.id, not managerUserId.
  managerUser: CoreUserSimple.empty().copyWith(id: userId),
);

void stubMyPayment(IntegrationScaffold scaffold, {List<History>? historyList}) {
  when(
    () => scaffold.repository.mypaymentUsersMeWalletGet(),
  ).thenAnswer((_) async => chopperResponse(wallet(2510)));
  when(
    () => scaffold.repository.mypaymentUsersMeStoresGet(),
  ).thenAnswer((_) async => chopperListResponse(<UserStore>[]));
  when(
    () => scaffold.repository.mypaymentUsersMeTosGet(),
  ).thenAnswer((_) async => chopperResponse(tos()));
  when(
    () => scaffold.repository.mypaymentRequestsGet(),
  ).thenAnswer((_) async => chopperListResponse(<Request$>[]));
  when(
    () => scaffold.repository.mypaymentStructuresGet(),
  ).thenAnswer((_) async => chopperListResponse(<Structure>[]));
  when(
    () => scaffold.repository.mypaymentUsersMeWalletHistoryGet(),
  ).thenAnswer((_) async => chopperListResponse(historyList ?? <History>[]));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IntegrationScaffold scaffold;

  setUp(() {
    QR.reset();
    SharedPreferences.setMockInitialValues({});
    scaffold = IntegrationScaffold();
    scaffold.stubInformation();
    scaffold.stubFeed();
  });

  group('MyPayment main page', () {
    // NOTE on ordering: qlevar_router 1.12.4 silently drops the first
    // mid-test QR.to() to a route that is not yet mounted when an earlier
    // test already ran in the same isolate. The navigation test is kept
    // first; the remaining tests only assert on already-mounted routes.
    testWidgets('stats card button navigates to the stats page', (
      tester,
    ) async {
      stubMyPayment(
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
    });

    testWidgets('renders the wallet balance and the latest transactions', (
      tester,
    ) async {
      stubMyPayment(
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
      stubMyPayment(scaffold);
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

    testWidgets('flip card shows the store card for structure admins', (
      tester,
    ) async {
      stubMyPayment(scaffold);
      when(
        () => scaffold.repository.mypaymentStructuresGet(),
      ).thenAnswer((_) async => chopperListResponse([structure('user-1')]));

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
}
