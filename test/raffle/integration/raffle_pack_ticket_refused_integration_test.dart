import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/repository_test_support.dart' show chopperError;
import '../raffle_fixtures.dart';

/// The add-pack-ticket form's refused POST: the backend answers with an
/// error and the page reports that the ticket was not added.
///
/// Own file for the deep-link rule (convention 11).
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

  testWidgets('a refused pack-ticket POST reports that nothing was added', (
    tester,
  ) async {
    stubCreationData(scaffold);
    when(
      () =>
          scaffold.repository.tombolaPackTicketsPost(body: any(named: 'body')),
    ).thenAnswer((_) async => chopperError<PackTicketSimple>(500));

    final container = scaffold.makeContainer(user: adminUser);
    addTearDown(container.dispose);
    container.read(raffleIdProvider.notifier).setId('r-1');
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tombola/detail/creation/add_edit_pack_ticket',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 40 && find.byType(TextFormField).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(QR.currentPath, '/tombola/detail/creation/add_edit_pack_ticket');

    await tester.enterText(find.byType(TextFormField).first, '5');
    await tester.enterText(find.byType(TextFormField).last, '10');
    await settle(tester, frames: 2);
    await scaffold.unfocus(tester);
    await tester.ensureVisible(find.text('Add').last);
    await tester.tap(find.text('Add').last);
    await settle(tester, frames: 20);

    verify(
      () => scaffold.repository.tombolaPackTicketsPost(body: any(named: 'body')),
    ).called(1);
    expect(find.text('Error during addition'), findsOneWidget);
    await scaffold.drainToast(tester);
  });
}
