import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../../shared/app_scaffold.dart';

AppModulesCdrSchemasCdrProductComplete product(
  String name, {
  String? description,
}) => AppModulesCdrSchemasCdrProductComplete.empty().copyWith(
  nameFr: name,
  descriptionFr: description,
);

PurchaseReturn purchase({
  required String name,
  required bool validated,
  String? description,
  int quantity = 2,
  int priceCents = 350,
  int year = 2026,
}) => PurchaseReturn.empty().copyWith(
  product: product(name, description: description),
  validated: validated,
  quantity: quantity,
  price: priceCents,
  purchasedOn: DateTime(year, 6, 15),
);

/// The history list and the purchase detail page it pushes, in one
/// router-pushing test (convention 19): the year chips built from the
/// purchase years, both card branches (paid price line / not-paid banner),
/// and the card tap that pushes the detail page.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'history lists the current-year purchases and a card tap opens the detail',
    (tester) async {
      when(() => scaffold.repository.cdrMePurchasesGet()).thenAnswer(
        (_) async => chopperListResponse<PurchaseReturn>([
          purchase(
            name: 'Consumption',
            validated: true,
            description: 'Two drinks',
          ),
          purchase(name: 'Deferred payment', validated: false),
          // Another year: filtered out of the default view (SizedBox
          // branch) but present once its chip is selected.
          purchase(name: 'Last year', validated: true, year: 2025),
        ]),
      );

      final container = scaffold.makeContainer();
      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/purchases/history',
      );
      await settle(tester, frames: 16);

      // The year chip strip is built from the purchase years.
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('2025'), findsOneWidget);
      expect(find.text('Consumption'), findsOneWidget);
      expect(find.text('Deferred payment'), findsOneWidget);
      // The paid card shows its price line; the unpaid one its banner.
      expect(find.text('2 x 3.5 €'), findsOneWidget);
      expect(find.text('Not validated'), findsWidgets);
      expect(find.text('Last year'), findsNothing);
      expect(tester.takeException(), isNull);

      // Pull to refresh reloads the purchase list.
      await tester.drag(find.byType(Refresher), const Offset(0, 1500));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await tester.fling(find.byType(Refresher), const Offset(0, 300), 1000);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await settle(tester, frames: 8);
      verify(() => scaffold.repository.cdrMePurchasesGet()).called(2);

      // Selecting the other year swaps the visible cards.
      await tester.tap(find.text('2025'));
      await settle(tester, frames: 6);
      expect(find.text('Last year'), findsOneWidget);
      expect(find.text('Consumption'), findsNothing);

      await tester.tap(find.text('2026'));
      await settle(tester, frames: 6);

      // Tapping the unpaid card pushes the detail page with the banner.
      await tester.tap(find.text('Deferred payment'));
      await settle(tester, frames: 16);

      expect(QR.currentPath, '/purchases/history/purchase');
      expect(find.text('Deferred payment'), findsOneWidget);
      expect(find.text('Not validated'), findsOneWidget);

      // The detail page's refresh closure is a no-op but must still run.
      await tester.drag(find.byType(Refresher), const Offset(0, 1500));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await settle(tester, frames: 8);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the detail page drops the banner for a validated purchase', (
    tester,
  ) async {
    when(() => scaffold.repository.cdrMePurchasesGet()).thenAnswer(
      (_) async => chopperListResponse<PurchaseReturn>([
        purchase(
          name: 'Consumption',
          validated: true,
          description: 'Two drinks',
        ),
      ]),
    );

    final container = scaffold.makeContainer();
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/purchases/history',
    );
    await settle(tester, frames: 16);

    await tester.tap(find.text('Consumption'));
    await settle(tester, frames: 16);

    expect(QR.currentPath, '/purchases/history/purchase');
    // Name, description… but no unpaid banner on a validated purchase.
    expect(find.text('Consumption'), findsOneWidget);
    expect(find.text('Two drinks'), findsOneWidget);
    expect(find.text('Not validated'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty history says so instead of a blank page', (
    tester,
  ) async {
    when(() => scaffold.repository.cdrMePurchasesGet()).thenAnswer(
      (_) async => chopperListResponse<PurchaseReturn>(<PurchaseReturn>[]),
    );

    final container = scaffold.makeContainer();
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/purchases/history',
    );
    await settle(tester, frames: 16);

    expect(find.text('No purchase'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failing history load shows the error builder', (tester) async {
    when(() => scaffold.repository.cdrMePurchasesGet())
        .thenThrow(Exception('backend down'));

    final container = scaffold.makeContainer();
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/purchases/history',
    );
    await settle(tester, frames: 16);

    expect(find.text('Error loading purchases'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
