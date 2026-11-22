import 'dart:async';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

AppModulesCdrSchemasCdrTicket usableTicket(String id) =>
    AppModulesCdrSchemasCdrTicket.empty().copyWith(
      id: id,
      name: 'Soirée des clubs',
      scanLeft: 1,
      expiration: DateTime(2100),
    );

/// The main page's ticket list. One arm stays dark through every state this
/// file mounts: the `orElse` of `ticketList.maybeWhen`
/// (`purchasesTicketsError`). That `maybeWhen` sits INSIDE
/// `AsyncChild(value: ticketList, builder: …)`, and `AsyncChild` calls its
/// builder from the `data:` arm of that very value (`async_child.dart`), so by
/// the time the closure runs the value is data and the fallback cannot win.
///
/// ATTEMPTED, one mount per state, each asserted: data with no tickets renders
/// "No tickets"; data with tickets renders the cards; a load that never
/// completes renders AsyncChild's `Loader`; a load that failed renders
/// AsyncChild's own `An error occured:<error>` — and in both of the last two
/// the ticket column is never built, so "Error loading tickets" (the real
/// `purchasesTicketsError` text, which an earlier version of this file spelled
/// "Error while loading tickets") never reaches the screen. The `orElse` is
/// the cost of a non-exhaustive re-read, not a state a user can be in.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  group('Purchases main page', () {
    // NOTE on ordering: qlevar_router 1.12.4 silently drops the first
    // mid-test QR.to() to a route that is not yet mounted when an earlier
    // test already ran in the same isolate (the route is added to the QR
    // history but the page is never appended and no listener is notified).
    // Verified by bisect: every test passes in isolation and the
    // navigation test passes when run first, but fails when it follows
    // another test. The navigation test is therefore kept first here, and
    // the remaining tests only assert on already-mounted routes.
    testWidgets('tapping a ticket opens the QR page and fetches the secret', (
      tester,
    ) async {
      when(() => scaffold.repository.cdrUsersMeTicketsGet()).thenAnswer(
        (_) async =>
            chopper.Response(http.Response('body', 200), [usableTicket('t-1')]),
      );
      when(
        () => scaffold.repository.cdrUsersMeTicketsTicketIdSecretGet(
          ticketId: any(named: 'ticketId'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response(
          http.Response('body', 200),
          TicketSecret.empty().copyWith(qrCodeSecret: 'secret-abc'),
        ),
      );

      final container = scaffold.makeContainer();
      await scaffold.pumpApp(tester, container, initialPath: '/purchases');
      await settle(tester);

      await tester.tap(find.text('Soirée des clubs'));
      await settle(tester, frames: 16);

      expect(QR.currentPath, '/purchases/ticket');
      // The page renders the ticket's own scan counter. (The QR image
      // itself can never appear through this flow: main_page discards
      // loadTicketSecret()'s result instead of storing it, so the page
      // keeps showing the loader — an app quirk, asserted as-is here.)
      expect(find.text('Scans remaining: 1'), findsOneWidget);
      verify(
        () => scaffold.repository.cdrUsersMeTicketsTicketIdSecretGet(
          ticketId: 't-1',
        ),
      ).called(1);
    });

    testWidgets('lists the user tickets with their scan count', (tester) async {
      when(() => scaffold.repository.cdrUsersMeTicketsGet()).thenAnswer(
        (_) async =>
            chopper.Response(http.Response('body', 200), [usableTicket('t-1')]),
      );

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(),
        initialPath: '/purchases',
      );
      await settle(tester);

      expect(find.text('Soirée des clubs'), findsOneWidget);
      // The error list beside the rows (`main_page.dart`'s
      // `ticketList.maybeWhen(... orElse: () => [Text(ticketsError)])`) is
      // dead: it re-reads the very AsyncValue this AsyncChild builder was
      // handed, which is data by the time the builder runs, so the orElse
      // arm can never win.
      expect(find.text('Error loading tickets'), findsNothing);
      // Non-admin users get the history entry but no scan button.
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Scan'), findsNothing);
    });

    testWidgets('shows the empty state without tickets', (tester) async {
      when(() => scaffold.repository.cdrUsersMeTicketsGet()).thenAnswer(
        (_) async => chopper.Response(
          http.Response('body', 200),
          <AppModulesCdrSchemasCdrTicket>[],
        ),
      );

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(),
        initialPath: '/purchases',
      );
      await settle(tester);

      expect(find.textContaining('No tickets'), findsOneWidget);
    });

    testWidgets('a pending load shows the loader, not the ticket column', (
      tester,
    ) async {
      // Never complete: the page stays in AsyncChild's loading arm, which
      // builds its own Loader instead of calling the ticket builder.
      final pending =
          Completer<chopper.Response<List<AppModulesCdrSchemasCdrTicket>>>();
      when(() => scaffold.repository.cdrUsersMeTicketsGet())
          .thenAnswer((_) => pending.future);

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(),
        initialPath: '/purchases',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 10);

      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.textContaining('No tickets'), findsNothing);
      expect(find.text('Error loading tickets'), findsNothing);
      // The page itself is up: only the list slot is held by the loader.
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('a failed load is answered above the ticket list', (
      tester,
    ) async {
      when(() => scaffold.repository.cdrUsersMeTicketsGet()).thenAnswer(
        (_) async =>
            chopper.Response(http.Response('boom', 500), null, error: 'boom'),
      );

      await scaffold.pumpApp(
        tester,
        // Riverpod 3 retries a failing provider by default; opt out so the
        // failure reaches the widget inside this test's frames.
        scaffold.makeContainer(retry: (count, error) => null),
        initialPath: '/purchases',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 14);

      // AsyncChild's error builder answers — the localized ticket-list error
      // is unreachable behind it, and the column is not built at all.
      expect(find.textContaining('An error occured'), findsOneWidget);
      expect(find.text('Error loading tickets'), findsNothing);
      expect(find.textContaining('No tickets'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
