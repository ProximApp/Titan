import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/amap/ui/pages/detail_delivery_page/order_detail_ui.dart';
import 'package:titan/amap/ui/pages/main_page/orders_section.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixed_size_card_fixtures.dart' show seedSharedMaps;

/// WIDGET level: `OrderSection` and `DetailOrderUI`.
///
/// Both sat in the mount-ratchet's exemption maps: `OrderSection` claimed
/// it needed page-scoped orders/associations maps seeded, and `DetailOrderUI`
/// was BLOCKED by bug #3 — `userOrderListProvider` (and its cash sibling)
/// read `state` from `build()`, which Riverpod turns into a hard throw
/// through its provider error channel, so the card never laid out. The
/// provider fix (start in `AsyncValue.loading()`, like every other
/// ListNotifierAPI subclass) made both mount clean, the mount-ratchet audit
/// recorded the clean mount and failed the stale claims, and the exemptions
/// were deleted. These tests are what the ratchet counts in their place.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  void stubImages() {
    final missing = chopper.Response(http.Response('', 404), <int>[]);
    when(
      () => scaffold.repository.associationsAssociationIdLogoGet(
        associationId: any(named: 'associationId'),
      ),
    ).thenAnswer((_) async => missing);
    when(
      () => scaffold.repository.advertAdvertsAdvertIdPictureGet(
        advertId: any(named: 'advertId'),
      ),
    ).thenAnswer((_) async => missing);
    when(
      () => scaffold.repository.cinemaSessionsSessionIdPosterGet(
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer((_) async => missing);
    when(
      () => scaffold.repository
          .recommendationRecommendationsRecommendationIdPictureGet(
            recommendationId: any(named: 'recommendationId'),
          ),
    ).thenAnswer((_) async => missing);
    when(
      () => scaffold.repository.campaignListsListIdLogoGet(
        listId: any(named: 'listId'),
      ),
    ).thenAnswer((_) async => missing);
  }

  Future<void> mountApp(WidgetTester tester, Widget child) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    stubImages();
    seedSharedMaps(container);
    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(body: SingleChildScrollView(child: child)),
      container,
      // Match the mount-ratchet audit's conditions: real font metrics, not
      // the Ahem test font — the card's fixed-height layout only fits under
      // the fonts it ships with.
      appFonts: true,
    );
    await settle(tester, frames: 2);
  }

  testWidgets('OrderSection mounts clean at 360px', (tester) async {
    await mountApp(
      tester,
      OrderSection(onTap: () {}, addOrder: () {}, onEdit: () {}),
    );

    expect(find.byType(OrderSection), findsOneWidget);
  });

  testWidgets('DetailOrderUI mounts clean at 360px', (tester) async {
    final order = OrderReturn.empty().copyWith(orderId: 'o-1');
    await mountApp(
      tester,
      DetailOrderUI(
        order: order,
        userCash: AppModulesAmapSchemasAmapCashComplete.empty(),
        deliveryId: 'd-1',
      ),
    );

    expect(find.byType(DetailOrderUI), findsOneWidget);
  });
}
