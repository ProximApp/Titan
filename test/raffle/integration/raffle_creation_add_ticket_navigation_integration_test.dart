import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/raffle/ui/pages/creation_edit_page/ticket_handler.dart';
import 'package:titan/raffle/ui/pages/pack_ticket_page/add_edit_pack_ticket_page.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/repository_stubs.dart';
import '../raffle_fixtures.dart';

/// The ticket strip's "+" card: it seeds an EMPTY pack ticket and pushes the
/// deferred add/edit pack-ticket route in CREATE mode. The strip's pencil
/// (edit mode) and the page's own submits have their own files; this is the
/// one navigation into the form that starts from nothing.
///
/// Own file because the tap navigates mid-test and qlevar honours only the
/// isolate's first such push.
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

  testWidgets('the ticket + card opens the empty add-pack-ticket form', (
    tester,
  ) async {
    stubCreationData(scaffold, withRaffleTickets: true);
    when(
      () => scaffold.repository.tombolaRafflesRaffleIdLogoGet(
        raffleId: any(named: 'raffleId'),
      ),
    ).thenAnswer((_) async => fileNotFound());

    scaffold.setWideSurface(tester);
    final container = scaffold.makeContainer(user: adminUser);
    addTearDown(container.dispose);
    container.read(raffleIdProvider.notifier).setId('r-1');
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tombola/detail/creation',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    await tester.tap(
      find.descendant(
        of: find.byType(TicketHandler),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.plus,
        ),
      ),
    );
    for (
      var i = 0;
      i < 60 && find.byType(AddEditPackTicketPage).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(QR.currentPath, '/tombola/detail/creation/add_edit_pack_ticket');
    expect(find.byType(AddEditPackTicketPage), findsOneWidget);
    // CREATE mode: the form's fields are empty.
    final fields = find.descendant(
      of: find.byType(AddEditPackTicketPage),
      matching: find.byType(TextFormField),
    );
    expect(fields, findsNWidgets(2));
    expect(
      tester.widget<TextFormField>(fields.first).controller!.text,
      isEmpty,
    );
    expect(tester.widget<TextFormField>(fields.last).controller!.text, isEmpty);
  });
}
