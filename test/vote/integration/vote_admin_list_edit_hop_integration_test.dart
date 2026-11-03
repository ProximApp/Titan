import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';
import '../vote_fixtures.dart';

/// The admin list card's Edit hop (`section_list_items.dart` lines 46-54):
/// tapping Edit in the card's bottom modal seeds `listProvider` and the
/// members row from the tapped list, then routes to the deferred add-edit
/// form — whose heading and seeded member are the observable trace that
/// both halves ran.
///
/// Own file (convention 19): qlevar keeps the active route branch in
/// process-global state, so a second router-driven hop in the same isolate
/// never renders its page. vote_admin_section_list_flows owns the
/// non-navigating dialogs on the same strip.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets("a list card's Edit hops to the prefilled edit form", (
    tester,
  ) async {
    final container = scaffold.makeContainer(user: voteAdminUserFixture());
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubVoteAdmin(
      scaffold,
      status: enums.StatusType.waiting,
      sections: [sectionFixture('s-1', 'Bureau des Sports')],
      lists: [
        voteListFixture(
          'l-3',
          'Club Robotic',
          section: sectionFixture('s-1', 'Bureau des Sports'),
        ).copyWith(
          members: [
            ListMemberComplete(
              userId: 'u-1',
              role: 'Treasurer',
              user: CoreUserSimple.empty().copyWith(
                id: 'u-1',
                firstname: 'Jane',
                name: 'Doe',
              ),
            ),
          ],
        ),
      ],
    );
    // ListCard's ListLogo auto-loads; a 404 falls back to the placeholder.
    when(
      () => scaffold.repository.campaignListsListIdLogoGet(
        listId: any(named: 'listId'),
      ),
    ).thenAnswer((_) async => fileNotFound());

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${VoteRouter.root}${VoteRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    // The card's Edit/Delete bottom modal (150ms debounce first: a timer
    // schedules no frames, so pumpAndSettle alone never crosses it).
    await tester.tap(find.text('Club Robotic'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);

    // onEdit seeds listId + the members row, then routes to the deferred
    // add-edit form (its heading is the same in edit mode).
    await tester.tap(find.text('Edit'));
    for (var i = 0; i < 25 && find.text('Add a list').evaluate().isEmpty; i++) {
      await settle(tester, frames: 4);
    }
    // The form is rendered under the card's bottom modal (which rode along
    // with the route swap): finders see through it, and closing it here
    // would pop the router's own navigator instead of the modal.
    expect(find.text('Add a list'), findsOneWidget);
    // The members seeded by onEdit render on the form.
    expect(find.text('Jane Doe'), findsOneWidget);
  });
}
