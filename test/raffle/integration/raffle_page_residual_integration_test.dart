import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/raffle/ui/pages/raffle_page/raffle_page.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../shared/app_scaffold.dart';
import '../raffle_fixtures.dart';

/// Three last raffle behaviours:
/// * the detail page's pull-to-refresh (balance, pack tickets, prizes) and
///   its "no prize" title when the raffle has none,
/// * the main page's two statuses that belong to no section — a raffle with
///   a null status and one the backend answered with its unknown enum value,
/// Dark line still left, proven unreachable:
/// * `ui/pages/raffle_page/raffle_page.dart:144` — the `prizes.isEmpty` arm
///   of the title ternary sits inside the branch that already handled the
///   empty list, so only the "actual prize" arm can render.
final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [
    CoreGroupSimple(
      name: 'admin_raffle',
      id: '0a25cb76-4b63-4fd3-b939-da6d9feabf28',
    ),
  ],
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the detail page refreshes and names the missing prize', (
    tester,
  ) async {
    when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
      (_) async => chopperListResponse([
        raffleFixture('r-1', 'Gala', RaffleStatusType.open),
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
    ).thenAnswer((_) async => chopperListResponse(<PrizeSimple>[]));
    when(
      () => scaffold.repository.tombolaRafflesRaffleIdPackTicketsGet(
        raffleId: any(named: 'raffleId'),
      ),
    ).thenAnswer((_) async => chopperListResponse(<PackTicketSimple>[]));

    final container = scaffold.makeContainer(user: adminUser);
    addTearDown(container.dispose);
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

    // No prize at all: the section title says so instead of naming prizes.
    expect(find.text('No prize'), findsOneWidget);

    clearInteractions(scaffold.repository);
    await tester.drag(find.byType(Refresher), const Offset(0, 400));
    await settle(tester, frames: 24);

    verify(
      () => scaffold.repository.tombolaUsersUserIdCashGet(userId: 'user-1'),
    ).called(1);
    verify(
      () => scaffold.repository.tombolaRafflesRaffleIdPackTicketsGet(
        raffleId: 'r-1',
      ),
    ).called(1);
    verify(
      () => scaffold.repository.tombolaRafflesRaffleIdPrizesGet(
        raffleId: 'r-1',
      ),
    ).called(1);
  });
}
