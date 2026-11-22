import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';

import '../../shared/app_scaffold.dart';
import '../raffle_fixtures.dart';

/// The add-prize form's refusal: a submit that fails validation says the
/// prize was not added instead of silently doing nothing.
///
/// Own file for the deep-link rule (convention 11): the deferred form route
/// has to be the only deep link in its isolate.
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

  testWidgets('an invalid prize form reports that nothing was added', (
    tester,
  ) async {
    when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
      (_) async => chopperListResponse([
        raffleFixture('r-1', 'Gala', RaffleStatusType.creation),
      ]),
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
    when(
      () => scaffold.repository.tombolaUsersUserIdTicketsGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer(
      (_) async =>
          chopperListResponse(<AppModulesRaffleSchemasRaffleTicketComplete>[]),
    );

    final container = scaffold.makeContainer(user: adminUser);
    addTearDown(container.dispose);
    container.read(raffleIdProvider.notifier).setId('r-1');
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tombola/detail/creation/add_edit_prize',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 40 && find.byType(TextFormField).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(QR.currentPath, '/tombola/detail/creation/add_edit_prize');

    // Nothing filled in: the form refuses and the page says so.
    await scaffold.unfocus(tester);
    await tester.ensureVisible(find.text('Add').last);
    await tester.tap(find.text('Add').last);
    await settle(tester, frames: 20);

    expect(find.text('Error during addition'), findsOneWidget);
    verifyNever(
      () => scaffold.repository.tombolaPrizesPost(body: any(named: 'body')),
    );
    await scaffold.drainToast(tester);
  });
}
