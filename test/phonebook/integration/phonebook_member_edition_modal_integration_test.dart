import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_provider.dart';
import 'package:titan/phonebook/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';

/// The members admin page's non-navigating flows (deep link only — the
/// route journeys live in phonebook_member_flows and
/// phonebook_president_members): the reorder handler behind
/// ReorderableListView (both endpoints' toasts), the member-edition modal's
/// delete-role confirmation (success, failure and cancel — the modal block
/// sat at 22/49 with only "Edit role" driven), and the deactivated
/// association layout that swaps the reorderable list for plain cards.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    shellTestSetUp(scaffold);
  });

  /// Two members so the reorder has somewhere to move; membership ids
  /// follow the fixture convention m-<userId>.
  void stubMembers(IntegrationScaffold scaffold) {
    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([association('a-1', 'Robot Club')]),
    );
    when(() => scaffold.repository.phonebookGroupementsGet()).thenAnswer(
      (_) async => chopperListResponse([groupement('grp-1', 'Clubs')]),
    );
    when(
      () => scaffold.repository
          .phonebookAssociationsAssociationIdMembersMandateYearGet(
            associationId: 'a-1',
            mandateYear: 2026,
          ),
    ).thenAnswer(
      (_) async => chopperListResponse([
        member('u-1', 'Bolt', 'Ada', 'Lovelace'),
        member('u-2', 'Nut', 'Grace', 'Hopper'),
      ]),
    );
    stubAssociationAndProfilePictures(scaffold);
  }

  ProviderContainer adminContainer() => scaffold.makeContainer(
    user: CoreUser.empty().copyWith(
      groups: [
        CoreGroupSimple.empty().copyWith(
          id: phonebookAdminGroupId,
          name: 'admin_phonebook',
        ),
      ],
    ),
  );

  Future<void> pumpMembers(WidgetTester tester, ProviderContainer container) =>
      scaffold
          .pumpApp(
            tester,
            container,
            initialPath:
                '${PhonebookRouter.root}${PhonebookRouter.admin}'
                '${PhonebookRouter.editAssociationMembers}',
            pumpAndSettle: false,
          )
          .then((_) => settle(tester));

  testWidgets('dragging a member card reorders it through the PATCH', (
    tester,
  ) async {
    final container = adminContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubMembers(scaffold);
    when(
      () =>
          scaffold.repository.phonebookAssociationsMembershipsMembershipIdPatch(
            membershipId: any(named: 'membershipId'),
            body: any(named: 'body'),
          ),
    ).thenAnswer(
      (_) async => chopper.Response<void>(http.Response('body', 200), null),
    );

    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));
    await pumpMembers(tester, container);

    expect(find.textContaining('Bolt - President'), findsOneWidget);
    expect(find.textContaining('Nut - President'), findsOneWidget);

    // Move the second card above the first. ReorderableListView's default
    // handles are DELAYED drags: press, hold past the long-press threshold,
    // then move — a plain drag is swallowed by the child's gestures.
    final gesture = await tester.startGesture(
      tester.getCenter(find.textContaining('Nut - President')),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(0, -400));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // The toast mounts on a frame AFTER the reorder future resolves; one
    // more settle pass gives it the frames to build before we look for it.
    await settle(tester, frames: 6);

    final captured = verify(
      () =>
          scaffold.repository.phonebookAssociationsMembershipsMembershipIdPatch(
            membershipId: captureAny(named: 'membershipId'),
            body: captureAny(named: 'body'),
          ),
    ).captured;
    expect(captured[0], 'm-u-2');
    expect((captured[1] as MembershipEdit).memberOrder, 0);
    expect(find.text('Member reordered'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('the member-edition modal deletes a role, or not', (
    tester,
  ) async {
    final container = adminContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubMembers(scaffold);

    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));
    await pumpMembers(tester, container);

    // Cancel: the confirm sheet closes and nothing is deleted.
    await scaffold.openModal(
      tester,
      find.textContaining('Bolt - President').first,
    );
    await scaffold.tapInModal(tester, find.text('Delete role'));
    expect(scaffold.isModalOpen(tester), isTrue);
    await scaffold.tapInModal(tester, find.text('Cancel'));
    expect(scaffold.isModalOpen(tester), isFalse);
    verifyNever(
      () => scaffold.repository
          .phonebookAssociationsMembershipsMembershipIdDelete(
            membershipId: any(named: 'membershipId'),
          ),
    );

    // Failure: the DELETE is refused and the error toast renders.
    when(
      () => scaffold.repository
          .phonebookAssociationsMembershipsMembershipIdDelete(
            membershipId: 'm-u-1',
          ),
    ).thenAnswer(
      (_) async => chopper.Response<void>(
        http.Response('{"detail": "nope"}', 500),
        null,
        error: 'nope',
      ),
    );
    await scaffold.openModal(
      tester,
      find.textContaining('Bolt - President').first,
    );
    await scaffold.tapInModal(tester, find.text('Delete role'));
    await scaffold.tapInModal(tester, find.text('Confirm'));
    await settle(tester, frames: 6);
    expect(find.text('Error deleting'), findsOneWidget);
    await scaffold.drainToast(tester);
    expect(find.textContaining('Bolt - President'), findsOneWidget);

    // Success: the second member's membership goes and its card leaves.
    when(
      () => scaffold.repository
          .phonebookAssociationsMembershipsMembershipIdDelete(
            membershipId: 'm-u-2',
          ),
    ).thenAnswer((_) async => chopperResponseVoid());
    await scaffold.openModal(
      tester,
      find.textContaining('Nut - President').first,
    );
    await scaffold.tapInModal(tester, find.text('Delete role'));
    await scaffold.tapInModal(tester, find.text('Confirm'));
    await settle(tester, frames: 6);
    expect(find.text('Member deleted'), findsOneWidget);
    await scaffold.drainToast(tester);
    expect(find.textContaining('Nut - President'), findsNothing);
  });

  testWidgets('a deactivated association lists plain cards without add', (
    tester,
  ) async {
    final container = adminContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubMembers(scaffold);

    container
        .read(associationProvider.notifier)
        .setAssociation(
          association('a-1', 'Robot Club').copyWith(deactivated: true),
        );
    await pumpMembers(tester, container);

    // No "Add a member" row and no reorderable list: a plain Column of
    // deactivated member cards.
    expect(find.text('Add a member'), findsNothing);
    expect(find.byType(ReorderableListView), findsNothing);
    expect(find.textContaining('Bolt - President'), findsOneWidget);
    expect(find.textContaining('Nut - President'), findsOneWidget);
  });
}
