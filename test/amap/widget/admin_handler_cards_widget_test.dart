import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/amap/ui/pages/admin_page/account_handler.dart';
import 'package:titan/amap/ui/pages/admin_page/delivery_handler.dart';
import 'package:titan/amap/ui/pages/admin_page/product_handler.dart';
import 'package:chopper/chopper.dart' as chopper;

import '../../shared/app_scaffold.dart';
import '../../tools/fixed_size_card_fixtures.dart' show seedSharedMaps;

/// WIDGET level: the three amap admin edit HANDLERS.
///
/// They used to sit in `cardLayoutNotMountedExemptions` on the claim that
/// they are dialogs needing the accounts/deliveries/products provider maps
/// and a route to dismiss back to. The mount-ratchet audit (ledger #49's
/// `exemption_mount_audit_test.dart`) tried that claim and the handlers
/// mounted CLEAN — the audit's own verdict is "delete the entry and mount
/// the card in a widget test so the ratchet counts it", which is what this
/// file does. Conditions mirror the audit's `attemptMount`: shared maps
/// seeded, the image endpoints stubbed to 404.
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

  testWidgets('AccountHandler mounts clean at 360px', (tester) async {
    await mountApp(tester, const AccountHandler());

    expect(find.byType(AccountHandler), findsOneWidget);
  });

  testWidgets('DeliveryHandler mounts clean at 360px', (tester) async {
    await mountApp(tester, const DeliveryHandler());

    expect(find.byType(DeliveryHandler), findsOneWidget);
  });

  testWidgets('ProductHandler mounts clean at 360px', (tester) async {
    await mountApp(tester, const ProductHandler());

    expect(find.byType(ProductHandler), findsOneWidget);
  });
}
