import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../amap_fixtures.dart';

/// The delivery form's CREATE-FAILURE arm: the POST is refused (a delivery
/// already exists for that date), so the form stays mounted and toasts the
/// "already exists" message instead of popping.
///
/// Own file for the same reason as the success journey: the "+" card opens
/// the form through the isolate's only usable mid-test QR.to().
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('a refused creation keeps the form open with its toast', (
    tester,
  ) async {
    stubAdminLoads(scaffold, withDeliveryOrders: true);
    when(() => scaffold.repository.amapDeliveriesPost(body: any(named: 'body')))
        .thenThrow(Exception('delivery already exists'));

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

    await tester.tap(
      find
          .byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus)
          .at(1),
    );
    for (var i = 0; i < 20 && find.text('Order date').evaluate().isEmpty; i++) {
      await settle(tester, frames: 4);
    }

    // A valid date, then a submit the backend refuses.
    await tester.tap(find.text('Order date'));
    await settle(tester, frames: 10);
    await tester.tap(find.text('OK').last);
    await settle(tester, frames: 10);
    await tester.ensureVisible(find.text('Add delivery').last);
    await tester.tap(find.text('Add delivery').last);
    await settle(tester, frames: 16);

    expect(find.text('An order already exists for this date'), findsOneWidget);
    // The form is still on screen: the failure arm does not pop.
    expect(QR.currentPath, contains('add_edit_delivery'));
    expect(find.text('Order date'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
    await scaffold.drainToast(tester);
  });
}
