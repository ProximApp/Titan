import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/generated/openapi.swagger.dart';

import 'app_scaffold.dart';

Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

AppModulesCdrSchemasCdrTicket usableTicket(String id) =>
    AppModulesCdrSchemasCdrTicket.empty().copyWith(
      id: id,
      name: 'Soirée des clubs',
      scanLeft: 1,
      expiration: DateTime(2100),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IntegrationScaffold scaffold;

  setUp(() {
    QR.reset();
    SharedPreferences.setMockInitialValues({});
    scaffold = IntegrationScaffold();
    scaffold.stubInformation();
    scaffold.stubFeed();
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
  });
}
