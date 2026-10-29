import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_groupement_provider.dart';
import 'package:titan/phonebook/providers/association_picture_provider.dart';
import 'package:titan/phonebook/providers/association_provider.dart';
import 'package:titan/phonebook/router.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';
import '../phonebook_fixtures.dart';

/// The PRESIDENT side of the members tree: AssociationEditionModal's
/// "Manage members" button routes to /phonebook/association_detail
/// /edit_association_members (AdminMiddleware on
/// isAssociationPresidentProvider), and that page's "Add a member" row
/// routes to the editor through the ELSE branch of its admin check — the
/// branch the admin-path member_flows file can never take. This file owns
/// that one deferred route journey (convention 10); everything on the
/// members page that does not navigate (reorder, delete-role, the
/// deactivated layout) lives in
/// phonebook_member_edition_modal_integration_test.dart.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    shellTestSetUp(scaffold);
  });

  void stubPresidentDetail(IntegrationScaffold scaffold) {
    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([association('a-1', 'Robot Club')]),
    );
    when(() => scaffold.repository.phonebookGroupementsGet()).thenAnswer(
      (_) async => chopperListResponse([groupement('grp-1', 'Clubs')]),
    );
    when(() => scaffold.repository.phonebookRoletagsGet()).thenAnswer(
      (_) async => chopperResponse(RoleTagsReturn(tags: ['President'])),
    );
    when(
      () => scaffold.repository
          .phonebookAssociationsAssociationIdMembersMandateYearGet(
            associationId: 'a-1',
            mandateYear: 2026,
          ),
    ).thenAnswer(
      (_) async => chopperListResponse([
        member('u-1', 'Bolt', 'Ada', 'Lovelace', roleTags: 'President'),
      ]),
    );
    stubAssociationAndProfilePictures(scaffold);
  }

  Future<void> pumpDeferred(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('a president manages members from the detail modal', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'u-1'),
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubPresidentDetail(scaffold);

    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));
    container
        .read(associationGroupementProvider.notifier)
        .setAssociationGroupement(groupement('grp-1', 'Clubs'));
    // Pre-load the picture so the avatar is data, not the perpetual loader
    // animation that would hang every pumpAndSettle in this test.
    await container
        .read(associationPictureProvider.notifier)
        .getAssociationPicture('a-1');

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${PhonebookRouter.root}${PhonebookRouter.associationDetail}',
      pumpAndSettle: false,
    );
    await settle(tester);

    // The president pencil opens the member-facing edition modal.
    final pencil = find.byWidgetPredicate(
      (w) => w is HeroIcon && w.icon == HeroIcons.pencilSquare,
    );
    await scaffold.openModal(tester, pencil);
    expect(find.text('Manage members'), findsOneWidget);

    // "Manage members" pops the sheet and routes to the president-side
    // members page (deferred: pump until it mounts).
    await scaffold.tapInModal(tester, find.text('Manage members'));
    await pumpDeferred(tester);
    expect(scaffold.isModalOpen(tester), isFalse);
    expect(find.text('Manage Robot Club members'), findsOneWidget);
    expect(find.text('Bolt - President'), findsOneWidget);

    // Pull-to-refresh reloads the members list (loadMembers on refresh).
    await tester.drag(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.text('Manage Robot Club members'),
      ),
      const Offset(0, 300),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    verify(
      () => scaffold.repository
          .phonebookAssociationsAssociationIdMembersMandateYearGet(
            associationId: 'a-1',
            mandateYear: 2026,
          ),
    ).called(2);

    // "Add a member" takes the ELSE branch (no /admin in the path) into the
    // editor under the detail tree.
    await tester.tap(find.text('Add a member'));
    await pumpDeferred(tester);
    expect(find.text('Search a user'), findsOneWidget);
  });
}
