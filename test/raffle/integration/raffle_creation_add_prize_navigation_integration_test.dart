import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/raffle/ui/pages/creation_edit_page/prize_handler.dart';
import 'package:titan/raffle/ui/pages/prize_page/add_edit_prize_page.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/repository_stubs.dart';
import '../raffle_fixtures.dart';

/// The prize strip's "+" card: it seeds an EMPTY prize and pushes the deferred
/// add/edit prize route in CREATE mode. The strip's pencil (edit mode) and the
/// add-prize page's create submit have their own files; this is the one
/// navigation into the form that starts from nothing.
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

  testWidgets('the prize + card opens the empty add-prize form', (
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

    // The prize strip's plus is the one inside PrizeHandler (the ticket
    // strip above carries its own).
    await tester.tap(
      find.descendant(
        of: find.byType(PrizeHandler),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.plus,
        ),
      ),
    );
    for (
      var i = 0;
      i < 60 && find.byType(AddEditPrizePage).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(QR.currentPath, '/tombola/detail/creation/add_edit_prize');
    final page = find.byType(AddEditPrizePage);
    expect(page, findsOneWidget);
    // CREATE mode: an empty form and the "Add" submit.
    final fields = find.descendant(
      of: page,
      matching: find.byType(TextFormField),
    );
    expect(fields, findsNWidgets(3));
    expect(
      tester.widget<TextFormField>(fields.at(1)).controller!.text,
      isEmpty,
    );
    expect(find.descendant(of: page, matching: find.text('Add')), findsWidgets);
    expect(
      find.descendant(of: page, matching: find.text('Edit')),
      findsNothing,
    );
  });
}
