import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/purchases/ui/pages/main_page/custom_button.dart';
// Two different TicketCard classes share one name, so the imports need
// prefixes (snake_case, for `library_prefixes`).
import 'package:titan/purchases/ui/pages/main_page/ticket_card.dart'
    as purchases_main_ticket;
import 'package:titan/purchases/ui/pages/scan_page/ticket_card.dart'
    as purchases_scan_ticket;
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level tests for the purchases rows the fixed-width sweep could not
/// reach: the two `TicketCard` classes (the main-page list row and the
/// scan-page row) and the `CustomButton` pair on the main page header.
///
/// The sweep found only `PurchaseCard` here, because none of these three
/// hardcodes a width. That is exactly why they need their own file: a
/// `width: double.infinity` card is *not* protected by a hardcoded number,
/// it is protected by whatever its children do — and both rows put an
/// unconstrained `Column` next to a `Spacer` inside a `Row`, the same shape
/// that overflowed `AdminAdvertCard` by 37px in ledger #47.
///
/// The buttons are mounted in the page's own header shape
/// (`Padding(all: 30) > Row(spaceBetween)`), because a `CustomButton` alone
/// always fits: what overflows is the PAIR at 360px minus 60px of padding.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// A translated label nobody would type in a demo. The French labels on
  /// this page are already close to the limit ("Historique", "Scanner" at
  /// 20pt bold inside 300px), so any locale with a longer word breaks it.
  const longLabel = 'Historique des achats passes';

  AppModulesCdrSchemasCdrTicket ticket({
    String name = 'Ticket',
    int scanLeft = 12,
  }) => AppModulesCdrSchemasCdrTicket.empty().copyWith(
    id: 't-1',
    name: name,
    scanLeft: scanLeft,
    expiration: DateTime(2100, 12, 31),
  );

  testWidgets('the main-page ticket row fits a long name', (tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: purchases_main_ticket.TicketCard(
            ticket: ticket(
              name: 'A ticket name that is far too long for a 320px card',
            ),
            onClicked: () {},
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(purchases_main_ticket.TicketCard), findsOneWidget);
    expect(find.textContaining('12 scans restants'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the main-page ticket row fits its sold-out state too', (
    tester,
  ) async {
    // scanLeft == 0 greys the card and disables the tap, so the label
    // changes from "restant(s)" to "restant" — the same row, one word shorter.
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: purchases_main_ticket.TicketCard(
            ticket: ticket(name: longLabel, scanLeft: 0),
            onClicked: () {},
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(purchases_main_ticket.TicketCard), findsOneWidget);
    expect(find.textContaining('0 scan restant -'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the scan-page ticket row fits a long name and use limit', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: purchases_scan_ticket.TicketCard(
            ticket: GenerateTicketComplete.empty().copyWith(
              id: 't-1',
              name: 'A generated ticket name that is far too long for the row',
              maxUse: 12500,
              expiration: DateTime(2100, 12, 31),
            ),
            product: AppModulesCdrSchemasCdrProductComplete.empty().copyWith(
              id: 'p-1',
            ),
            onClicked: () {},
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(purchases_scan_ticket.TicketCard), findsOneWidget);
    // The limit line is a single hand-built string: maxUse, the plural, the
    // "valid until" clause and a localized date, all in one Text. The
    // "maximun" spelling is the one in lib/ today, asserted as-is so this
    // test reports a layout change rather than a copy change.
    expect(find.textContaining('12500 scans maximun'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  /// The purchases main page's header, verbatim: `Padding(all: 30)` around a
  /// `Row(spaceBetween)` whose children are Flexible so each button is
  /// capped at half of the 300px that the padding leaves. A `CustomButton`
  /// always fits alone; what overflowed was the PAIR, so the pair is the
  /// fixture.
  Widget headerPair(String history, String scan) => Padding(
    padding: const EdgeInsets.all(30),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: CustomButton(
            icon: HeroIcons.clock,
            text: history,
            onTap: () {},
          ),
        ),
        Flexible(
          child: CustomButton(
            icon: HeroIcons.viewfinderCircle,
            text: scan,
            onTap: () {},
          ),
        ),
      ],
    ),
  );

  testWidgets('the header button pair fits two short labels', (tester) async {
    // The real English labels.
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(body: headerPair('History', 'Scan')),
      container,
      appFonts: true,
    );

    expect(find.byType(CustomButton), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the header button pair fits two long labels', (tester) async {
    // The same pair with labels a real translation can reach.
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(body: headerPair(longLabel, 'Scanner les tickets')),
      container,
      appFonts: true,
    );

    expect(find.byType(CustomButton), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('a lone button survives an unbounded parent row', (tester) async {
    // The label is Flexible, which is illegal under an unbounded width
    // unless the row shrink-wraps. A component that throws a layout
    // assertion in a plain Row is a landmine for the next caller, so this
    // guards the MainAxisSize.min that makes it safe.
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: Row(
          children: [
            CustomButton(icon: HeroIcons.clock, text: longLabel, onTap: () {}),
          ],
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(CustomButton), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
