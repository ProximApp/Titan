import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/amap/ui/components/order_ui.dart';
import 'package:titan/amap/ui/components/product_ui.dart';
import 'package:titan/amap/ui/pages/admin_page/user_cash_ui.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/layouts/horizontal_list_view.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level tests for the amap cards — the WIDGET level's first users.
///
/// These mount ONE widget with no router, no AppTemplate and no navigation,
/// at a 360x640 phone surface instead of the integration shell's 1920x1080.
/// A fixed-width card that only fits on a desktop is a bug (ledger #4), and
/// `flutter_test` makes every overflow fatal, so this file is the standing
/// guard for the family the layout sweep fixed: the order card's date/count/
/// amount rows, the product card's AutoSizeText column and the cash card's
/// balance row.
///
/// The data is deliberately adversarial — a long nickname, a five-figure
/// balance, a 12500.00 amount, three products — because the widths that
/// overflow are the ones nobody types in a demo.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Everything the cards' notifiers load on mount. The cards only READ
  /// these (no taps), so an empty answer is enough to keep the network edge
  /// quiet and the render deterministic.
  void stubCardLoads() {
    when(
      () => scaffold.repository.amapUsersUserIdOrdersGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => chopperListResponse(const <OrderReturn>[]));
    when(
      () => scaffold.repository.amapUsersUserIdCashGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer(
      (_) async =>
          chopperResponse(AppModulesAmapSchemasAmapCashComplete.empty()),
    );
    when(() => scaffold.repository.amapProductsGet()).thenAnswer(
      (_) async => chopperListResponse(
        const <AppModulesAmapSchemasAmapProductComplete>[],
      ),
    );
  }

  ProviderContainer cardContainer() {
    final container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(container.dispose);
    return container;
  }

  CoreUserSimple user(String firstname, String name, {String? nickname}) =>
      CoreUserSimple.empty().copyWith(
        id: 'user-1',
        firstname: firstname,
        name: name,
        nickname: nickname,
      );

  AppModulesAmapSchemasAmapProductComplete product(
    String id,
    String name, {
    int price = 1000,
    String category = 'Food',
  }) => AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
    id: id,
    name: name,
    price: price,
    category: category,
  );

  OrderReturn order({int amount = 12500, int products = 3}) =>
      OrderReturn.empty().copyWith(
        orderId: 'o-1',
        user: user('Jean-Baptiste', 'DelaunayDeserializer'),
        amount: amount,
        collectionSlot: enums.AmapSlotType.soir,
        deliveryDate: DateTime(2100, 12, 31),
        productsdetail: List.generate(
          products,
          (i) => ProductQuantity.empty().copyWith(
            quantity: 12,
            product: product('p-$i', 'Product with a fairly long name $i'),
          ),
        ),
      );

  testWidgets('the order card fits a long date, three products and 12500.00', (
    tester,
  ) async {
    stubCardLoads();
    await scaffold.pumpWidgetApp(
      tester,
      OrderUI(order: order()),
      cardContainer(),
    );

    // The card renders its date, its product count and the scaled-down
    // amount: the three rows the sweep made flexible. The count line is
    // built from the l10n singular ("product" in en) plus a hand-rolled "s",
    // so match it by shape instead of by literal.
    expect(find.textContaining('12/31/2100'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && RegExp(r'^3\s').hasMatch(w.data ?? ''),
      ),
      findsOneWidget,
    );
    expect(find.text('12500.00€'), findsOneWidget);
    // The collection slot line still sits under them.
    expect(find.text('Soir'), findsOneWidget);
    // And the whole card stayed inside the phone width.
    expect(tester.getSize(find.byType(OrderUI)).width, lessThanOrEqualTo(360));
    // The card keeps its designed proportions: the height fix below scales
    // with the text, it does not resize the card at the default scale.
    expect(tester.getSize(find.byType(OrderUI)).height, 150);
  });

  testWidgets(
    'the order card detail state fits its own content, buttons or not',
    (tester) async {
      stubCardLoads();
      await scaffold.pumpWidgetApp(
        tester,
        OrderUI(order: order(), showButton: false, isDetail: true),
        cardContainer(),
      );

      // The detail card drops the info icon and the button row, but its
      // three remaining lines (date, count/amount, slot) measured 104px
      // against a pinned 100px box — a 4px overflow at the DEFAULT text
      // scale, on a page nobody had mounted at phone width before.
      expect(find.textContaining('12/31/2100'), findsOneWidget);
      expect(find.text('12500.00€'), findsOneWidget);
      expect(find.text('Soir'), findsOneWidget);
      // No button row in the detail state.
      expect(find.byType(HeroIcon), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the order card grows with the text scale', (tester) async {
    stubCardLoads();
    // Every state overflowed its pinned height at 1.3x (17px / 9px / 27px)
    // and the height now follows `MediaQuery.textScalerOf`. 2.0x is the
    // most extreme text setting iOS/Android expose in their own pickers.
    for (final scale in [1.3, 1.5, 2.0]) {
      for (final state in const [
        (showButton: true, isDetail: false),
        (showButton: false, isDetail: false),
        (showButton: false, isDetail: true),
      ]) {
        await scaffold.pumpWidgetApp(
          tester,
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: OrderUI(
              order: order(),
              showButton: state.showButton,
              isDetail: state.isDetail,
            ),
          ),
          cardContainer(),
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'order card overflowed at a ${scale}x text scale',
        );
      }
    }
  });

  testWidgets('the order card still fits the main page strip at 1.3x', (
    tester,
  ) async {
    stubCardLoads();
    // The main page puts the cards in a HorizontalListView(height: 195), so
    // the taller card must still fit inside that bound.
    await scaffold.pumpWidgetApp(
      tester,
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: HorizontalListView(
          height: 195,
          children: [OrderUI(order: order())],
        ),
      ),
      cardContainer(),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('the product card fits a long category and name', (tester) async {
    stubCardLoads();
    await scaffold.pumpWidgetApp(
      tester,
      ProductCard(
        product: product(
          'p-1',
          'A product whose name is far too long for a 130px card',
          price: 12345,
          category: 'A very long category name',
        ),
        quantity: 7,
        showButton: false,
      ),
      cardContainer(),
    );

    // AutoSizeText in a bounded Column scales down and ellipsizes instead of
    // overflowing. amap renders raw amounts (ledger: prices are cents, so
    // 12345 prints as 12345.00 — no division here).
    expect(find.textContaining('12345.00 €'), findsOneWidget);
    expect(find.textContaining('Quantity'), findsOneWidget);
    expect(find.textContaining('7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the cash card fits a five-figure balance and a long nickname', (
    tester,
  ) async {
    stubCardLoads();
    await scaffold.pumpWidgetApp(
      tester,
      UserCashUi(
        cash: AppModulesAmapSchemasAmapCashComplete.empty().copyWith(
          balance: 1250000,
          userId: 'user-1',
          user: user(
            'Jean-Baptiste',
            'DelaunayDeserializer',
            nickname: 'A nickname that will not fit',
          ),
        ),
      ),
      cardContainer(),
    );

    // The balance row is the one the sweep wrapped in Expanded (an
    // AutoSizeText inside a Row never scaled on its own). Same raw-cents
    // convention: 1250000 prints in full.
    expect(find.textContaining('1250000.00'), findsOneWidget);
    expect(find.textContaining('A nickname'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
