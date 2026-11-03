import 'package:flutter/material.dart' show PageView;
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderContainer;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/amap/providers/delivery_product_list_provider.dart';
import 'package:titan/amap/providers/page_controller_provider.dart';
import 'package:titan/amap/providers/scroll_provider.dart';
import 'package:titan/amap/router.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../amap_fixtures.dart';

/// `ListProducts` pages through one category per view. Two paths had never
/// run: the empty-category placeholder (a delivery whose products failed to
/// load) and the `onPageChanged` handler that resets the scroll offset and
/// re-shows the header as the customer swipes between categories.
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
    name: '$category Produit $i',
    category: category,
    price: 2,
  );

  void stubOrders() {
    when(
      () => scaffold.repository.amapUsersUserIdOrdersGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => chopperListResponse(<OrderReturn>[]));
  }

  Future<void> pumpList(WidgetTester tester) async {
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      _container!,
      initialPath: '${AmapRouter.root}${AmapRouter.listProduct}',
      pumpAndSettle: false,
    );
    // The background painter animates forever: poll instead of settling.
    for (var i = 0; i < 20 && find.byType(PageView).evaluate().isEmpty; i++) {
      await settle(tester, frames: 4);
    }
  }

  testWidgets('a delivery without products shows the empty page', (
    tester,
  ) async {
    stubOrders();
    _container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(_container!.dispose);
    // No products loaded for this delivery.
    await _container!
        .read(deliveryProductListProvider.notifier)
        .loadProductList(const []);

    await pumpList(tester);

    expect(find.text('No product'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping to the next category resets the scroll offset', (
    tester,
  ) async {
    stubOrders();
    _container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(_container!.dispose);
    await _container!
        .read(deliveryProductListProvider.notifier)
        .loadProductList([product(0), product(1, category: 'snacks')]);

    await pumpList(tester);
    final pages = find.byType(PageView);
    expect(pages, findsOneWidget);
    expect(_container!.read(amapPageControllerProvider).page, 0);

    // A previous offset must not survive the category change.
    _container!.read(scrollProvider.notifier).setScroll(0.4);
    // A fling, not a drag: the controller has to COMMIT the page, and the
    // background painter prevents settling on its own.
    await tester.fling(pages, const Offset(-500, 0), 1200);
    await settle(tester, frames: 40);

    expect(
      _container!.read(amapPageControllerProvider).page,
      closeTo(1, 0.05),
      reason: 'the fling must land on the second category',
    );
    expect(
      _container!.read(scrollProvider),
      closeTo(1, 0.05),
      reason: 'the page listener pins the offset to the new page index',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('the web arrows page forward and back between categories', (
    tester,
  ) async {
    stubOrders();
    _container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(_container!.dispose);
    await _container!
        .read(deliveryProductListProvider.notifier)
        .loadProductList([product(0), product(1, category: 'snacks')]);

    await pumpList(tester);
    // The wide surface renders the web-only arrows around the page view.
    final next = find.byWidgetPredicate(
      (w) => w is HeroIcon && w.icon == HeroIcons.arrowRight,
    );
    final previous = find.byWidgetPredicate(
      (w) => w is HeroIcon && w.icon == HeroIcons.arrowLeft,
    );
    expect(next, findsOneWidget);
    expect(previous, findsOneWidget);
    expect(_container!.read(amapPageControllerProvider).page, 0);

    // Forward to the second category: the page change resets the offset.
    _container!.read(scrollProvider.notifier).setScroll(0.4);
    await tester.tap(next);
    await settle(tester, frames: 40);
    expect(_container!.read(amapPageControllerProvider).page, closeTo(1, 0.05));
    expect(_container!.read(scrollProvider), closeTo(1, 0.05));

    // And back to the first.
    await tester.tap(previous);
    await settle(tester, frames: 40);
    expect(_container!.read(amapPageControllerProvider).page, closeTo(0, 0.05));
    expect(_container!.read(scrollProvider), closeTo(0, 0.05));
    expect(tester.takeException(), isNull);
  });
}

ProviderContainer? _container;
