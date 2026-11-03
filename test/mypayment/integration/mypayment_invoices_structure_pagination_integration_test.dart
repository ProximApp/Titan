import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../mypayment_fixtures.dart';

Invoice invoice(String id, String reference, Structure structure) =>
    Invoice.empty().copyWith(
      id: id,
      reference: reference,
      structureId: structure.id,
      creation: DateTime(2026, 1, 5),
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 31),
      total: 1500,
      structure: structure,
    );

/// The structure invoices page's pagination row: the two page arrows (the
/// left one disabled on the first page) and the page-size dropdown, each of
/// which re-fetches with new parameters.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the page arrows and the page size reload the list', (
    tester,
  ) async {
    final bde = structureFixture('structure-1', 'BDE', 'user-1');
    stubInvoicePreviews(scaffold);
    stubStructureInvoiceList(
      scaffold,
      invoices: [
        for (var i = 0; i < 20; i++)
          invoice('inv-$i', 'FA-2026-${i.toString().padLeft(3, '0')}', bde),
      ],
    );

    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'user-1'),
      myStructures: [bde],
      selectedStructure: bde,
    );
    addTearDown(container.dispose);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/mypayment/invoicesStructure',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    expect(find.text('FA-2026-000'), findsOneWidget);

    // The page's own arrows, picked by icon: the invoice cards carry
    // IconButtons of their own.
    Finder arrow(HeroIcons icon) =>
        find.byWidgetPredicate((w) => w is HeroIcon && w.icon == icon);
    final previous = arrow(HeroIcons.arrowLeft);
    final next = arrow(HeroIcons.arrowRight);
    expect(previous, findsOneWidget);
    expect(next, findsOneWidget);

    // A full page leaves the right arrow live.
    await tester.tap(next);
    await settle(tester, frames: 30);
    expect(tester.takeException(), isNull);

    // Now on page two the left arrow goes back.
    await tester.tap(previous);
    await settle(tester, frames: 30);
    expect(tester.takeException(), isNull);

    // Picking another page size re-fetches too.
    await tester.tap(find.text('20').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('50').last);
    await settle(tester, frames: 30);

    expect(find.text('50'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
