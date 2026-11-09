import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../../shared/app_scaffold.dart';
import '../amap_fixtures.dart';

/// `detail_page.dart:44-48` is the delivery detail page's pull-to-refresh
/// body. The sibling navigation test records it as unreachable, but a
/// product-less delivery renders fine and an `AlwaysScrollableScrollPhysics`
/// sliver overscrolls from a slow stepped drag — that arms the Cupertino
/// control and fires the body, exactly as on the admin page.
///
/// Its own file: the admin navigation and this one both use QR.to(), and the
/// qlevar singleton drops a second mid-test navigation once one ran.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('pulling the delivery detail page reloads it', (tester) async {
    stubAdminLoads(
      scaffold,
      deliveries: [orderableDelivery('d-1', 0)],
      ordersByDelivery: {'d-1': const <OrderReturn>[]},
      withDeliveryOrders: true,
    );
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

    // Open the detail page from its card.
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.arrowTopRightOnSquare,
      ),
    );
    for (var i = 0; i < 20 && find.text('No order').evaluate().isEmpty; i++) {
      await settle(tester, frames: 4);
    }
    expect(find.text('Delivery date : 12/31/2100'), findsOneWidget);

    // Slow, stepped drag on the detail page's own Refresher (the admin page's
    // sits underneath).
    await pullToRefresh(tester, finder: find.byType(Refresher).last);

    // The body reloads the delivery list (the detail's own order list is
    // loaded by the page's watch, not by this handler).
    verify(() => scaffold.repository.amapDeliveriesGet()).called(2);
    expect(find.text('Delivery date : 12/31/2100'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
