import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../amap_fixtures.dart';

/// The delivery form's CREATE journey, in its own file because it needs a
/// mid-test navigation: the DeliveryHandler's "+" card opens the deferred
/// form. First and only test of the file, so the mid-test QR.to() is the
/// isolate's first (qlevar drops later ones).
///
/// The journey covers both submit outcomes of the form's validator: an
/// empty date is refused with the "Error while adding" toast, then the real
/// date dialog fills the field and the second submit POSTs the delivery.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('an empty date is refused, then the real date creates the '
      'delivery', (tester) async {
    stubAdminLoads(
      scaffold,
      deliveries: [orderableDelivery('d-1', 2)],
      ordersByDelivery: {'d-1': const <OrderReturn>[]},
      withDeliveryOrders: true,
    );

    DeliveryBase? created;
    when(() => scaffold.repository.amapDeliveriesPost(body: any(named: 'body')))
        .thenAnswer((inv) async {
          created = inv.namedArguments[#body] as DeliveryBase;
          return chopperResponse(DeliveryReturn.empty());
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

    // The create card is the second plus (AccountHandler's toggle first).
    await tester.tap(
      find
          .byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus)
          .at(1),
    );
    for (var i = 0; i < 20 && find.text('Order date').evaluate().isEmpty; i++) {
      await settle(tester, frames: 4);
    }
    expect(find.text('Order date'), findsOneWidget);

    // Empty date: the form's validator refuses and toasts; nothing is sent.
    await tester.ensureVisible(find.text('Add delivery').last);
    await tester.tap(find.text('Add delivery').last);
    await settle(tester, frames: 10);
    expect(find.text('Error while adding'), findsOneWidget);
    expect(created, isNull);
    await scaffold.drainToast(tester);

    // The date row opens the real Material date dialog; OK fills the field
    // with today's yMd date.
    await tester.tap(find.text('Order date'));
    await settle(tester, frames: 10);
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK').last);
    await settle(tester, frames: 10);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Order date'))
          .controller!
          .text,
      isNotEmpty,
    );

    // Submitting now POSTs the delivery, pops back and toasts.
    await tester.ensureVisible(find.text('Add delivery').last);
    await tester.tap(find.text('Add delivery').last);
    await settle(tester, frames: 16);

    expect(created, isNotNull);
    expect(created!.deliveryDate, today);
    // `toDeliveryBase` sends only the date and name: the products are
    // attached through the delivery's own product endpoint.
    expect(created!.productsIds, isNull);
    expect(find.text('Order added'), findsOneWidget);
    expect(QR.currentPath, contains('admin'));

    await scaffold.unmountApp(tester);
    await scaffold.drainToast(tester);
  });
}
