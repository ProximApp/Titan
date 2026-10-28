import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderContainer;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/amap/providers/user_amount_provider.dart';
import 'package:titan/amap/ui/components/order_ui.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The amap main page with an ORDER ON IT: every callback the order row
/// exposes (card tap, edit pencil, delete trash), the slide-up order panel's
/// open/close, the "+" card and the page's own pull-to-refresh — the
/// populated-order half `amap_integration_test.dart` renders but never
/// presses, because it asserts only on rendered text.
///
/// Two tests, both booting the SAME path: the navigation one runs first
/// (conventions 2 and 11), the mutating one never leaves /amap
/// (convention 10).
AppModulesAmapSchemasAmapCashComplete cash(int balance) =>
    AppModulesAmapSchemasAmapCashComplete.empty().copyWith(
      balance: balance,
      userId: 'user-1',
    );

DeliveryReturn orderableDelivery(String id, int productCount) =>
    DeliveryReturn.empty().copyWith(
      id: id,
      name: 'Delivery $id',
      deliveryDate: DateTime(2100, 12, 31),
      status: DeliveryStatusType.orderable,
      products: List.generate(
        productCount,
        (i) => AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
          id: 'p-$i',
          name: 'Product $i',
        ),
      ),
    );

OrderReturn order(String orderId, String deliveryId, int amount) =>
    OrderReturn.empty().copyWith(
      orderId: orderId,
      deliveryId: deliveryId,
      amount: amount,
      deliveryDate: DateTime(2100, 12, 31),
      orderingDate: DateTime(2100),
    );

void main() {
  late IntegrationScaffold scaffold;
  late int orderFetches;
  late ProviderContainer container;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();

    orderFetches = 0;
    when(
      () => scaffold.repository.amapUsersUserIdCashGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => chopperResponse(cash(2510)));
    when(() => scaffold.repository.amapDeliveriesGet()).thenAnswer(
      (_) async => chopperListResponse([orderableDelivery('d-1', 2)]),
    );
    // The cash LIST is what `updateCash` writes through after a delete: it
    // refuses (before the PATCH) unless its state holds the user's entry.
    when(() => scaffold.repository.amapUsersCashGet())
        .thenAnswer((_) async => chopperListResponse([cash(2510)]));
    when(
      () => scaffold.repository.amapUsersUserIdOrdersGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async {
      orderFetches++;
      return chopperListResponse([order('o-1', 'd-1', 500)]);
    });
    when(
      () => scaffold.repository.amapOrdersOrderIdDelete(
        orderId: any(named: 'orderId'),
      ),
    ).thenAnswer((_) async => scaffold.repository.okVoid());
    when(
      () => scaffold.repository.amapUsersUserIdCashPatch(
        userId: any(named: 'userId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => scaffold.repository.okVoid());
  });

  Future<void> pumpOrdersPage(WidgetTester tester) async {
    container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'user-1'),
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    ignoreAmapKnownQuirks();
    await scaffold.pumpApp(tester, container, initialPath: '/amap');
    await settle(tester, frames: 16);
    expect(find.byType(OrderUI), findsOneWidget);
  }

  testWidgets('the order card opens the order detail', (tester) async {
    await pumpOrdersPage(tester);

    // The navigation handler hangs off the card's info button, not the card
    // body — tapping the card centre lands on nothing.
    await tester.tap(
      find.descendant(
        of: find.byType(OrderUI),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.informationCircle,
        ),
      ),
    );
    await settle(tester, frames: 15);

    expect(QR.currentPath, contains('detail'));
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('refresh, panel open/close, edit and delete round trip', (
    tester,
  ) async {
    await pumpOrdersPage(tester);

    // 1. Pull-to-refresh: the page's own onRefresh reloads all three lists.
    await tester.dragFrom(
      tester.getTopLeft(find.byType(OrderUI)) - const Offset(0, 60),
      const Offset(0, 300),
    );
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(orderFetches, greaterThan(1), reason: 'the refresh must reload');

    // 2. The "+" card seeds an empty order and slides the panel up; the
    //    panel's X closes it again.
    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus),
    );
    await settle(tester, frames: 12);
    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.xMark),
    );
    await settle(tester, frames: 12);
    expect(tester.takeException(), isNull);

    // 3. The pencil on the order card edits it into the same panel.
    await tester.tap(
      find.descendant(
        of: find.byType(OrderUI),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.pencil,
        ),
      ),
    );
    await settle(tester, frames: 12);
    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.xMark),
    );
    await settle(tester, frames: 12);

    // 4. The trash opens the confirm dialog; confirming runs the real DELETE
    //    plus the cash refund and its success toast.
    await tester.tap(
      find.descendant(
        of: find.byType(OrderUI),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.trash,
        ),
      ),
    );
    await settle(tester, frames: 10);
    expect(find.text('Confirm'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 15);

    verify(() => scaffold.repository.amapOrdersOrderIdDelete(orderId: 'o-1'))
        .called(1);
    // The refund lands in the LOCAL balance state (`userAmountProvider`)
    // — this path issues no PATCH.
    expect(container.read(userAmountProvider).value?.balance, 3010);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
    await scaffold.drainToast(tester);
  });
}
