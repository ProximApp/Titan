import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../../shared/app_scaffold.dart';

SellerComplete adminSeller(String id, String name) =>
    SellerComplete.empty().copyWith(id: id, name: name);

GenerateTicketComplete generator() => GenerateTicketComplete.empty().copyWith(
  id: 'gen-1',
  name: 'Soirée des clubs',
  maxUse: 10,
  expiration: DateTime(2100),
);

AppModulesCdrSchemasCdrProductComplete scannableProduct() =>
    AppModulesCdrSchemasCdrProductComplete.empty().copyWith(
      id: 'prod-1',
      nameFr: 'Consumption',
      sellerId: 'seller-1',
      tickets: [generator()],
    );

AppModulesCdrSchemasCdrProductComplete unscannableProduct() =>
    AppModulesCdrSchemasCdrProductComplete.empty().copyWith(
      id: 'prod-2',
      nameFr: 'Merch',
      sellerId: 'seller-2',
      tickets: <GenerateTicketComplete>[],
    );

AppModulesCdrSchemasCdrTicket myTicket() =>
    AppModulesCdrSchemasCdrTicket.empty().copyWith(
      id: 't-1',
      name: 'Soirée des clubs',
      scanLeft: 1,
      expiration: DateTime(2100),
    );

/// The purchases-admin path in one router-pushing test (convention 19): a
/// non-empty seller list opens the admin gate, so the main page shows the
/// Scan button whose tap pushes the scan page; the main page and the scan
/// page both reload through their pull-to-refresh closures; and the scan
/// page renders both the scannable ticket cards and the empty
/// "no scannable products" branch.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'the Scan button opens the scan page, refresh reloads, and both product branches render',
    (tester) async {
      when(() => scaffold.repository.cdrUsersMeTicketsGet()).thenAnswer(
        (_) async =>
            chopperListResponse<AppModulesCdrSchemasCdrTicket>([myTicket()]),
      );
      // The scan-page refresh reloads the seller list through the API; the
      // same two sellers come back so the chips survive the reload.
      when(() => scaffold.repository.cdrSellersGet()).thenAnswer(
        (_) async => chopperListResponse<SellerComplete>([
          adminSeller('seller-1', 'BDE Bar'),
          adminSeller('seller-2', 'Snack'),
        ]),
      );
      when(
        () => scaffold.repository.cdrSellersSellerIdProductsGet(
          sellerId: any(named: 'sellerId'),
        ),
      ).thenAnswer((invocation) async {
        final sellerId = invocation.namedArguments[#sellerId] as String?;
        final products = sellerId == 'seller-2'
            ? <AppModulesCdrSchemasCdrProductComplete>[unscannableProduct()]
            : <AppModulesCdrSchemasCdrProductComplete>[scannableProduct()];
        return chopperListResponse(products);
      });

      final container = scaffold.makeContainer(
        purchasesSellers: [
          adminSeller('seller-1', 'BDE Bar'),
          adminSeller('seller-2', 'Snack'),
        ],
      );
      await scaffold.pumpApp(tester, container, initialPath: '/purchases');
      await settle(tester, frames: 10);

      // The seller list pre-seed opens the admin gate: the Scan button shows.
      expect(find.text('Scan'), findsOneWidget);

      // Pull to refresh reloads the user's tickets.
      await tester.drag(find.byType(Refresher), const Offset(0, 1500));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await tester.fling(find.byType(Refresher), const Offset(0, 300), 1000);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await settle(tester, frames: 8);
      verify(() => scaffold.repository.cdrUsersMeTicketsGet()).called(2);

      await tester.tap(find.text('Scan'));
      await settle(tester, frames: 10);
      expect(QR.currentPath, '/purchases/scan');
      expect(find.text('Please select a seller'), findsOneWidget);

      // Selecting the first seller reveals its scannable ticket card.
      await tester.tap(find.text('BDE Bar'));
      await settle(tester, frames: 6);
      expect(find.text('Soirée des clubs'), findsOneWidget);

      // The scan page also reloads its sellers through its own refresh.
      await tester.drag(find.byType(Refresher), const Offset(0, 1500));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await tester.fling(find.byType(Refresher), const Offset(0, 300), 1000);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await settle(tester, frames: 8);
      verify(
        () => scaffold.repository.cdrSellersSellerIdProductsGet(
          sellerId: 'seller-1',
        ),
      ).called(2);

      // A second seller whose products carry no tickets takes the empty
      // branch instead of the ticket cards.
      await tester.tap(find.text('Snack'));
      await settle(tester, frames: 6);
      expect(find.text('No scannable products'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
