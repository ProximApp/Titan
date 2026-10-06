import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/amap/providers/product_list_provider.dart';
import 'package:titan/amap/providers/product_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';

import 'amap_integration_test.dart';
import '../../shared/app_scaffold.dart';

/// The product edit form, driven by a deep link with the selected product
/// pre-seeded into the providers (no mid-test navigation — see the qlevar
/// notes in amap_integration_test.dart; edit mode renders straight from the
/// seeded provider state).
///
/// The delivery form's edit journey lives in its own file
/// (amap_admin_edit_delivery_integration_test.dart): the amap main-page
/// shell cannot mount a deferred child from a deep link once another test
/// ran in the isolate, so that one is tap-navigated as its file's first
/// test (README convention 10, same split as the recommendation module).
///
/// The form titles itself "Add product" in edit mode too; only the submit
/// button switches label ("Edit").
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Stubs everything the admin page loads on mount. Nullable params so the
  /// defaults can be const: DeliveryHandler sorts a copy of the provider's
  /// list (ledger #12), so an unmodifiable fixture is now the honest one and
  /// guards the fix.
  void stubAdminLoads({
    List<AppModulesAmapSchemasAmapProductComplete>? products,
    List<DeliveryReturn>? deliveries,
  }) {
    when(() => scaffold.repository.amapUsersCashGet()).thenAnswer(
      (_) async =>
          chopperListResponse(<AppModulesAmapSchemasAmapCashComplete>[]),
    );
    when(() => scaffold.repository.amapDeliveriesGet()).thenAnswer(
      (_) async => chopperListResponse(deliveries ?? const <DeliveryReturn>[]),
    );
    // The admin page's delivery cards auto-load their orders per delivery;
    // an un-stubbed call would read as a null Future<Response> and kill the
    // whole child-route mount with a type error.
    when(
      () => scaffold.repository.amapDeliveriesDeliveryIdOrdersGet(
        deliveryId: any(named: 'deliveryId'),
      ),
    ).thenAnswer((_) async => chopperListResponse(<OrderReturn>[]));
    when(
      () => scaffold.repository.amapProductsGet(),
    ).thenAnswer((_) async => chopperListResponse(products ?? []));
  }

  testWidgets(
    'the product form edits a pre-seeded product through the real PATCH',
    (tester) async {
      final editing = AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
        id: 'p-1',
        name: 'Honey jar',
        price: 350,
        category: 'Grocery',
      );
      stubAdminLoads(products: [editing]);

      AppModulesAmapSchemasAmapProductEdit? capturedEdit;
      String? patchedProductId;
      when(
        () => scaffold.repository.amapProductsProductIdPatch(
          productId: any(named: 'productId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((inv) async {
        capturedEdit =
            inv.namedArguments[#body] as AppModulesAmapSchemasAmapProductEdit;
        patchedProductId = inv.namedArguments[#productId] as String;
        return chopperResponseVoid();
      });

      final container = scaffold.makeContainer(
        user: amapAdminUser,
        userId: 'user-1',
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      // Pre-seed the selection BEFORE the pump so the form's hooks read the
      // edit product on their first build (isEdit = id != '').
      container.read(productProvider.notifier).setProduct(editing);
      container.read(productListProvider.notifier).state = AsyncValue.data([
        editing,
      ]);

      ignoreAmapKnownQuirks();
      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/amap/admin/add_edit_product',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 16);

      // Edit mode: heading and submit say Edit, fields are prefilled and the
      // category dropdown starts on the product's category.
      expect(find.text('Edit product'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Name').first)
            .controller!
            .text,
        'Honey jar',
      );
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Price').first)
            .controller!
            .text,
        '350,00',
      );
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .initialValue,
        'Grocery',
      );
      // An existing category shows no extra create-category field, and the
      // closed dropdown does not render the non-selected item either.
      expect(find.text('Create category'), findsNothing);

      // Change the name and submit.
      await tester.enterText(
        find.widgetWithText(TextField, 'Name').first,
        'Honey jar 500g',
      );
      await settle(tester, frames: 4);
      await tester.tap(find.text('Edit'));
      await settle(tester, frames: 16);

      expect(patchedProductId, 'p-1');
      expect(capturedEdit!.name, 'Honey jar 500g');
      // The price round-trips through its comma prefill back to the int.
      expect(capturedEdit!.price, 350);
      expect(capturedEdit!.category, 'Grocery');
      // The form pops back to the admin page with the success toast.
      expect(find.text('Product updated'), findsOneWidget);
      // Drain the toast timer.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
