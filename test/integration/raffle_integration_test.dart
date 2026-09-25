import 'package:auto_size_text/auto_size_text.dart';
import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/raffle/ui/pages/main_page/ticket_card.dart';
import 'package:titan/raffle/ui/pages/raffle_page/raffle_page.dart';

import 'app_scaffold.dart';

chopper.Response<T> chopperResponse<T>(T body) =>
    chopper.Response(http.Response('body', 200), body);

chopper.Response<List<T>> chopperListResponse<T>(List<T> body) =>
    chopper.Response(http.Response('body', 200), body);

Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [
    CoreGroupSimple(
      name: 'admin_raffle',
      id: '0a25cb76-4b63-4fd3-b939-da6d9feabf28',
    ),
  ],
);

RaffleComplete raffle(String id, String name, RaffleStatusType? status) =>
    RaffleComplete.empty().copyWith(
      id: id,
      name: name,
      groupId: 'group-1',
      description: 'A good cause',
      status: status,
    );

AppModulesRaffleSchemasRaffleTicketComplete ticket(
  String id,
  String raffleId, {
  int packSize = 1,
  int price = 200,
  PrizeSimple? prize,
}) => AppModulesRaffleSchemasRaffleTicketComplete.empty().copyWith(
  id: id,
  packId: 'pack-$id',
  userId: 'user-1',
  prize: prize,
  packTicket: PackTicketSimple.empty().copyWith(
    id: 'pack-$id',
    raffleId: raffleId,
    packSize: packSize,
    price: price,
  ),
);

void stubRaffleList(IntegrationScaffold scaffold) {
  // The main page loads the raffle list plus the user tickets (through the
  // JWT-derived idProvider, overridden on the container), and each raffle
  // card then pulls its own stats and logo.
  when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
    (_) async => chopperListResponse([
      raffle('r-open', 'Gala(open)', RaffleStatusType.open),
    ]),
  );
  when(
    () => scaffold.repository.tombolaUsersUserIdTicketsGet(
      userId: any(named: 'userId'),
    ),
  ).thenAnswer(
    (_) async =>
        chopperListResponse(<AppModulesRaffleSchemasRaffleTicketComplete>[]),
  );
  when(
    () => scaffold.repository.tombolaRafflesRaffleIdStatsGet(
      raffleId: any(named: 'raffleId'),
    ),
  ).thenAnswer(
    (_) async => chopperResponse(
      RaffleStats.empty().copyWith(ticketsSold: 42, amountRaised: 150),
    ),
  );
  // A 404 reads as "no bytes" and the card falls back to the placeholder
  // asset instead of crashing on invalid image data.
  when(
    () => scaffold.repository.tombolaRafflesRaffleIdLogoGet(
      raffleId: any(named: 'raffleId'),
    ),
  ).thenAnswer(
    (_) async => chopper.Response<List<int>>(
      http.Response('{"detail": "File does not exist"}', 404),
      [],
      error: 'File does not exist',
    ),
  );
}

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

  group('Raffle main page', () {
    // NOTE on ordering: qlevar_router 1.12.4 silently drops the first
    // mid-test QR.to() to a route that is not yet mounted when an earlier
    // test already ran in the same isolate. The navigation test is kept
    // first; the remaining tests only assert on already-mounted routes.
    testWidgets('admin button opens the raffle admin page', (tester) async {
      // Empty raffle list: the header (with the admin button) still renders,
      // but no raffle card mounts — an embedded card crashes debug-mode
      // layout (see the ticket-card group below).
      when(
        () => scaffold.repository.tombolaRafflesGet(),
      ).thenAnswer((_) async => chopperListResponse(<RaffleComplete>[]));
      when(
        () => scaffold.repository.tombolaUsersUserIdTicketsGet(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer(
        (_) async => chopperListResponse(
          <AppModulesRaffleSchemasRaffleTicketComplete>[],
        ),
      );
      when(() => scaffold.repository.tombolaUsersCashGet()).thenAnswer(
        (_) async =>
            chopperListResponse(<AppModulesRaffleSchemasRaffleCashComplete>[]),
      );
      when(
        () => scaffold.repository.groupsGet(),
      ).thenAnswer((_) async => chopperListResponse(<CoreGroupSimple>[]));

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(user: adminUser),
        initialPath: '/tombola',
      );
      await settle(tester);

      await tester.tap(find.text('Admin'));
      await settle(tester, frames: 16);

      expect(QR.currentPath, '/tombola/admin');
      // The admin page's raffle handler section header.
      expect(find.text('Raffle'), findsOneWidget);
    });

    testWidgets('shows the empty state without raffles or tickets', (
      tester,
    ) async {
      when(
        () => scaffold.repository.tombolaRafflesGet(),
      ).thenAnswer((_) async => chopperListResponse(<RaffleComplete>[]));
      when(
        () => scaffold.repository.tombolaUsersUserIdTicketsGet(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer(
        (_) async => chopperListResponse(
          <AppModulesRaffleSchemasRaffleTicketComplete>[],
        ),
      );

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(user: CoreUser.empty().copyWith(id: 'user-1')),
        initialPath: '/tombola',
      );
      await settle(tester);

      expect(find.text('You have no ticket'), findsOneWidget);
      expect(find.text('There is no ongoing raffle'), findsOneWidget);
      // Non-admin users get no admin entry.
      expect(find.text('Admin'), findsNothing);
    });

    // NOTE: /tombola/detail is a nested child route; mounted through the
    // shell its content never builds (the parent page's TopBar is all that
    // renders), and with a seeded raffle list the parent page lays out a
    // raffle card whose embedded Scaffold crashes debug-mode layout. The
    // detail page is therefore covered by the standalone test below.

    // NOTE: a deep link to /tombola/detail as a non-admin does NOT bounce
    // cleanly: AuthenticatedMiddleware forwards the deep-linked path into
    // pathForwarding, AdminMiddleware redirects to /, and the auth
    // middleware at / then sends the user back to the forwarded path — an
    // infinite redirect loop (real app bug, documented but not asserted).
  });

  group('Raffle detail page with data', () {
    // The page under its route shell is not reachable cleanly (see the
    // main-page group note); it is exercised standalone — its Scaffold at
    // the widget root is properly bounded — to cover the data-driven
    // branches.
    testWidgets('renders name, balance, prizes and description', (
      tester,
    ) async {
      when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
        (_) async => chopperListResponse([
          raffle('r-1', 'Gala(open)', RaffleStatusType.open),
        ]),
      );
      when(
        () => scaffold.repository.tombolaUsersUserIdCashGet(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer(
        (_) async => chopperResponse(
          AppModulesRaffleSchemasRaffleCashComplete.empty().copyWith(
            userId: 'user-1',
            balance: 1250,
          ),
        ),
      );
      when(
        () => scaffold.repository.tombolaRafflesRaffleIdPrizesGet(
          raffleId: any(named: 'raffleId'),
        ),
      ).thenAnswer(
        (_) async => chopperListResponse([
          PrizeSimple.empty().copyWith(
            name: 'PS5',
            raffleId: 'r-1',
            quantity: 1,
            id: 'prize-1',
          ),
        ]),
      );
      when(
        () => scaffold.repository.tombolaRafflesRaffleIdPackTicketsGet(
          raffleId: any(named: 'raffleId'),
        ),
      ).thenAnswer((_) async => chopperListResponse(<PackTicketSimple>[]));

      final container = scaffold.makeContainer(user: adminUser);
      // Selecting the raffle BEFORE the first build so every provider
      // (prizes, tickets) derives from it exactly like a card tap would.
      container.read(raffleIdProvider.notifier).setId('r-1');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en', 'US'), Locale('fr', 'FR')],
            home: const RaffleInfoPage(),
          ),
        ),
      );
      await settle(tester, frames: 16);

      expect(find.text('Gala(open)'), findsOneWidget);
      // The raffle balance renders raw (already in euros), not cents.
      expect(find.textContaining('1250.00'), findsOneWidget);
      expect(find.textContaining('PS5'), findsOneWidget);
      expect(find.textContaining('A good cause'), findsOneWidget);
    });
  });

  group('Raffle ticket card', () {
    // The main page embeds each card inside its own RaffleTemplate
    // (a full Scaffold nested in the page's scroll view), which throws
    // unbounded-height assertions in debug mode — a latent app quirk that
    // only release builds tolerate. The cards are therefore exercised
    // standalone in a bounded viewport; everything around them (list
    // grouping, empty state) is covered by the shell tests above.
    testWidgets(
      'renders price and count for plain tickets, prize for winners',
      (tester) async {
        when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
          (_) async => chopperListResponse([
            raffle('r-1', 'Soirée des clubs', RaffleStatusType.open),
          ]),
        );

        final container = scaffold.makeContainer(
          user: CoreUser.empty().copyWith(id: 'user-1'),
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en', 'US'), Locale('fr', 'FR')],
              home: Scaffold(
                body: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: TicketWidget(
                        ticket: [ticket('t-1', 'r-1'), ticket('t-2', 'r-1')],
                        price: 2.0,
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: TicketWidget(
                        ticket: [
                          ticket(
                            't-3',
                            'r-1',
                            prize: PrizeSimple.empty().copyWith(name: 'PS5'),
                          ),
                        ],
                        price: 5.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await settle(tester);

        // Plain tickets display the pack's unit price (2.00 / 1) and their
        // count; the card uses AutoSizeText (a RichText), so assertions go
        // through widget predicates instead of find.text.
        AutoSizeText text(String data) => tester
            .widgetList<AutoSizeText>(
              find.byWidgetPredicate((w) => w is AutoSizeText),
            )
            .firstWhere(
              (t) => t.data == data,
              orElse: () => throw TestFailure('missing AutoSizeText "$data"'),
            );
        expect(text('2.00 €'), isNotNull);
        expect(text('2 tickets'), isNotNull);
        expect(text('Soirée des clubs'), isNotNull);
        // Winning tickets display their prize instead of a price.
        expect(text('Winner !'), isNotNull);
        expect(text('PS5'), isNotNull);
      },
    );
  });
}
