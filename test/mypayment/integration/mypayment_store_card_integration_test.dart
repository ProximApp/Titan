import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../mypayment_fixtures.dart';

/// The store face of the payment main page (`StoreCard`).
///
/// Its three routing buttons are gated on rights the shop owner gets per
/// store — manage the sellers, read the history, hand the structure over —
/// and every existing test booted a store that had none of them, so none of
/// the three buttons had ever been rendered, let alone tapped. Each test here
/// boots a store the member really runs and asserts the route the button asks
/// for, one journey per test (convention 10).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> bootStoreFace(WidgetTester tester) async {
    stubMainPage(
      scaffold,
      structures: [structureFixture('structure-1', 'BDE', 'user-1')],
      userStores: [managedStoreFixture()],
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: CoreUser.empty().copyWith(id: 'user-1')),
      initialPath: '/mypayment',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    // The account card boots face-up; the store card is one flip away.
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.arrowsRightLeft,
      ),
      warnIfMissed: false,
    );
    await settle(tester, frames: 16);
    expect(find.text('Store balance'), findsOneWidget);
  }

  Finder iconButton(HeroIcons icon) =>
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == icon);

  testWidgets('the sellers button opens the store admin page', (tester) async {
    await bootStoreFace(tester);

    await tester.tap(iconButton(HeroIcons.userGroup), warnIfMissed: false);
    await settle(tester, frames: 16);

    expect(QR.currentPath, '/mypayment/storeAdmin');
  });

  testWidgets('the history button opens the store stats page', (tester) async {
    await bootStoreFace(tester);

    await tester.tap(iconButton(HeroIcons.wallet), warnIfMissed: false);
    await settle(tester, frames: 16);

    expect(QR.currentPath, '/mypayment/storeStats');
  });

  testWidgets('the hand-over button opens the transfer form', (tester) async {
    await bootStoreFace(tester);

    await tester.tap(iconButton(HeroIcons.users), warnIfMissed: false);
    await settle(tester, frames: 16);

    expect(QR.currentPath, '/mypayment/transferStructure');
  });
}
