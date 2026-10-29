import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/admin/providers/association_membership_members_list_provider.dart';
import 'package:titan/admin/providers/association_membership_provider.dart';
import 'package:titan/admin/providers/user_association_membership_provider.dart';
import 'package:titan/admin/ui/pages/membership/association_membership_detail_page/association_membership_detail_page.dart';
import 'package:titan/admin/ui/pages/membership/association_membership_detail_page/association_membership_information_editor.dart';
import 'package:titan/admin/ui/pages/membership/association_membership_detail_page/association_membership_member_editable_card.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';
import 'package:titan/tools/ui/widgets/custom_dialog_box.dart';
import 'package:titan/tools/ui/widgets/date_entry.dart';

import '../../shared/app_scaffold.dart';

const adminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    scaffold.stubAdminMainPage();
    when(() => scaffold.repository.mypaymentStructuresGet())
        .thenAnswer((_) async => chopperListResponse<models.Structure>([]));
    when(() => scaffold.repository.associationsGet())
        .thenAnswer((_) async => chopperListResponse<models.Association>([]));
    when(() => scaffold.repository.membershipsGet()).thenAnswer(
      (_) async => chopperListResponse([
        models.MembershipSimple.empty().copyWith(
          id: 'am-1',
          name: 'Mandate 2026',
          managerGroupId: 'g-1',
        ),
      ]),
    );
    when(() => scaffold.repository.groupsGet()).thenAnswer(
      (_) async => chopperListResponse([
        models.CoreGroupSimple.empty().copyWith(id: 'g-2', name: 'Clubs'),
        models.CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'Admins'),
      ]),
    );
  });

  models.UserMembershipComplete member({
    required String id,
    required String firstname,
    required String name,
    String? nickname,
  }) => models.UserMembershipComplete.empty().copyWith(
    id: id,
    associationMembershipId: 'am-1',
    user: models.CoreUserSimple.empty().copyWith(
      id: 'u-$id',
      firstname: firstname,
      name: name,
      nickname: nickname,
    ),
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 12, 31),
  );

  Future<ProviderContainer> pumpDetail(
    WidgetTester tester, {
    List<models.UserMembershipComplete> members = const [],
  }) async {
    scaffold.setWideSurface(tester);
    final container = scaffold.makeContainer(
      user: models.CoreUser.empty().copyWith(
        id: 'me',
        groups: [
          models.CoreGroupSimple.empty().copyWith(
            id: adminGroupId,
            name: 'admin',
          ),
        ],
      ),
      groups: [
        models.CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'Admins'),
        models.CoreGroupSimple.empty().copyWith(id: 'g-2', name: 'Clubs'),
      ],
    );
    container
        .read(associationMembershipProvider.notifier)
        .setAssociationMembership(
          models.MembershipSimple.empty().copyWith(
            id: 'am-1',
            name: 'Mandate 2026',
            managerGroupId: 'g-1',
          ),
        );
    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '/admin/association_memberships/detail_association_membership',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    container
        .read(associationMembershipMembersProvider.notifier)
        .loadFromList(members);
    await settle(tester, frames: 8);
    return container;
  }

  testWidgets('members are filtered by accented name and nickname', (
    tester,
  ) async {
    final container = await pumpDetail(
      tester,
      members: [
        member(id: '1', firstname: 'Élodie', name: 'Durand'),
        member(id: '2', firstname: 'Bob', name: 'Martin', nickname: 'Bobby'),
      ],
    );

    expect(find.byType(AssociationMembershipEditorPage), findsOneWidget);
    expect(find.text('Élodie Durand'), findsOneWidget);
    expect(find.text('Bobby'), findsOneWidget);

    final search = find.byType(TextField).last;
    await tester.enterText(search, 'elodie');
    await settle(tester, frames: 3);
    expect(find.text('Élodie Durand'), findsOneWidget);
    expect(find.text('Bobby'), findsNothing);

    await tester.enterText(search, 'bobby');
    await settle(tester, frames: 3);
    expect(find.text('Bobby'), findsOneWidget);
    expect(find.text('Bob Martin'), findsOneWidget);
    expect(find.text('Élodie Durand'), findsNothing);
    expect(tester.takeException(), isNull);
    await scaffold.unmountApp(tester);
    container.dispose();
  });

  testWidgets('member edit action seeds the chosen membership for editing', (
    tester,
  ) async {
    final editMember = member(
      id: 'membership-1',
      firstname: 'Ada',
      name: 'Lovelace',
    );
    final container = await pumpDetail(tester, members: [editMember]);
    when(
      () => scaffold.repository.membershipsUsersMembershipIdPatch(
        membershipId: any(named: 'membershipId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    final editButton = find
        .descendant(
          of: find.byType(MemberEditableCard),
          matching: find.byType(CustomIconButton),
        )
        .first;
    await tester.tap(editButton);
    await settle(tester, frames: 10);
    expect(
      container.read(userAssociationMembershipProvider).id,
      'membership-1',
    );
    expect(
      QR.currentPath,
      '/admin/association_memberships/detail_association_membership/add_edit_member',
    );
    expect(tester.takeException(), isNull);
    await scaffold.unmountApp(tester);
    container.dispose();
  });

  testWidgets('member delete action calls the API and removes the member', (
    tester,
  ) async {
    final target = member(
      id: 'membership-2',
      firstname: 'Grace',
      name: 'Hopper',
    );
    final container = await pumpDetail(tester, members: [target]);
    when(
      () => scaffold.repository.membershipsUsersMembershipIdDelete(
        membershipId: any(named: 'membershipId'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    final deleteButton = find
        .descendant(
          of: find.byType(MemberEditableCard),
          matching: find.byType(CustomIconButton),
        )
        .last;
    await tester.tap(deleteButton);
    await settle(tester, frames: 4);
    expect(find.byType(CustomDialogBox), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 12);

    verify(
      () => scaffold.repository.membershipsUsersMembershipIdDelete(
        membershipId: 'membership-2',
      ),
    ).called(1);
    expect(find.text('Grace Hopper'), findsNothing);
    await scaffold.drainToast(tester);
    await scaffold.unmountApp(tester);
    container.dispose();
  });

  testWidgets('group manager and date filters query the membership API', (
    tester,
  ) async {
    final container = await pumpDetail(
      tester,
      members: [member(id: '3', firstname: 'Katherine', name: 'Johnson')],
    );
    when(
      () => scaffold.repository.membershipsAssociationMembershipIdMembersGet(
        associationMembershipId: any(named: 'associationMembershipId'),
        minimalStartDate: any(named: 'minimalStartDate'),
        maximalStartDate: any(named: 'maximalStartDate'),
        minimalEndDate: any(named: 'minimalEndDate'),
        maximalEndDate: any(named: 'maximalEndDate'),
      ),
    ).thenAnswer(
      (_) async => chopperListResponse([
        member(id: '3', firstname: 'Katherine', name: 'Johnson'),
      ]),
    );

    await tester.tap(find.text('Admins'));
    await settle(tester, frames: 4);
    expect(
      find.text('Choose a group to manage this membership'),
      findsOneWidget,
    );
    final selectClubs = find
        .descendant(
          of: find.byType(BottomModalTemplate),
          matching: find.byWidgetPredicate(
            (widget) => widget is HeroIcon && widget.icon == HeroIcons.plus,
          ),
        )
        .last;
    await tester.ensureVisible(selectClubs);
    await settle(tester, frames: 2);
    await tester.tap(selectClubs);
    await settle(tester, frames: 8);
    expect(find.text('Clubs'), findsOneWidget);

    final filterButton = find.descendant(
      of: find.byType(AssociationMembershipEditorPage),
      matching: find.text('Filters'),
    );
    await tester.ensureVisible(filterButton);
    await settle(tester, frames: 2);
    await tester.tap(filterButton);
    await settle(tester, frames: 12);
    expect(find.text('Minimum start date'), findsOneWidget);
    expect(find.text('Maximum start date'), findsOneWidget);
    expect(find.text('Minimum end date'), findsOneWidget);
    expect(find.text('Maximum end date'), findsOneWidget);

    final entries = find.byType(DateEntry);
    expect(entries, findsNWidgets(4));
    await tester.enterText(
      find.descendant(of: entries.at(0), matching: find.byType(TextField)),
      '01/02/2026',
    );
    await tester.enterText(
      find.descendant(of: entries.at(2), matching: find.byType(TextField)),
      '01/03/2026',
    );
    await tester.tap(find.text('Apply filters'));
    await settle(tester, frames: 12);

    verify(
      () => scaffold.repository.membershipsAssociationMembershipIdMembersGet(
        associationMembershipId: 'am-1',
        minimalStartDate: '2026-01-02',
        maximalStartDate: any(named: 'maximalStartDate'),
        minimalEndDate: '2026-01-03',
        maximalEndDate: any(named: 'maximalEndDate'),
      ),
    ).called(1);
    final clearFilters = find.text('Clear filters');
    expect(clearFilters, findsOneWidget);
    await tester.ensureVisible(clearFilters);
    await settle(tester, frames: 2);
    await tester.tapAt(tester.getCenter(clearFilters));
    await settle(tester, frames: 12);
    verify(
      () => scaffold.repository.membershipsAssociationMembershipIdMembersGet(
        associationMembershipId: 'am-1',
        minimalStartDate: null,
        maximalStartDate: null,
        minimalEndDate: null,
        maximalEndDate: null,
      ),
    ).called(1);
    expect(tester.takeException(), isNull);
    await scaffold.unmountApp(tester);
    container.dispose();
  });

  void stubMemberGet() {
    when(
      () => scaffold.repository.membershipsAssociationMembershipIdMembersGet(
        associationMembershipId: any(named: 'associationMembershipId'),
        minimalStartDate: any(named: 'minimalStartDate'),
        maximalStartDate: any(named: 'maximalStartDate'),
        minimalEndDate: any(named: 'minimalEndDate'),
        maximalEndDate: any(named: 'maximalEndDate'),
      ),
    ).thenAnswer(
      (_) async => chopperListResponse([
        member(id: '3', firstname: 'Katherine', name: 'Johnson'),
      ]),
    );
  }

  testWidgets('pull-to-refresh reloads the member list', (tester) async {
    await pumpDetail(
      tester,
      members: [member(id: '1', firstname: 'Ada', name: 'Lovelace')],
    );
    stubMemberGet();

    // Nothing has queried the members endpoint yet: the list came from
    // loadFromList. A held downward drag pulls the Cupertino refresh control
    // past its threshold and runs the page's onRefresh (a fast fling does
    // not: the control only arms while the pointer is still down).
    // Start the drag in the page-header region, not the scroll view's
    // centre: with members present the centre lands on the inner
    // ListView.builder (fixed 400px), whose own scrollable wins the gesture,
    // exactly as it would under a real finger starting on a member card.
    await tester.dragFrom(
      tester.getTopLeft(
            find.descendant(
              of: find.byType(AssociationMembershipEditorPage),
              matching: find.byType(CustomScrollView),
            ),
          ) +
          const Offset(200, 60),
      const Offset(0, 300),
    );
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    verify(
      () => scaffold.repository.membershipsAssociationMembershipIdMembersGet(
        associationMembershipId: any(named: 'associationMembershipId'),
        minimalStartDate: any(named: 'minimalStartDate'),
        maximalStartDate: any(named: 'maximalStartDate'),
        minimalEndDate: any(named: 'minimalEndDate'),
        maximalEndDate: any(named: 'maximalEndDate'),
      ),
    );
    await scaffold.unmountApp(tester);
  });

  testWidgets('the + button seeds an empty member and hops to the add route', (
    tester,
  ) async {
    final container = await pumpDetail(tester);

    final plus = find.descendant(
      of: find.byType(AssociationMembershipEditorPage),
      matching: find.byType(CustomIconButton),
    );
    expect(plus, findsOneWidget);
    await tester.tap(plus);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(
      QR.currentPath,
      '/admin/association_memberships/detail_association_membership/add_edit_member',
    );
    expect(
      container.read(userAssociationMembershipProvider).associationMembershipId,
      'am-1',
    );
    expect(tester.takeException(), isNull);
    await scaffold.unmountApp(tester);
    container.dispose();
  });

  testWidgets(
    'the information editor refuses an empty name and saves the rest',
    (tester) async {
      final container = await pumpDetail(tester);
      when(
        () => scaffold.repository.membershipsAssociationMembershipIdPatch(
          associationMembershipId: any(named: 'associationMembershipId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => chopperResponseVoid());

      final nameField = find.descendant(
        of: find.byType(AssociationMembershipInformationEditor),
        matching: find.byType(TextFormField),
      );
      expect(nameField, findsOneWidget);
      final save = find.text('Edit');

      // Empty name: the form refuses before any API call.
      await tester.enterText(nameField, '');
      await scaffold.unfocus(tester);
      await scaffold.ensureOnScreen(tester, save);
      await tester.tap(save);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      expect(find.text('Name cannot be empty'), findsOneWidget);
      verifyNever(
        () => scaffold.repository.membershipsAssociationMembershipIdPatch(
          associationMembershipId: any(named: 'associationMembershipId'),
          body: any(named: 'body'),
        ),
      );

      // A refused update reports its toast and keeps the page.
      when(
        () => scaffold.repository.membershipsAssociationMembershipIdPatch(
          associationMembershipId: any(named: 'associationMembershipId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => scaffold.repository.fail<void>(500));
      await tester.enterText(nameField, 'New mandate');
      await scaffold.unfocus(tester);
      await scaffold.ensureOnScreen(tester, save);
      await tester.tap(save);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      expect(find.text('Error while updating'), findsOneWidget);
      await scaffold.drainToast(tester);

      // The success arm reports and writes the membership back to its provider.
      when(
        () => scaffold.repository.membershipsAssociationMembershipIdPatch(
          associationMembershipId: any(named: 'associationMembershipId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => chopperResponseVoid());
      await scaffold.ensureOnScreen(tester, save);
      await tester.tap(save);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      expect(find.text('Membership updated'), findsOneWidget);
      expect(container.read(associationMembershipProvider).name, 'New mandate');
      await scaffold.drainToast(tester);
      expect(tester.takeException(), isNull);
      await scaffold.unmountApp(tester);
      container.dispose();
    },
  );

  testWidgets(
    'every date filter opens the picker and the max end date is sent',
    (tester) async {
      await pumpDetail(
        tester,
        members: [member(id: '3', firstname: 'Katherine', name: 'Johnson')],
      );
      stubMemberGet();

      final filterButton = find.descendant(
        of: find.byType(AssociationMembershipEditorPage),
        matching: find.text('Filters'),
      );
      await tester.ensureVisible(filterButton);
      await settle(tester, frames: 2);
      await tester.tap(filterButton);
      await settle(tester, frames: 12);
      expect(find.text('Minimum start date'), findsOneWidget);

      final entries = find.byType(DateEntry);
      expect(entries, findsNWidgets(4));
      for (var i = 0; i < 4; i++) {
        final field = find.descendant(
          of: entries.at(i),
          matching: find.byType(TextField),
        );
        await tester.ensureVisible(field);
        await settle(tester, frames: 2);
        await tester.tap(field);
        await settle(tester, frames: 14);
        expect(find.text('OK'), findsOneWidget);
        await tester.tap(find.text('OK'));
        await settle(tester, frames: 14);
      }

      await tester.tap(find.text('Apply filters'));
      await settle(tester, frames: 12);

      // All four controllers hold a date now, so the maximal-end parse runs.
      verify(
        () => scaffold.repository.membershipsAssociationMembershipIdMembersGet(
          associationMembershipId: 'am-1',
          minimalStartDate: any(named: 'minimalStartDate'),
          maximalStartDate: any(named: 'maximalStartDate'),
          minimalEndDate: any(named: 'minimalEndDate'),
          maximalEndDate: any(named: 'maximalEndDate'),
        ),
      );
      expect(tester.takeException(), isNull);
      await scaffold.unmountApp(tester);
    },
  );
}
