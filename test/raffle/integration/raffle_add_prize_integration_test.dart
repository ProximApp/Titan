import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';

import '../../shared/app_scaffold.dart';

/// The add-edit prize page (`/tombola/detail/creation/add_edit_prize`, 93
/// uncovered lines): the form's three entries and its POST round-trip.
///
/// Own file for the deep-link rule (convention 11): a deep link to this
/// nested route wedges when any earlier deep link to a different path has
/// already run in the same isolate, so the creation-page tests live in
/// raffle_creation_integration_test.dart.
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

  testWidgets('the add-prize page creates a prize through the API', (
    tester,
  ) async {
    when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
      (_) async => chopperListResponse([
        RaffleComplete.empty().copyWith(
          id: 'r-1',
          name: 'Gala',
          groupId: 'group-1',
          status: RaffleStatusType.creation,
        ),
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
    when(
      () => scaffold.repository.tombolaPrizesPost(body: any(named: 'body')),
    ).thenAnswer(
      (_) async =>
          chopper.Response<PrizeSimple>(http.Response('body', 200), null),
    );

    final container = scaffold.makeContainer(user: adminUser);
    container.read(raffleIdProvider.notifier).setId('r-1');
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tombola/detail/creation/add_edit_prize',
      pumpAndSettle: false,
    );
    // The deferred page + provider data land at a variable frame; wait
    // for the form instead of a fixed pump count.
    for (var i = 0; i < 40 && find.text('Quantity').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(QR.currentPath, '/tombola/detail/creation/add_edit_prize');
    // The section titles AND the field labels render the same strings.
    expect(find.text('Quantity'), findsNWidgets(2));
    expect(find.text('Name'), findsNWidgets(2));
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Description (Optional)'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, '1');
    await tester.enterText(fields.at(1), 'PS6');
    await tester.enterText(fields.at(2), 'Even better');
    // 'Add' is both the page title and the submit button.
    await tester.tap(find.text('Add').last);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    final captured =
        verify(
              () => scaffold.repository.tombolaPrizesPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as PrizeBase;
    expect(captured.name, 'PS6');
    expect(captured.raffleId, 'r-1');
    expect(captured.quantity, 1);
    await scaffold.drainToast(tester);
  });
}
