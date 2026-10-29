import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/admin/ui/pages/membership/association_membership_page/association_membership_page.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';
import 'package:titan/tools/ui/styleguide/button.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';

import '../../shared/app_scaffold.dart';

/// The actions half of `/admin/association_memberships`: the existing shell
/// test deep-links the route with an EMPTY list and stops at the heading,
/// while the page itself was at 36/92 — the sorted list, the plus→modal
/// create, the row action sheet's delete and the edit navigation were all
/// unexercised. Each test re-pumps the same path (the groups-management
/// pattern); qlevar's init-path rule only bites on a second, DIFFERENT
/// deep link.
const adminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

void main() {
  late IntegrationScaffold scaffold;

  final groups = [
    CoreGroupSimple.empty().copyWith(id: 'g1', name: 'BDE'),
    CoreGroupSimple.empty().copyWith(id: 'g2', name: 'BDS'),
  ];

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    // The admin main page mounted underneath the sub-page.
    scaffold.stubAdminMainPage();
    // The modal's group picker reads allGroupList (over the [] above).
    when(() => scaffold.repository.groupsGet())
        .thenAnswer((_) async => scaffold.repository.ok(groups));
  });

  MembershipSimple membership(String id, String name) =>
      MembershipSimple.empty().copyWith(id: id, name: name);

  Future<ProviderContainer> pumpMemberships(
    WidgetTester tester, {
    List<MembershipSimple> memberships = const [],
  }) async {
    when(() => scaffold.repository.membershipsGet())
        .thenAnswer((_) async => scaffold.repository.ok(memberships));
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        id: 'me',
        groups: [
          CoreGroupSimple.empty().copyWith(id: adminGroupId, name: 'admin'),
        ],
      ),
    );
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/admin/association_memberships',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);
    return container;
  }

  Finder plusInPage() => find.descendant(
    of: find.byType(AssociationMembershipsPage),
    matching: find.byType(CustomIconButton),
  );

  Finder plusIcon() => find.descendant(
    of: find.byType(BottomModalTemplate),
    matching: find.byWidgetPredicate(
      (w) => w is HeroIcon && w.icon == HeroIcons.plus,
    ),
  );

  testWidgets('the list renders sorted A to Z', (tester) async {
    await pumpMemberships(
      tester,
      memberships: [membership('m-z', 'Zeta'), membership('m-a', 'Alpha')],
    );

    expect(QR.currentPath, '/admin/association_memberships');
    final titles = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .toList();
    expect(titles, contains('Alpha'));
    expect(titles, contains('Zeta'));
    // The page sorts the endpoint's order before rendering.
    expect(titles.indexOf('Alpha'), lessThan(titles.indexOf('Zeta')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the plus modal creates a membership through the API', (
    tester,
  ) async {
    AppCoreMembershipsSchemasMembershipsMembershipBase? created;
    when(() => scaffold.repository.membershipsPost(body: any(named: 'body')))
        .thenAnswer((inv) async {
          created =
              inv.namedArguments[#body]
                  as AppCoreMembershipsSchemasMembershipsMembershipBase?;
          return scaffold.repository.ok(MembershipSimple.empty());
        });

    await pumpMemberships(tester);

    await tester.tap(plusInPage());
    // WaitingButton plus: Loader spins while the sheet is open — fixed
    // frames, never pumpAndSettle.
    await tester.pump();
    await settle(tester, frames: 14);
    expect(find.text('Association memberships management'), findsOneWidget);

    await tester.tap(find.text('Choose a group to manage this membership'));
    // The picker opens after 150ms.
    await tester.pump(const Duration(milliseconds: 200));
    await settle(tester, frames: 8);
    expect(find.text('BDE'), findsOneWidget);

    // The picker rows' + icons are the only plus icons reachable here.
    await tester.tap(plusIcon().first);
    await settle(tester, frames: 8);
    expect(find.text('BDE'), findsOneWidget);
    expect(find.text('Choose a group to manage this membership'), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'New asso');
    await tester.tap(find.widgetWithText(Button, 'Add'));
    await settle(tester, frames: 14);

    expect(created, isNotNull);
    expect(created!.name, 'New asso');
    expect(created!.managerGroupId, 'g1');
    expect(find.text('Membership created'), findsOneWidget);
    expect(find.text('Success'), findsOneWidget);
    // The modal popped itself after the create.
    expect(find.text('Association memberships management'), findsNothing);

    await scaffold.drainToast(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a rejected create toasts the creation error', (tester) async {
    when(() => scaffold.repository.membershipsPost(body: any(named: 'body')))
        .thenAnswer((_) async => scaffold.repository.fail(400));

    await pumpMemberships(tester);

    await tester.tap(plusInPage());
    await tester.pump();
    await settle(tester, frames: 14);
    await tester.tap(find.text('Choose a group to manage this membership'));
    await tester.pump(const Duration(milliseconds: 200));
    await settle(tester, frames: 8);
    await tester.tap(plusIcon().first);
    await settle(tester, frames: 8);
    await tester.enterText(find.byType(TextFormField), 'Doomed');
    await tester.tap(find.widgetWithText(Button, 'Add'));
    await settle(tester, frames: 14);

    expect(find.text('Error during creation'), findsOneWidget);

    await scaffold.drainToast(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the row action sheet deletes through the API', (tester) async {
    when(
      () => scaffold.repository.membershipsAssociationMembershipIdDelete(
        associationMembershipId: any(named: 'associationMembershipId'),
      ),
    ).thenAnswer((_) async => scaffold.repository.okVoid());

    await pumpMemberships(tester, memberships: [membership('m-1', 'Zeta')]);

    await tester.tap(find.text('Zeta'));
    await settle(tester, frames: 14);

    expect(find.widgetWithText(Button, 'Edit'), findsOneWidget);
    expect(find.widgetWithText(Button, 'Delete'), findsOneWidget);

    await tester.tap(find.widgetWithText(Button, 'Delete'));
    await settle(tester, frames: 8);
    expect(find.text('Deleting'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 14);

    verify(
      () => scaffold.repository.membershipsAssociationMembershipIdDelete(
        associationMembershipId: 'm-1',
      ),
    ).called(1);
    expect(find.text('Membership deleted'), findsOneWidget);
    expect(find.text('Success'), findsOneWidget);

    await scaffold.drainToast(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the row sheet Edit loads members and routes to the detail', (
    tester,
  ) async {
    when(
      () => scaffold.repository.membershipsAssociationMembershipIdMembersGet(
        associationMembershipId: any(named: 'associationMembershipId'),
        minimalStartDate: any(named: 'minimalStartDate'),
        maximalStartDate: any(named: 'maximalStartDate'),
        minimalEndDate: any(named: 'minimalEndDate'),
        maximalEndDate: any(named: 'maximalEndDate'),
      ),
    ).thenAnswer(
      (_) async => scaffold.repository.okList<UserMembershipComplete>(),
    );

    await pumpMemberships(tester, memberships: [membership('m-1', 'Zeta')]);

    await tester.tap(find.text('Zeta'));
    await settle(tester, frames: 14);
    await tester.tap(find.widgetWithText(Button, 'Edit'));
    await settle(tester, frames: 24);

    expect(
      QR.currentPath,
      '/admin/association_memberships/detail_association_membership',
    );
    expect(tester.takeException(), isNull);
  });
}
