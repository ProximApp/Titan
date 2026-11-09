import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../amap_fixtures.dart';
import '../../shared/app_scaffold.dart';

/// The delivery form's FAILED edit: the pencil opens the prefilled form, the
/// submit runs the real PATCH, and the PATCH is refused.
///
/// In its own file because it needs a mid-test navigation: the pencil
/// deep-links the deferred form route through the admin page's shell, and
/// qlevar drops a later isolate's mid-test QR.to() to a not-yet-mounted route
/// (see amap_integration_test.dart's ordering note). First and only test of
/// the file, so the navigation is the isolate's first.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('a refused edit reports the error and leaves the form open', (
    tester,
  ) async {
    final d1 = DeliveryReturn.empty().copyWith(
      id: 'd-1',
      name: 'Delivery d-1',
      deliveryDate: DateTime(2100, 12, 31),
      status: DeliveryStatusType.creation,
      products: [
        AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
          id: 'p-1',
          name: 'Honey jar',
          price: 350,
          category: 'Grocery',
        ),
      ],
    );
    when(() => scaffold.repository.amapUsersCashGet()).thenAnswer(
      (_) async =>
          chopperListResponse(<AppModulesAmapSchemasAmapCashComplete>[]),
    );
    when(() => scaffold.repository.amapDeliveriesGet())
        .thenAnswer((_) async => chopperListResponse([d1]));
    when(() => scaffold.repository.amapProductsGet())
        .thenAnswer((_) async => chopperListResponse([...?d1.products]));
    when(
      () => scaffold.repository.amapDeliveriesDeliveryIdOrdersGet(
        deliveryId: any(named: 'deliveryId'),
      ),
    ).thenAnswer((_) async => chopperListResponse(<OrderReturn>[]));

    // The PATCH is refused: the form must say so and stay where it is.
    var patches = 0;
    when(
      () => scaffold.repository.amapDeliveriesDeliveryIdPatch(
        deliveryId: any(named: 'deliveryId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async {
      patches++;
      throw Exception('edit refused');
    });

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

    // The creation card's pencil (the product cards below carry pencils too,
    // but the delivery row renders first).
    await tester.tap(
      find
          .byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.pencil)
          .first,
    );
    for (
      var i = 0;
      i < 20 && find.text('Edit delivery').evaluate().isEmpty;
      i++
    ) {
      await settle(tester, frames: 4);
    }
    expect(find.text('Edit delivery'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Edit delivery'),
      find.byType(SingleChildScrollView).last,
      const Offset(0, -200),
    );
    await settle(tester, frames: 2);
    await tester.tap(find.text('Edit delivery'));
    await settle(tester, frames: 16);

    expect(patches, 1);
    expect(find.text('Error while editing'), findsOneWidget);
    expect(find.text('Order edited'), findsNothing);
    // The form did not pop: the refusal keeps the user on their edits.
    expect(find.text('Edit delivery'), findsOneWidget);

    // Drain the toast timer.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
