import 'package:auto_size_text/auto_size_text.dart';
import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/raffle/ui/pages/main_page/ticket_card.dart';
import 'package:titan/raffle/ui/pages/raffle_page/prize_card.dart';
import 'package:titan/raffle/ui/pages/raffle_page/prize_dialog.dart';
import 'package:titan/raffle/ui/pages/raffle_page/raffle_page.dart';

import '../../shared/app_scaffold.dart';
import '../raffle_fixtures.dart';

final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [
    CoreGroupSimple(
      name: 'admin_raffle',
      id: '0a25cb76-4b63-4fd3-b939-da6d9feabf28',
    ),
  ],
);

void stubRaffleList(IntegrationScaffold scaffold) {
  // The main page loads the raffle list plus the user tickets (through the
  // JWT-derived idProvider, overridden on the container), and each raffle
  // card then pulls its own stats and logo.
  when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
    (_) async => chopperListResponse([
      raffleFixture('r-open', 'Gala(open)', RaffleStatusType.open),
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
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  group('Raffle main page', () {
    // NOTE on ordering: qlevar_router 1.12.4 silently drops the first
    // mid-test QR.to() to a route that is not yet mounted when an earlier
    // test already ran in the same isolate. The navigation test is kept
    // first; the remaining tests only assert on already-mounted routes.
    testWidgets('admin button opens the raffle admin page', (tester) async {
      // Empty raffle list: the header (with the admin button) still renders,
      // with no raffle card mounted.
      when(() => scaffold.repository.tombolaRafflesGet())
          .thenAnswer((_) async => chopperListResponse(<RaffleComplete>[]));
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
      when(() => scaffold.repository.groupsGet())
          .thenAnswer((_) async => chopperListResponse(<CoreGroupSimple>[]));

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
      when(() => scaffold.repository.tombolaRafflesGet())
          .thenAnswer((_) async => chopperListResponse(<RaffleComplete>[]));
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
    // renders). The detail page is therefore covered by the standalone
    // test below. A seeded raffle list renders cards in the shell since
    // the card's own RaffleTemplate wrapper was removed — see
    // raffle_main_page_cards_integration_test.

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
          raffleFixture('r-1', 'Gala(open)', RaffleStatusType.open),
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

    testWidgets('tapping a prize card opens its dialog', (tester) async {
      when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
        (_) async => chopperListResponse([
          raffleFixture('r-1', 'Gala(open)', RaffleStatusType.open),
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
            id: 'prize-1',
            name: 'PS5',
            raffleId: 'r-1',
            quantity: 1,
            description: 'A shiny console',
          ),
          PrizeSimple.empty().copyWith(
            id: 'prize-2',
            name: 'Switch',
            raffleId: 'r-1',
            quantity: 2,
            description: '',
          ),
        ]),
      );
      when(
        () => scaffold.repository.tombolaRafflesRaffleIdPackTicketsGet(
          raffleId: any(named: 'raffleId'),
        ),
      ).thenAnswer((_) async => chopperListResponse(<PackTicketSimple>[]));

      final container = scaffold.makeContainer(user: adminUser);
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

      // Described prize: dialog shows the copy and the singular quantity.
      await tester.tap(find.byType(PrizeCard).first);
      await settle(tester, frames: 8);
      expect(find.byType(PrizeDialog), findsOneWidget);
      expect(find.text('A shiny console'), findsOneWidget);
      expect(find.text('1 Prize winnable'), findsOneWidget);

      // Dismiss through the barrier, then the empty-description prize.
      await tester.tapAt(const Offset(8, 8));
      await settle(tester, frames: 8);
      expect(find.byType(PrizeDialog), findsNothing);

      await tester.tap(find.byType(PrizeCard).last);
      await settle(tester, frames: 8);
      expect(find.byType(PrizeDialog), findsOneWidget);
      expect(find.text('No description'), findsOneWidget);
      // The template pluralizes both words: "2 Prizes winnables".
      expect(find.text('2 Prizes winnables'), findsOneWidget);
    });
  });

  group('Raffle ticket card', () {
    // The winning-ticket card repeats a shine animation forever, so any
    // shell test that seeds tickets can never pumpAndSettle — the card is
    // exercised standalone here in a bounded viewport instead. Plain-shell
    // grouping lives in raffle_main_page_cards_integration_test.
    testWidgets(
      'renders price and count for plain tickets, prize for winners',
      (tester) async {
        when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
          (_) async => chopperListResponse([
            raffleFixture('r-1', 'Soirée des clubs', RaffleStatusType.open),
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
                        ticket: [
                          raffleTicketFixture('t-1', 'r-1'),
                          raffleTicketFixture('t-2', 'r-1'),
                        ],
                        price: 2.0,
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: TicketWidget(
                        ticket: [
                          raffleTicketFixture(
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
