import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import 'amap_integration_test.dart';
import '../../shared/app_scaffold.dart';

/// The delivery form's EDIT journey, in its own file because it needs a
/// mid-test navigation: the pencil of a creation delivery opens the form
/// (deep-linking the deferred child through the amap main-page shell dies
/// on the shell's known UserCashNotifier quirk once another test ran in the
/// isolate — see amap_integration_test.dart's ordering note). First and
/// only test of the file, so the mid-test QR.to() is the isolate's first.
///
/// The form titles itself "Add delivery" in edit mode too; only the submit
/// button switches label ("Edit delivery").
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'the creation-card pencil opens the prefilled delivery form and PATCHes through Edit delivery',
    (tester) async {
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
          AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
            id: 'p-2',
            name: 'Wholemeal bread',
            price: 120,
            category: 'Bakery',
          ),
        ],
      );
      when(() => scaffold.repository.amapUsersCashGet()).thenAnswer(
        (_) async =>
            chopperListResponse(<AppModulesAmapSchemasAmapCashComplete>[]),
      );
      when(
        () => scaffold.repository.amapDeliveriesGet(),
      ).thenAnswer((_) async => chopperListResponse([d1]));
      when(() => scaffold.repository.amapProductsGet()).thenAnswer(
        (_) async => chopperListResponse(
          List.of(d1.products ?? <AppModulesAmapSchemasAmapProductComplete>[]),
        ),
      );
      // The admin page's delivery cards auto-load their orders per delivery.
      when(
        () => scaffold.repository.amapDeliveriesDeliveryIdOrdersGet(
          deliveryId: any(named: 'deliveryId'),
        ),
      ).thenAnswer((_) async => chopperListResponse(<OrderReturn>[]));

      DeliveryUpdate? capturedUpdate;
      String? patchedDeliveryId;
      when(
        () => scaffold.repository.amapDeliveriesDeliveryIdPatch(
          deliveryId: any(named: 'deliveryId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((inv) async {
        capturedUpdate = inv.namedArguments[#body] as DeliveryUpdate;
        patchedDeliveryId = inv.namedArguments[#deliveryId] as String;
        return chopperResponseVoid();
      });

      final container = scaffold.makeContainer(
        user: amapAdminUser,
        userId: 'user-1',
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      ignoreAmapKnownQuirks();
      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/amap/admin',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 24);

      // The creation card carries pencil + trash + the Open button; the
      // pencil navigates to the deferred form route. .first: the product
      // cards below also carry pencils, but the deliveries row renders
      // above the products row.
      expect(find.text('The 12/31/2100'), findsOneWidget);
      await tester.tap(
        find
            .byWidgetPredicate(
              (w) => w is HeroIcon && w.icon == HeroIcons.pencil,
            )
            .first,
      );
      for (
        var i = 0;
        i < 20 && find.text('Edit delivery').evaluate().isEmpty;
        i++
      ) {
        await settle(tester, frames: 4);
      }

      // Edit mode: the page title still reads "Add delivery" but the submit
      // button says "Edit delivery", and the date is prefilled from the
      // card (processDateBack round-trips the yMd format on submit).
      expect(find.text('Add delivery'), findsWidgets);
      expect(find.text('Edit delivery'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.widgetWithText(TextField, 'Order date').first,
            )
            .controller!
            .text,
        '12/31/2100',
      );
      // Both products render checked (selectedList rebuilds all-true).
      // Each name shows twice: once on the form's ProductUi rows, once on
      // the admin page's product cards still mounted underneath.
      expect(find.text('Honey jar'), findsNWidgets(2));
      expect(find.text('Wholemeal bread'), findsNWidgets(2));
      expect(find.byType(Checkbox), findsNWidgets(2));

      // Uncheck the first product and submit.
      await tester.tap(find.byType(Checkbox).first);
      await settle(tester, frames: 4);
      await tester.dragUntilVisible(
        find.text('Edit delivery'),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await settle(tester, frames: 2);
      await tester.tap(find.text('Edit delivery'));
      await settle(tester, frames: 16);

      expect(patchedDeliveryId, 'd-1');
      // The PATCH carries the date (the only field DeliveryUpdate has) —
      // parsed back from the yMd prefill through processDateBack.
      expect(capturedUpdate!.deliveryDate, DateTime(2100, 12, 31));
      // The form pops back to the admin page with the success toast.
      expect(find.text('Order edited'), findsOneWidget);
      // Drain the toast timer.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
