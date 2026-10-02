import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tickets/adapters/ticket_event.dart';
import 'package:titan/tickets/ui/components/edit_ticket_event_helpers.dart';
import 'package:titan/tickets/ui/components/read_only_banner.dart';
import 'package:titan/tickets/ui/components/sold_out_badge.dart';
import 'package:titan/tickets/ui/components/stat_tile.dart';
import 'package:titan/tickets/ui/components/switch_row.dart';
import 'package:titan/tickets/ui/components/ticket_event_card.dart';
import 'package:titan/tickets/ui/components/ticket_event_status_chip.dart';
import 'package:titan/tools/constants.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level tests for the tickets rows the fixed-width sweep could not
/// reach.
///
/// The sweep mounts `SessionCard`, `StatsCard`, `TarifCard` and
/// `UserTicketCard` — the four that hardcode a width. This file covers the
/// other eight leaves of the module: the event list row, its status chip in
/// all four states, the section card the edit page composes, the stat tile
/// at its real half-width, the switch row in both its editable and read-only
/// shapes, the sold-out badge and the read-only banner.
///
/// `TicketEventCard` is the interesting one: it renders through
/// `ListItemTemplate` with a `TicketEventStatusChip` as the trailing slot,
/// so the row's elastic budget is the phone width MINUS a chip whose own
/// width is whatever the longest status label needs. That is the shape that
/// decides whether a long event name wraps to two lines or three.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  const longEventName =
      'Soiree de gala de l association des etudiants en medecine';

  EventSimple event({
    String name = longEventName,
    bool disabled = false,
    DateTime? open,
    DateTime? close,
  }) => EventSimple.empty().copyWith(
    id: 'e-1',
    name: name,
    storeId: 'store-1',
    // The status extension derives its chip from these three, so each state
    // is reached by moving a date rather than by faking a status.
    openDatetime: open ?? DateTime(2100, 1, 1),
    closeDatetime: close,
    disabled: disabled,
  );

  testWidgets('the event row fits a long name in every status', (tester) async {
    // The four states are four different trailing chip widths, so the row is
    // mounted once per state rather than once for the default.
    final states = <(String, EventSimple)>[
      ('upcoming', event()),
      ('open', event(open: DateTime(2020, 1, 1), close: DateTime(2100))),
      ('closed', event(open: DateTime(2020, 1, 1), close: DateTime(2021))),
      ('disabled', event(disabled: true, open: DateTime(2020, 1, 1))),
    ];

    for (final (label, theEvent) in states) {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);

      await scaffold.pumpWidgetApp(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: TicketEventCard(ticketEvent: theEvent),
          ),
        ),
        container,
        appFonts: true,
      );

      expect(find.byType(TicketEventCard), findsOneWidget, reason: label);
      expect(find.byType(TicketEventStatusChip), findsOneWidget, reason: label);
      // The status really is the one the dates ask for — otherwise the four
      // iterations would be the same row four times and prove nothing.
      expect(
        theEvent.status,
        label == 'upcoming'
            ? TicketEventStatus.upcoming
            : label == 'open'
            ? TicketEventStatus.open
            : label == 'closed'
            ? TicketEventStatus.closed
            : TicketEventStatus.disabled,
        reason: label,
      );
      expect(tester.takeException(), isNull, reason: 'event row ($label)');

      await scaffold.unmountApp(tester);
    }
  });

  testWidgets('the event row renders the opening date in its subtitle', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: TicketEventCard(
            ticketEvent: event(open: DateTime(2100, 3, 4, 5, 6)),
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    // dd/MM/yyyy HH:mm, hard-coded in the card.
    expect(find.textContaining('04/03/2100 05:06'), findsOneWidget);
    expect(find.text(longEventName), findsOneWidget);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the section card fits a long title over its content', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: SectionCard(
            title: 'Questions with an unusually long section title',
            child: const Text('Body'),
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(SectionCard), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the stat tile fits a five-figure value and total side by side', (
    tester,
  ) async {
    // StatsCard gives each tile half the card in an Expanded, so that is the
    // shape to mount: the RichText carries "125000 / 125000" in two spans
    // and the label above it is a translated string.
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Tickets sold',
                  value: 125000,
                  total: 125000,
                  color: ColorConstants.main,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: 'In checkout',
                  value: 125000,
                  color: ColorConstants.gradient1,
                ),
              ),
            ],
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(StatTile), findsNWidgets(2));
    // The value is a RichText of two spans, not a Text, so the finder needs
    // findRichText to see the joined string.
    expect(
      find.textContaining('125000 / 125000', findRichText: true),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the stat tile treats a null value as zero and hides a 0 total', (
    tester,
  ) async {
    // Both branches of `hasTotal` — a null quota prints no " / N" span, and a
    // null value prints "0" rather than "null".
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Sold',
                  value: null,
                  total: null,
                  color: ColorConstants.main,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: 'Sold',
                  value: 7,
                  total: 0,
                  color: ColorConstants.main,
                ),
              ),
            ],
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.text('0', findRichText: true), findsOneWidget);
    // total == 0 is not "hasTotal", so no "/ 0" span is rendered.
    expect(find.textContaining('/', findRichText: true), findsNothing);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the switch row fits a long title in both of its shapes', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              SwitchRow(
                title: 'A very long editable setting title that has to wrap',
                subtitle: 'With a subtitle that is long enough to wrap as well',
                value: true,
                onChanged: (v) {},
              ),
              // A null callback is what renders the row read-only, and the
              // Switch is then disabled — the shape the sold-events edit page
              // shows.
              SwitchRow(
                title: 'A very long read-only setting title that has to wrap',
                value: false,
                onChanged: null,
              ),
            ],
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(SwitchRow), findsNWidgets(2));
    expect(find.byType(Switch), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the sold-out badge and the read-only banner fit', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              // The long default label is the one a locale can produce.
              const SoldOutBadge(label: 'Epuisement des tickets'),
              const SoldOutBadge(fontSize: 18, padding: EdgeInsets.all(12)),
              const ReadOnlyBanner(
                message:
                    'This event has sales, so it can no longer be edited or cancelled',
              ),
            ],
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(SoldOutBadge), findsNWidgets(2));
    expect(find.byType(ReadOnlyBanner), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the status chip fits its longest label alone', (tester) async {
    // Each chip is its own natural width, and the row gives it whatever the
    // elastic title does not need — so an unbounded chip is the shape that
    // would push the row over.
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final status in TicketEventStatus.values)
                TicketEventStatusChip(status: status),
            ],
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(TicketEventStatusChip), findsNWidgets(4));
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
