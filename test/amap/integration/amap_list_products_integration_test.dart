import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/amap/providers/delivery_product_list_provider.dart';
import 'package:titan/amap/providers/order_provider.dart';
import 'package:titan/amap/router.dart';
import 'package:titan/amap/ui/pages/list_products_page/product_ui_list.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// Page-level coverage for the customer `ListProductPage`: the categories
/// built from the delivery's products, the overflow "See more" branch, the
/// in-memory basket (+/- on a row, the empty-basket guard) and the real
/// `amapOrdersPost` behind the confirm button.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  AppModulesAmapSchemasAmapProductComplete product(
    int i, {
    String category = 'boissons',
  }) => AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
    id: 'p-$category-$i',
    // The category is part of the name: the page view pre-builds the next
    // category's page, so bare numbers would appear twice.
    name: '$category Produit $i',
    category: category,
    price: 2,
  );

  testWidgets('the product list builds a basket and posts the order', (
    tester,
  ) async {
    final container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(container.dispose);

    when(
      () => scaffold.repository.amapUsersUserIdOrdersGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => chopperListResponse(<OrderReturn>[]));

    OrderBase? captured;
    when(
      () => scaffold.repository.amapOrdersPost(body: any(named: 'body')),
    ).thenAnswer((inv) async {
      captured = inv.namedArguments[#body] as OrderBase;
      return chopperResponse(OrderReturn.empty().copyWith(orderId: 'o-new'));
    });

    // 18 products in one category so the list overflows its fixed height
    // and takes the scrollable "See more" branch; a second category drives
    // the page dots.
    await container.read(deliveryProductListProvider.notifier).loadProductList([
      for (var i = 0; i < 18; i++) product(i),
      for (var i = 0; i < 2; i++) product(i, category: 'snacks'),
    ]);

    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${AmapRouter.root}${AmapRouter.listProduct}',
      pumpAndSettle: false,
    );
    // The background painter animates forever: poll instead of settling.
    for (
      var i = 0;
      i < 20 && find.text('boissons Produit 0').evaluate().isEmpty;
      i++
    ) {
      await settle(tester, frames: 4);
    }

    expect(find.text('Boissons'), findsOneWidget);
    expect(find.text('boissons Produit 0'), findsOneWidget);
    expect(find.text('See more'), findsOneWidget);
    expect(find.text('Confirm (0.00€)'), findsOneWidget);

    // Confirm with an empty basket is refused without a POST.
    await tester.tap(find.text('Confirm (0.00€)'));
    await settle(tester, frames: 12);
    expect(find.text('No product'), findsOneWidget);
    verifyNever(
      () => scaffold.repository.amapOrdersPost(body: any(named: 'body')),
    );

    // The first row's icons are minus then plus. Taps happen before the
    // "See more" scroll moves the first rows under the top gradient.
    final rowIcons = find.descendant(
      of: find.byType(ProductUiInList).first,
      matching: find.byType(HeroIcon),
    );
    await tester.tap(rowIcons.last);
    await settle(tester, frames: 4);
    await tester.tap(rowIcons.last);
    await settle(tester, frames: 4);
    expect(container.read(orderProvider).productsdetail.single.quantity, 2);
    expect(container.read(orderProvider).amount, closeTo(4.0, 0.001));

    await tester.tap(rowIcons.first);
    await settle(tester, frames: 4);
    expect(container.read(orderProvider).productsdetail.single.quantity, 1);

    // Confirm posts the basket through the real endpoint.
    // The overflow branch scrolls the list; the confirm bar stays fixed.
    await tester.tap(find.text('See more'));
    await settle(tester, frames: 8);

    final confirmLabel =
        'Confirm ('
        '${container.read(orderProvider).amount.toStringAsFixed(2)}€)';
    await tester.tap(find.text(confirmLabel));
    await settle(tester, frames: 12);

    expect(captured, isNotNull);
    expect(captured!.productsIds, ['p-boissons-0']);
    expect(captured!.productsQuantity, [1]);
    expect(find.text('Order added'), findsOneWidget);

    // Drain the toast timer.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
