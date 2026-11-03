import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/providers/path_forwarding_provider.dart';

import '../../shared/app_scaffold.dart';

/// The mypayment main page's PAYMENT-RETURN listener: the HelloAsso redirect
/// comes back as `?code=succeeded` on the path-forwarding state, and the page
/// answers it by toasting the success and re-reading the wallet, the history
/// and the stores.
///
/// Two things are pinned, because both were silent failure modes:
///
///  * the toast fires ONCE per code — the listener is registered with
///    `ref.listen`, which re-runs on every forwarding change, so without the
///    handled-keys guard a user who then taps any module would see "Successful
///    payment" again;
///  * the three providers are re-read, not just the wallet: a top-up changes
///    the wallet AND the transaction history, and a stale history row is what
///    the user checks to believe the payment landed.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('a succeeded payment return toasts once and re-reads the '
      'wallet, history and stores', (tester) async {
    var walletCalls = 0;
    var historyCalls = 0;
    var storeCalls = 0;

    when(() => scaffold.repository.mypaymentUsersMeStoresGet())
        .thenAnswer((_) async {
          storeCalls++;
          return chopperListResponse(<UserStore>[]);
        });
    when(() => scaffold.repository.mypaymentUsersMeWalletGet())
        .thenAnswer((_) async {
          walletCalls++;
          return chopperResponse(
            Wallet.empty().copyWith(id: 'wallet-1', balance: 5000),
          );
        });
    when(() => scaffold.repository.mypaymentUsersMeTosGet()).thenAnswer(
      (_) async => chopperResponse(
        TOSSignatureResponse.empty().copyWith(
          acceptedTosVersion: 1,
          latestTosVersion: 1,
          maxWalletBalance: 100000,
        ),
      ),
    );
    when(() => scaffold.repository.mypaymentRequestsGet())
        .thenAnswer((_) async => chopperListResponse(<Request$>[]));
    when(() => scaffold.repository.mypaymentStructuresGet())
        .thenAnswer((_) async => chopperListResponse(<Structure>[]));
    when(() => scaffold.repository.mypaymentUsersMeWalletHistoryGet())
        .thenAnswer((_) async {
          historyCalls++;
          return chopperListResponse(<History>[]);
        });

    scaffold.setWideSurface(tester);
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/mypayment',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 20);

    final storesBefore = storeCalls;
    final walletBefore = walletCalls;
    final historyBefore = historyCalls;

    // The redirect returns to the page with the provider's code.
    container
        .read(pathForwardingProvider.notifier)
        .forward('/mypayment', queryParameters: {'code': 'succeeded'});
    await settle(tester, frames: 20);

    expect(find.text('Successful payment'), findsOneWidget);
    // All three are re-read, not just the wallet.
    expect(storeCalls, greaterThan(storesBefore));
    expect(walletCalls, greaterThan(walletBefore));
    expect(historyCalls, greaterThan(historyBefore));
    await scaffold.drainToast(tester);

    // A second forwarding change carrying the SAME code must not toast again:
    // the return is answered once, however many times the path changes.
    container
        .read(pathForwardingProvider.notifier)
        .forward('/mypayment', queryParameters: {'code': 'succeeded'});
    await settle(tester, frames: 20);

    expect(find.text('Successful payment'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
