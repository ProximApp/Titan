import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tickets/ui/components/user_ticket_card.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';

import '../../shared/app_scaffold.dart';

/// Behaviour tests for [UserTicketCard]'s transfer gate.
///
/// The card sweep mounts this widget for layout only, so nothing reached the
/// three `TicketTransferBlockReason` arms or the "no session yet" exemption in
/// `transferBlockReason`. Those decide whether a user can hand a ticket over,
/// which is the one thing this card actually enforces — the text on screen is
/// the only signal a user gets.
///
/// One arm of that message builder cannot be selected, and it was tried by
/// mounting the card, not by reading it. The third case is
/// `TicketTransferBlockReason.transferable`, and the block is rendered inside
/// `if (!isTransferable)`; `isTransferable` is *defined* as
/// `transferBlockReason == TicketTransferBlockReason.transferable`
/// (`user_ticket.dart`), so the only value that selects that case is the one
/// value that suppresses the call. The first test mounts exactly that ticket
/// and asserts what renders: the live button (a non-null `onTap`), no block
/// text at all, and specifically no "This ticket cannot be transferred".
///
/// The other direction is mounted too, because the argument above only holds
/// if blocked tickets really do get their explanation — the two tests below
/// assert the sentence AND the dead control (a null `onTap`) a scanned ticket
/// and a past session render, so no blocked user is left with a button that
/// silently does nothing.
///
/// The live direction is an interaction, not a field check: the transferable
/// test taps the button and asserts the transfer sheet is on screen. That is
/// the observable difference the guard makes, and it is also why the third
/// arm's text is dead twice over — `ticketsOfferNotTransferable` is referenced
/// by that arm and by nothing else in `lib/`, so the localized string has no
/// screen on which to appear.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  AppCoreTicketsSchemasTicketsTicketComplete ticket({
    bool scanned = false,
    String sessionId = 's1',
    DateTime? start,
    int price = 1250,
  }) => AppCoreTicketsSchemasTicketsTicketComplete(
    id: 'ticket-1',
    userId: 'user-1',
    price: price,
    scanned: scanned,
    eventId: 'event-1',
    categoryId: 'category-1',
    sessionId: sessionId,
    category: Category.empty().copyWith(name: 'VIP'),
    session: Session.empty().copyWith(
      id: sessionId,
      name: 'Evening',
      startDatetime: start ?? DateTime(2100, 3, 4, 5, 6),
    ),
    user: CoreUserSimple.empty(),
    answers: const [],
    event: EventSimple.empty().copyWith(name: 'Gala'),
  );

  Future<void> mount(
    WidgetTester tester,
    AppCoreTicketsSchemasTicketsTicketComplete theTicket,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(child: UserTicketCard(ticket: theTicket)),
      ),
      container,
      locale: const Locale('en', 'US'),
      appFonts: true,
    );
  }

  testWidgets('an unblocked ticket offers the transfer button', (tester) async {
    await mount(tester, ticket());

    expect(find.text('Transfer this ticket'), findsOneWidget);
    // No block message when the ticket is transferable.
    expect(find.textContaining('can no longer be transferred'), findsNothing);
    // Not even the `transferable` case's own message can appear: the guard
    // that would render it is the one that excludes it.
    expect(find.text('This ticket cannot be transferred'), findsNothing);
    // 1250 cents is printed in euros, without a trailing zero.
    expect(find.text('12.5€'), findsOneWidget);

    // The button is live: the gesture has a callback rather than the
    // disabled shape a blocked ticket renders.
    final gesture = tester.widget<GestureDetector>(
      find
          .ancestor(
            of: find.text('Transfer this ticket'),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    expect(gesture.onTap, isNotNull);

    // And the callback really opens the transfer sheet: the guard's effect is
    // a sheet on screen, not just a non-null field.
    await tester.tap(find.text('Transfer this ticket'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomModalTemplate), findsOneWidget);
    expect(find.text('This ticket cannot be transferred'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a scanned ticket reports that it is already used', (
    tester,
  ) async {
    await mount(tester, ticket(scanned: true));

    expect(
      find.text(
        'This ticket has already been used and can no longer be transferred',
      ),
      findsOneWidget,
    );

    // And the control is not tappable: the explanation sits under a disabled
    // button rather than a live one that would fail on the server.
    final gesture = tester.widget<GestureDetector>(
      find
          .ancestor(
            of: find.text('Transfer this ticket'),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    expect(gesture.onTap, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a past session reports the date and time it started', (
    tester,
  ) async {
    await mount(tester, ticket(start: DateTime(2020, 3, 4, 5, 6)));

    // The message interpolates the session start in the card's own
    // dd/MM/yyyy and HH:mm formats.
    expect(
      find.textContaining('already passed (04/03/2020 at 05:06)'),
      findsOneWidget,
    );
    // The expired case blocks the same way the used one does.
    final gesture = tester.widget<GestureDetector>(
      find
          .ancestor(
            of: find.text('Transfer this ticket'),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    expect(gesture.onTap, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty session id stays transferable even with a past start', (
    tester,
  ) async {
    // `transferBlockReason` only consults the start date once the session has
    // an id, so a ticket whose session is not booked yet can still be handed
    // over. Without this guard every unscheduled ticket would look expired.
    await mount(tester, ticket(sessionId: '', start: DateTime(2000, 1, 1)));

    expect(find.text('Transfer this ticket'), findsOneWidget);
    expect(find.textContaining('already passed'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
