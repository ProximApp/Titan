import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/amap/providers/delivery_id_provider.dart';
import 'package:titan/amap/providers/delivery_product_list_provider.dart';
import 'package:titan/amap/providers/order_provider.dart';
import 'package:titan/amap/router.dart';
import 'package:titan/amap/ui/pages/list_products_page/product_choice_button.dart';
import 'package:titan/amap/ui/pages/list_products_page/product_ui_list.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../amap_fixtures.dart';
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

    // The confirm label renders the basket in euros (Hyperion stores the
    // amount in CENTS — ledger #5/#13): 4 cents → 0.04€.
    final confirmLabel =
        'Confirm ('
        '${(container.read(orderProvider).amount / 100).toStringAsFixed(2)}€)';
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

  testWidgets(
    'decrementing the last unit removes the product from the basket',
    (tester) async {
      final container = scaffold.makeContainer(userId: 'user-1');
      addTearDown(container.dispose);

      when(
        () => scaffold.repository.amapUsersUserIdOrdersGet(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => chopperListResponse(<OrderReturn>[]));

      // A basket holding ONE unit of the single product: the next minus takes
      // the quantity to zero and must drop the row from the basket.
      final p = product(0);
      container
          .read(orderProvider.notifier)
          .setOrder(
            OrderReturn.empty().copyWith(
              deliveryId: 'd-1',
              amount: p.price,
              productsdetail: [ProductQuantity(quantity: 1, product: p)],
            ),
          );
      container.read(deliveryIdProvider.notifier).setId('d-1');
      await container
          .read(deliveryProductListProvider.notifier)
          .loadProductList([p]);

      scaffold.setWideSurface(tester);
      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '${AmapRouter.root}${AmapRouter.listProduct}',
        pumpAndSettle: false,
      );
      for (
        var i = 0;
        i < 20 && find.text('boissons Produit 0').evaluate().isEmpty;
        i++
      ) {
        await settle(tester, frames: 4);
      }
      expect(find.text('Confirm (0.02€)'), findsOneWidget);

      // The row's minus is its first icon.
      await tester.tap(
        find
            .descendant(
              of: find.byType(ProductUiInList).first,
              matching: find.byType(HeroIcon),
            )
            .first,
      );
      await settle(tester, frames: 4);

      expect(container.read(orderProvider).productsdetail, isEmpty);
      expect(container.read(orderProvider).amount, 0);
      expect(find.text('Confirm (0.00€)'), findsOneWidget);
    },
  );

  testWidgets('a refused order toasts the adding error', (tester) async {
    final container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(container.dispose);

    when(
      () => scaffold.repository.amapUsersUserIdOrdersGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => chopperListResponse(<OrderReturn>[]));
    when(() => scaffold.repository.amapOrdersPost(body: any(named: 'body')))
        .thenThrow(Exception('order refused'));

    final p = product(0);
    container
        .read(orderProvider.notifier)
        .setOrder(
          OrderReturn.empty().copyWith(
            deliveryId: 'd-1',
            amount: p.price,
            productsdetail: [ProductQuantity(quantity: 1, product: p)],
          ),
        );
    container.read(deliveryIdProvider.notifier).setId('d-1');
    await container.read(deliveryProductListProvider.notifier).loadProductList([
      p,
    ]);

    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${AmapRouter.root}${AmapRouter.listProduct}',
      pumpAndSettle: false,
    );
    for (
      var i = 0;
      i < 20 && find.text('boissons Produit 0').evaluate().isEmpty;
      i++
    ) {
      await settle(tester, frames: 4);
    }

    await tester.tap(find.text('Confirm (0.02€)'));
    await settle(tester, frames: 12);

    // The create arm's failure branch: the error names the failed ADD.
    expect(find.text('Error while adding'), findsOneWidget);
    expect(find.text('Order added'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('confirming an EXISTING order patches it instead of adding one', (
    tester,
  ) async {
    final container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(container.dispose);

    when(
      () => scaffold.repository.amapUsersUserIdOrdersGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => chopperListResponse([order('o-1', 'd-1', 200)]));
    when(
      () => scaffold.repository.amapUsersUserIdCashGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => chopperResponse(cash(0)));
    when(
      () => scaffold.repository.amapOrdersOrderIdPatch(
        orderId: any(named: 'orderId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    // An order already in the basket is what makes this an EDIT: the button
    // reads `orderProvider.orderId`, not "did the user tap from the orders
    // list", so seeding the provider is the whole setup.
    container.read(orderProvider.notifier).setOrder(order('o-1', 'd-1', 200));
    container.read(deliveryIdProvider.notifier).setId('d-1');
    await container.read(deliveryProductListProvider.notifier).loadProductList([
      product(0),
    ]);

    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${AmapRouter.root}${AmapRouter.listProduct}',
      pumpAndSettle: false,
    );
    for (
      var i = 0;
      i < 20 && find.text('boissons Produit 0').evaluate().isEmpty;
      i++
    ) {
      await settle(tester, frames: 4);
    }

    await tester.tap(find.text('Confirm (2.00€)'));
    await settle(tester, frames: 12);

    // The PATCH targets the existing order and NOT a second POST — adding
    // here would leave the customer with two orders for one basket.
    verify(
      () => scaffold.repository.amapOrdersOrderIdPatch(
        orderId: 'o-1',
        body: any(named: 'body'),
      ),
    ).called(1);
    verifyNever(
      () => scaffold.repository.amapOrdersPost(body: any(named: 'body')),
    );
    expect(find.text('Order updated'), findsOneWidget);
    expect(find.text('Order added'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('clearing the basket asks first and only then discards it', (
    tester,
  ) async {
    final container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(container.dispose);

    when(
      () => scaffold.repository.amapUsersUserIdOrdersGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => chopperListResponse(<OrderReturn>[]));
    when(
      () => scaffold.repository.amapUsersUserIdCashGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => chopperResponse(cash(0)));

    // A basket with something in it: the X must protect it.
    container.read(orderProvider.notifier).setOrder(order('', 'd-1', 200));
    container.read(deliveryIdProvider.notifier).setId('d-1');
    await container.read(deliveryProductListProvider.notifier).loadProductList([
      product(0),
    ]);

    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${AmapRouter.root}${AmapRouter.listProduct}',
      pumpAndSettle: false,
    );
    for (
      var i = 0;
      i < 20 && find.text('boissons Produit 0').evaluate().isEmpty;
      i++
    ) {
      await settle(tester, frames: 4);
    }

    await tester.tap(
      find.descendant(
        of: find.byType(ProductChoiceButton),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.xMark,
        ),
      ),
    );
    await settle(tester, frames: 12);

    // The basket is still intact behind the question — the tap did not clear
    // it, which is what makes the confirmation worth having.
    expect(find.text('Delete order?'), findsOneWidget);
    expect(container.read(orderProvider).amount, 200);

    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 12);

    expect(
      container.read(orderProvider).orderId,
      OrderReturn.empty().orderId,
      reason: 'confirming really does clear the basket',
    );
    expect(container.read(orderProvider).amount, 0);
  });

  testWidgets('a refused update toasts the update-failed message', (
    tester,
  ) async {
    final container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(container.dispose);

    when(
      () => scaffold.repository.amapUsersUserIdOrdersGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => chopperListResponse([order('o-1', 'd-1', 200)]));
    when(
      () => scaffold.repository.amapOrdersOrderIdPatch(
        orderId: any(named: 'orderId'),
        body: any(named: 'body'),
      ),
    ).thenThrow(Exception('update refused'));

    final seeded = order('o-1', 'd-1', 200);
    final p = product(0);
    container
        .read(orderProvider.notifier)
        .setOrder(
          seeded.copyWith(
            productsdetail: [ProductQuantity(quantity: 1, product: p)],
          ),
        );
    container.read(deliveryIdProvider.notifier).setId('d-1');
    await container.read(deliveryProductListProvider.notifier).loadProductList([
      p,
    ]);

    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${AmapRouter.root}${AmapRouter.listProduct}',
      pumpAndSettle: false,
    );
    for (
      var i = 0;
      i < 20 && find.text('boissons Produit 0').evaluate().isEmpty;
      i++
    ) {
      await settle(tester, frames: 4);
    }

    // The label shows the seeded amount: adding the product to the basket
    // did not change it.
    await tester.tap(find.text('Confirm (2.00€)'));
    await settle(tester, frames: 12);

    // The edit arm's failure branch: the update-failed message, and no
    // success toast for a PATCH that was refused.
    expect(find.text('Update failed'), findsOneWidget);
    expect(find.text('Order updated'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('the X on an EMPTY basket just leaves without asking', (
    tester,
  ) async {
    final container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(container.dispose);

    when(
      () => scaffold.repository.amapUsersUserIdOrdersGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => chopperListResponse(<OrderReturn>[]));

    container.read(deliveryIdProvider.notifier).setId('d-1');
    await container.read(deliveryProductListProvider.notifier).loadProductList([
      product(0),
    ]);

    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${AmapRouter.root}${AmapRouter.listProduct}',
      pumpAndSettle: false,
    );
    for (
      var i = 0;
      i < 20 && find.text('boissons Produit 0').evaluate().isEmpty;
      i++
    ) {
      await settle(tester, frames: 4);
    }

    await tester.tap(
      find.descendant(
        of: find.byType(ProductChoiceButton),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.xMark,
        ),
      ),
    );
    await settle(tester, frames: 10);

    // Nothing to protect: no confirmation dialog is raised.
    expect(find.text('Delete order?'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
