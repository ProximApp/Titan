import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/ui/components/offer_ticket_modal.dart';

import '../../shared/app_scaffold.dart';

/// The transfer sheet (`offer_ticket_modal.dart`, 49 executable lines):
/// the email validator, the success round-trip (pop + toast + ticket
/// reload) and the three backend error mappings — the not-owner, the
/// not-found and the generic failure.
///
/// Mounted through the real journey: `/tickets` lists one transferable
/// ticket (not scanned, session in the future) whose card opens the
/// sheet. Every test deep-links the SAME path (convention 10).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  models.AppCoreTicketsSchemasTicketsTicketComplete transferableTicket() =>
      models.AppCoreTicketsSchemasTicketsTicketComplete.empty().copyWith(
        id: 't-1',
        scanned: false,
        event: models.EventSimple.empty().copyWith(id: 'e-1', name: 'Gala'),
        category: models.Category.empty().copyWith(id: 'c-1', name: 'Normal'),
        session: models.Session.empty().copyWith(
          id: 's-1',
          name: 'Vendredi',
          startDatetime: DateTime(2100),
        ),
      );

  Future<void> pumpTickets(WidgetTester tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    // The real MyStoresNotifier.build fires this endpoint; a plain user
    // has no stores, which also keeps the admin button off the page.
    when(() => scaffold.repository.mypaymentUsersMeStoresGet())
        .thenAnswer((_) async => chopperListResponse(<models.UserStore>[]));
    when(() => scaffold.repository.ticketsUserMeTicketsGet())
        .thenAnswer((_) async => chopperListResponse([transferableTicket()]));
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets',
      pumpAndSettle: false,
    );
    await settle(tester);
  }

  Finder modalButton() => find.descendant(
    of: find.byType(OfferTicketModal),
    matching: find.text('Transfer this ticket'),
  );

  Finder modalEmailField() => find.descendant(
    of: find.byType(OfferTicketModal),
    matching: find.byType(TextFormField).first,
  );

  testWidgets('the sheet refuses an invalid email before any request', (
    tester,
  ) async {
    await pumpTickets(tester);

    await scaffold.openModal(tester, find.text('Transfer this ticket'));
    expect(scaffold.isModalOpen(tester), isTrue);
    expect(find.text('Email'), findsOneWidget);
    expect(
      find.text(
        'The recipient will receive an email to accept the transfer. '
        'Any pending invitation will be replaced.',
      ),
      findsOneWidget,
    );

    await tester.enterText(modalEmailField(), 'not-an-email');
    await scaffold.tapInModal(tester, modalButton());

    expect(find.text('Invalid email address'), findsOneWidget);
    verifyNever(
      () => scaffold.repository.ticketsUserMeTicketsChangeOverRequestPost(
        body: any(named: 'body'),
      ),
    );
    // A refused submit never closes the sheet.
    expect(scaffold.isModalOpen(tester), isTrue);
  });

  testWidgets('a valid transfer sends the invitation and reloads the list', (
    tester,
  ) async {
    await pumpTickets(tester);
    when(
      () => scaffold.repository.ticketsUserMeTicketsChangeOverRequestPost(
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<void>(http.Response('ok', 200), null),
    );

    await scaffold.openModal(tester, find.text('Transfer this ticket'));
    await tester.enterText(modalEmailField(), 'ada@example.com');
    // Drop the mount-time ticket loads so the verify below counts ONLY
    // the post-success reload (mocktail's verify consumes matched calls).
    clearInteractions(scaffold.repository);

    await scaffold.tapInModal(tester, modalButton());
    await settle(tester, frames: 6);

    expect(scaffold.isModalOpen(tester), isFalse);
    expect(find.text('Transfer invitation sent'), findsOneWidget);
    verify(() => scaffold.repository.ticketsUserMeTicketsGet()).called(1);
    // The exact invitation body travels to the wire.
    final body = verify(
      () => scaffold.repository.ticketsUserMeTicketsChangeOverRequestPost(
        body: captureAny(named: 'body'),
      ),
    ).captured;
    expect(
      (body.single as models.TicketChangeOverInvitation).email,
      'ada@example.com',
    );
    expect((body.single as models.TicketChangeOverInvitation).ticketId, 't-1');
    await scaffold.drainToast(tester);
  });

  testWidgets('backend refusals map to their own error strings', (
    tester,
  ) async {
    await pumpTickets(tester);

    Future<void> refuse(String error) async {
      when(
        () => scaffold.repository.ticketsUserMeTicketsChangeOverRequestPost(
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response<void>(
          http.Response(error, 500),
          null,
          error: error,
        ),
      );
      await tester.enterText(modalEmailField(), 'ada@example.com');
      await scaffold.tapInModal(tester, modalButton());
      await settle(tester, frames: 6);
    }

    await scaffold.openModal(tester, find.text('Transfer this ticket'));

    await refuse('User is not the owner');
    expect(find.text('You are not the owner of this ticket'), findsOneWidget);
    await scaffold.drainToast(tester);

    await refuse('Ticket not found');
    expect(find.text('Ticket not found'), findsOneWidget);
    await scaffold.drainToast(tester);

    await refuse('boom');
    expect(find.text('Failed to send transfer invitation'), findsOneWidget);
    await scaffold.drainToast(tester);

    // A refusal never closes the sheet.
    expect(scaffold.isModalOpen(tester), isTrue);
  });
}
