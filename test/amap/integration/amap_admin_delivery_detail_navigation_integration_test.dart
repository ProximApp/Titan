import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../amap_fixtures.dart';

/// The admin delivery card's open-in-new icon: it selects the delivery,
/// seeds the product list and navigates to the delivery detail page. The
/// second test covers the card's order loader error arm, which replaces the
/// order count with the admin error label.
///
/// The navigation test runs FIRST: qlevar drops later mid-test QR.to() calls
/// to not-yet-mounted routes once an earlier test ran in the isolate.
///
/// The detail page is opened on a delivery with NO products: its fixed
/// 100px-tall ProductDetailCard overflows by 3px under the integration
/// harness' font metrics, and the card's own rendering is covered by
/// test/amap/widget/amap_detail_pages_widget_test.dart.
///
/// The page's pull-to-refresh (its `Refresher` onRefresh body) is NOT
/// exercised here: a product-less delivery renders a page shorter than the
/// viewport, so the sliver never overscrolls and the drag cannot arm the
/// refresh control.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pumpAdmin(WidgetTester tester) async {
    final container = scaffold.makeContainer(
      user: amapAdminUser,
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/amap/admin',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);
  }

  testWidgets('the open-in-new icon opens the delivery detail page', (
    tester,
  ) async {
    stubAdminLoads(
      scaffold,
      deliveries: [orderableDelivery('d-1', 0)],
      ordersByDelivery: {'d-1': const <OrderReturn>[]},
      withDeliveryOrders: true,
    );
    await pumpAdmin(tester);

    expect(find.text('The 12/31/2100'), findsOneWidget);
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.arrowTopRightOnSquare,
      ),
    );
    for (var i = 0; i < 20 && find.text('No order').evaluate().isEmpty; i++) {
      await settle(tester, frames: 4);
    }

    // The detail page shows the selected delivery's date and its (empty)
    // order list.
    expect(QR.currentPath, contains('detail'));
    expect(find.text('Delivery date : 12/31/2100'), findsOneWidget);
    expect(find.text('No order'), findsOneWidget);
    expect(find.text('Products :'), findsOneWidget);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the order loader error arm shows the admin error label', (
    tester,
  ) async {
    stubAdminLoads(
      scaffold,
      deliveries: [orderableDelivery('d-1', 1)],
      withDeliveryOrders: true,
    );
    when(
      () => scaffold.repository.amapDeliveriesDeliveryIdOrdersGet(
        deliveryId: any(named: 'deliveryId'),
      ),
    ).thenThrow(Exception('orders failed'));
    await pumpAdmin(tester);

    expect(find.text('Error'), findsOneWidget);
    expect(find.text('The 12/31/2100'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
