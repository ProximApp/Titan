import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';
import '../vote_fixtures.dart';

/// Two arms of the list form that the create journey never reaches.
///
/// The type chips: the form defaults to `serio` and posts `serio` whether or
/// not the chip row works, so only a tap on another chip proves the choice is
/// read at all. And a REFUSED save: the success path pops the page, so a
/// failure that also popped (or that silently stayed put) would look identical
/// to a 404 in the list — the page must stay on the form and say so.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('choosing another type posts it, and a refused save says so', (
    tester,
  ) async {
    final container = scaffold.makeContainer(user: voteAdminUserFixture());
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubVoteAdmin(scaffold, status: enums.StatusType.waiting);
    when(
      () => scaffold.repository.campaignListsListIdLogoGet(
        listId: any(named: 'listId'),
      ),
    ).thenAnswer((_) async => fileNotFound());

    ListBase? capturedList;
    when(() => scaffold.repository.campaignListsPost(body: any(named: 'body')))
        .thenAnswer((inv) async {
          capturedList = inv.namedArguments[#body] as ListBase;
          throw Exception('backend down');
        });

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${VoteRouter.root}${VoteRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester);

    // The + opens the add form (deferred route: poll for it).
    await tester.tap(find.byType(CustomIconButton));
    for (var i = 0; i < 20 && find.text('Add a list').evaluate().isEmpty; i++) {
      await settle(tester, frames: 4);
    }
    expect(find.text('Add a list'), findsOneWidget);

    // The chips are the enum names capitalized, minus `blank`: \"Serio\" and
    // \"Pipo\". The form starts on serio.
    expect(find.text('Serio'), findsOneWidget);
    await tester.tap(find.text('Pipo'));
    await settle(tester, frames: 2);

    await tester.enterText(find.byType(TextField).first, 'Liste Pipo');
    await tester.enterText(find.byType(TextField).at(1), 'Des jeux');
    await tester.enterText(find.byType(TextField).at(2), 'Un tournoi par mois');
    await settle(tester, frames: 2);

    await tester.dragUntilVisible(
      find.text('Add'),
      find.byType(SingleChildScrollView).last,
      const Offset(0, -200),
    );
    await settle(tester, frames: 2);
    await tester.tap(find.text('Add'));
    await settle(tester, frames: 12);

    expect(capturedList, isNotNull);
    expect(
      capturedList!.type,
      enums.ListType.pipo,
      reason: 'the chip choice has to reach the POST, not stay in the widget',
    );
    // The save failed: the form is still there and the user is told why.
    expect(find.text('Error editing'), findsOneWidget);
    expect(find.text('Add a list'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
