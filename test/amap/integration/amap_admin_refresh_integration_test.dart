import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';
import '../amap_fixtures.dart';

/// `admin_page.dart:28-31` is the pull-to-refresh body: it reloads cash,
/// deliveries and products in one go. The page carried a note saying the
/// widget harness never arms the Cupertino control; that is not so — the
/// control arms from a slow multi-step drag (`tester.drag`'s single jump
/// overshoots and springs back before it is armed), which is what this test
/// does, and the loan admin strip uses the same widget the same way.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('pulling the admin page reloads all three lists', (tester) async {
    final cash = AppModulesAmapSchemasAmapCashComplete.empty().copyWith(
      balance: 1250,
      userId: 'user-1',
    );
    final product = AppModulesAmapSchemasAmapProductComplete.empty();
    final delivery = DeliveryReturn.empty();

    stubAdminLoads(
      scaffold,
      cashes: [cash],
      products: [product],
      deliveries: [delivery],
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

    // A slow, stepped drag: the Cupertino sliver refresh needs the overscroll
    // to pass its arm threshold and be released from there.
    await pullToRefresh(tester);

    // Each of the three loaders ran a second time from the one gesture.
    verify(() => scaffold.repository.amapUsersCashGet()).called(2);
    verify(() => scaffold.repository.amapDeliveriesGet()).called(2);
    verify(() => scaffold.repository.amapProductsGet()).called(2);
    expect(tester.takeException(), isNull);
  });
}
