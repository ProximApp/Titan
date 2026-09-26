import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/admin/providers/association_membership_members_list_provider.dart';
import 'package:titan/admin/providers/association_membership_provider.dart';
import 'package:titan/admin/providers/user_association_membership_provider.dart';
import 'package:titan/admin/ui/pages/membership/association_membership_detail_page/association_membership_detail_page.dart';
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
}
