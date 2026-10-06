import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import 'amap_integration_test.dart';
import '../../shared/app_scaffold.dart';

/// The admin page's bottom handler (ProductHandler): product cards grouped
/// by category, the create-product navigation and the delete dialog.
///
/// The FIRST test is the only mid-test navigator (qlevar 1.12.4 drops later
/// mid-test QR.to() calls — see amap_integration_test.dart).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  AppModulesAmapSchemasAmapProductComplete product(
    String id,
    String name,
    int price,
    String category,
  ) => AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
    id: id,
    name: name,
    price: price,
    category: category,
  );

  /// Stubs everything the admin page loads on mount. Nullable params so the
  /// defaults can be const: DeliveryHandler sorts a copy of the provider's
  /// list (ledger #12), so an unmodifiable fixture is now the honest one and
  /// guards the fix.
  void stubAdminLoads({
    List<AppModulesAmapSchemasAmapProductComplete>? products,
  }) {
    when(() => scaffold.repository.amapUsersCashGet()).thenAnswer(
      (_) async =>
          chopperListResponse(<AppModulesAmapSchemasAmapCashComplete>[]),
    );
    when(
      () => scaffold.repository.amapDeliveriesGet(),
    ).thenAnswer((_) async => chopperListResponse(const <DeliveryReturn>[]));
    when(
      () => scaffold.repository.amapProductsGet(),
    ).thenAnswer((_) async => chopperListResponse(products ?? []));
  }

  Future<void> pumpAdmin(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    ignoreAmapKnownQuirks();
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/amap/admin',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);
  }

  testWidgets('the products + card opens the add-product form', (tester) async {
    stubAdminLoads();

    final container = scaffold.makeContainer(
      user: amapAdminUser,
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await pumpAdmin(tester, container);

    // Third plus on the page (accounts toggle, deliveries create, products
    // create).
    await tester.tap(
      find
          .byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus)
          .at(2),
    );
    for (
      var i = 0;
      i < 20 && find.text('Add product').evaluate().isEmpty;
      i++
    ) {
      await settle(tester, frames: 4);
    }

    // The deferred form route mounts with the "Create category" default.
    expect(find.text('Add product'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Price'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Create category'), findsNWidgets(2));
  });

  testWidgets('renders product cards grouped by category', (tester) async {
    stubAdminLoads(
      products: [
        product('p-1', 'Honey jar', 350, 'Grocery'),
        product('p-2', 'Wholemeal bread', 120, 'Bakery'),
        product('p-3', 'Apple juice', 240, 'Grocery'),
      ],
    );

    final container = scaffold.makeContainer(
      user: amapAdminUser,
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await pumpAdmin(tester, container);

    // Three cards, each showing category, name and the raw int price
    // (no cents division — same convention as the balance cards).
    expect(find.text('Honey jar'), findsOneWidget);
    expect(find.text('Wholemeal bread'), findsOneWidget);
    expect(find.text('Apple juice'), findsOneWidget);
    expect(find.text('350.00 €'), findsOneWidget);
    expect(find.text('120.00 €'), findsOneWidget);
    expect(find.text('240.00 €'), findsOneWidget);
    // No product → the empty state is gone.
    expect(find.text('No product'), findsNothing);
    // Each card carries its edit pencil and delete trash.
    expect(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.pencil,
      ),
      findsNWidgets(3),
    );
    expect(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.trash),
      findsNWidgets(3),
    );
  });

  testWidgets('the trash dialog deletes a product', (tester) async {
    stubAdminLoads(products: [product('p-1', 'Honey jar', 350, 'Grocery')]);

    String? deletedProductId;
    when(
      () => scaffold.repository.amapProductsProductIdDelete(
        productId: any(named: 'productId'),
      ),
    ).thenAnswer((inv) async {
      deletedProductId = inv.namedArguments[#productId] as String;
      return chopperResponseVoid();
    });

    final container = scaffold.makeContainer(
      user: amapAdminUser,
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await pumpAdmin(tester, container);

    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.trash),
    );
    await tester.pump();
    await settle(tester, frames: 8);
    expect(find.text('Delete product?'), findsOneWidget);
    expect(
      find.text('Are you sure you want to delete this product?'),
      findsOneWidget,
    );

    // Confirm runs the real DELETE, toasts and empties the row.
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 12);

    expect(deletedProductId, 'p-1');
    expect(find.text('Product deleted'), findsOneWidget);
    expect(find.text('Honey jar'), findsNothing);
    expect(find.text('No product'), findsOneWidget);
    // Drain the toast timer.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
