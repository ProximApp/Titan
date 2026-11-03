import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';
import 'package:titan/vote/providers/list_members.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';
import '../vote_fixtures.dart';

/// The add-list form's member row and its two failure toasts
/// (`add_edit_list.dart` lines 183-197, 304-307, 310-314, plus the whole
/// MemberCard admin modal — 22 uncovered lines of its own): a seeded member
/// renders as an admin MemberCard whose tap opens the Edit/Delete bottom
/// modal, Delete empties the row back to the "No member" state, and the
/// submit reports a failed validate() and a failed POST differently.
///
/// vote_add_edit_list / vote_edit_list own the successful round trips —
/// this file is the members branch and the two error arms.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'the add-list form manages members and reports validation and POST failures',
    (tester) async {
      final container = scaffold.makeContainer(user: voteAdminUserFixture());
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      stubVoteAdmin(scaffold, status: enums.StatusType.waiting);
      // ListCard mounts fetch each list's logo; the 404 reads as "no bytes".
      when(
        () => scaffold.repository.campaignListsListIdLogoGet(
          listId: any(named: 'listId'),
        ),
      ).thenAnswer((_) async => fileNotFound());

      // The seeded member, added once the form is open: the + button's own
      // handler clears the member row first (admin_page.dart), so seeding
      // before the navigation would be wiped — production fills it through
      // the add-member modal while the form is up.
      final member = ListMemberComplete(
        userId: 'u-1',
        role: 'Treasurer',
        user: CoreUserSimple.empty().copyWith(
          id: 'u-1',
          firstname: 'Jane',
          name: 'Doe',
        ),
      );

      // The POST fails for the whole test: only the error arm under test.
      when(
        () => scaffold.repository.campaignListsPost(body: any(named: 'body')),
      ).thenThrow(Exception('backend said no'));

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '${VoteRouter.root}${VoteRouter.admin}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // Waiting state shows the + button next to the Lists header.
      expect(find.text('Lists'), findsOneWidget);
      await tester.tap(find.byType(CustomIconButton));
      for (
        var i = 0;
        i < 20 && find.text('Add a list').evaluate().isEmpty;
        i++
      ) {
        await settle(tester, frames: 4);
      }
      expect(find.text('Add a list'), findsOneWidget);

      container.read(listMembersProvider.notifier).setMembers([member]);
      await settle(tester, frames: 4);

      // Members branch: the seeded member renders instead of the empty
      // state (MemberCard with isAdmin: true — title from getName(),
      // subtitle the role).
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('Treasurer'), findsOneWidget);
      expect(find.text('No member'), findsNothing);

      // The tap opens the admin's Edit/Delete bottom modal — 150ms AFTER
      // the card's own debounce future, which pumpAndSettle alone never
      // crosses (a timer schedules no frames).
      await tester.tap(find.text('Jane Doe'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Delete runs removeMember: the row empties back to the copy.
      await tester.tap(find.text('Delete'));
      await settle(tester, frames: 6);
      await scaffold.closeModal(tester);
      expect(find.text('No member'), findsOneWidget);
      expect(find.text('Jane Doe'), findsNothing);

      // Empty submit: validate() fails, so the form stays put on the
      // field-error toast and the POST never fires.
      await tester.dragUntilVisible(
        find.text('Add'),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await settle(tester, frames: 2);
      await tester.tap(find.text('Add'));
      await settle(tester, frames: 12);
      expect(find.text('Incorrect or missing fields'), findsOneWidget);
      expect(find.text('Error editing'), findsNothing);
      // Drain the toast so it cannot swallow the next tap.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      // Filled form, failing POST: validate() passes, the request fires
      // once and its failure takes the edit-error toast instead.
      await tester.enterText(
        find.byType(TextField).first,
        'Liste Pique-Assiette',
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        'Des repas, de la convivialité',
      );
      await tester.enterText(
        find.byType(TextField).at(2),
        'Un banquet par mois',
      );
      await settle(tester, frames: 4);
      await tester.dragUntilVisible(
        find.text('Add'),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await settle(tester, frames: 2);
      await tester.tap(find.text('Add'));
      await settle(tester, frames: 12);

      verify(
        () => scaffold.repository.campaignListsPost(body: any(named: 'body')),
      ).called(1);
      expect(find.text('Error editing'), findsOneWidget);
      expect(find.text('List added'), findsNothing);
      // The failure never pops the form.
      expect(find.text('Add a list'), findsOneWidget);

      // Drain the toast timer.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
