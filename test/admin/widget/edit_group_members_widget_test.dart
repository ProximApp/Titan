import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/admin/providers/all_group_list_provider.dart';
import 'package:titan/admin/providers/group_provider.dart';
import 'package:titan/admin/providers/simple_groups_groups_provider.dart';
import 'package:titan/admin/ui/pages/groups/edit_group_page/search_user.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/repository/repository.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';
import 'package:titan/user/providers/user_list_provider.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level coverage for the edit-group form: `SearchUser` (0/65 — the
/// member rows, the search bar and the add-member sheet) and its
/// `MemberResults` (the add results list). The two search bars differ ONLY
/// in the group filter they pass — the main one includes the group, the
/// add-member sheet's excludes it — so both directions are asserted from the
/// captured invocations.
class _GroupFake extends GroupNotifier {
  _GroupFake(this.group);

  final AsyncValue<CoreGroup> group;

  @override
  AsyncValue<CoreGroup> build() => group;
}

class _GroupListFake extends GroupListNotifier {
  _GroupListFake(this.groups);

  final List<CoreGroupSimple> groups;

  @override
  AsyncValue<List<CoreGroupSimple>> build() => AsyncValue.data(groups);
}

void main() {
  late IntegrationScaffold scaffold;

  final alice = CoreUserSimple.empty().copyWith(
    id: 'u1',
    firstname: 'Alice',
    name: 'Durand',
  );
  final bob = CoreUserSimple.empty().copyWith(
    id: 'u2',
    firstname: 'Bob',
    name: 'Martin',
  );
  final group = CoreGroup.empty().copyWith(
    id: 'g-1',
    name: 'BDE',
    members: [alice, bob],
  );
  final zoe = CoreUserSimple.empty().copyWith(
    id: 'u3',
    firstname: 'Zoe',
    name: 'Zern',
  );

  /// Every search the two bars fire, so the include/exclude wiring can be
  /// asserted without mocktail's literal-equality traps on List arguments.
  late List<Invocation> searches;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    searches = [];
  });

  void stubSearch({List<CoreUserSimple> results = const []}) {
    when(
      () => scaffold.repository.usersSearchGet(
        query: any(named: 'query'),
        includedAccountTypes: any(named: 'includedAccountTypes'),
        excludedAccountTypes: any(named: 'excludedAccountTypes'),
        includedGroups: any(named: 'includedGroups'),
        excludedGroups: any(named: 'excludedGroups'),
      ),
    ).thenAnswer((inv) async {
      searches.add(inv);
      return scaffold.repository.ok(results);
    });
  }

  ProviderContainer containerWith() {
    final container = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(scaffold.repository),
        groupProvider.overrideWith(() => _GroupFake(AsyncValue.data(group))),
        allGroupListProvider.overrideWith(
          () => _GroupListFake([
            CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'BDE'),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> pumpSearchUser(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(body: SingleChildScrollView(child: SearchUser())),
      container,
    );
  }

  Finder trashIcon() =>
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.trash);

  /// Drains the toast through the scaffold's canonical drain (3s + one
  /// frame) — deliberately NOT pumpAndSettle, which can never finish while
  /// the add-member sheet's WaitingButton Loader spins.
  Future<void> drainToast(WidgetTester tester) => scaffold.drainToast(tester);

  testWidgets('lists the current members with a delete control', (
    tester,
  ) async {
    final container = containerWith();
    await pumpSearchUser(tester, container);

    expect(find.text('Alice Durand'), findsOneWidget);
    expect(find.text('Bob Martin'), findsOneWidget);
    expect(trashIcon(), findsNWidgets(2));
    expect(find.byType(CustomIconButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the main search bar queries with the group INCLUDED', (
    tester,
  ) async {
    stubSearch(results: [zoe]);
    final container = containerWith();
    await pumpSearchUser(tester, container);

    await tester.enterText(find.byType(TextField), 'zoe');
    await tester.pumpAndSettle();

    expect(searches, hasLength(1));
    final args = searches.single.namedArguments;
    expect(args[#query], 'zoe');
    expect(args[#includedGroups], ['g-1']);
    expect(args[#excludedGroups], isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty query clears the result list again', (tester) async {
    stubSearch(results: [zoe]);
    final container = containerWith();
    await pumpSearchUser(tester, container);

    await tester.enterText(find.byType(TextField), 'zoe');
    await tester.pumpAndSettle();
    expect(container.read(userList).value, hasLength(1));

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    expect(container.read(userList).value, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the plus opens the add-member sheet searching EXCLUDED', (
    tester,
  ) async {
    stubSearch(results: [zoe]);
    final container = containerWith();
    await pumpSearchUser(tester, container);

    await tester.tap(find.byType(CustomIconButton));
    // The plus is a WaitingButton whose onTap awaits the sheet closing, so a
    // Loader spins as long as the sheet is open: fixed frame budget, never
    // pumpAndSettle (the rule from admin_groups_management).
    await tester.pump();
    await settle(tester, frames: 14);

    expect(find.text('Add member'), findsOneWidget);
    // Both bars are on screen now: the sheet's is the second one.
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).last, 'zoe');
    await settle(tester, frames: 8);

    expect(searches, hasLength(1));
    final args = searches.single.namedArguments;
    expect(args[#query], 'zoe');
    expect(args[#excludedGroups], ['g-1']);
    expect(args[#includedGroups], isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a result adds the member and toasts', (tester) async {
    stubSearch(results: [zoe]);
    when(
      () => scaffold.repository.groupsMembershipPost(body: any(named: 'body')),
    ).thenAnswer((_) async => scaffold.repository.ok(group));

    final container = containerWith();
    await pumpSearchUser(tester, container);

    await tester.tap(find.byType(CustomIconButton));
    // The plus is a WaitingButton whose onTap awaits the sheet closing, so a
    // Loader spins as long as the sheet is open: fixed frame budget, never
    // pumpAndSettle (the rule from admin_groups_management).
    await tester.pump();
    await settle(tester, frames: 14);
    await tester.enterText(find.byType(TextField).last, 'zoe');
    await settle(tester, frames: 8);

    expect(find.text('Zoe Zern'), findsOneWidget);

    await tester.tap(find.text('Zoe Zern'));
    await settle(tester, frames: 8);

    verify(
      () => scaffold.repository.groupsMembershipPost(body: any(named: 'body')),
    ).called(1);
    expect(find.text('Member added'), findsOneWidget);
    expect(find.text('Success'), findsOneWidget);
    // The group-slot map gets the loaded-answer marker for this group.
    expect(container.read(simpleGroupsGroupsProvider)['g-1']?.value, isEmpty);

    await drainToast(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a member already in the group is not posted again', (
    tester,
  ) async {
    // Equal by value to the member already in group.members.
    final duplicate = CoreUserSimple.empty().copyWith(
      id: 'u1',
      firstname: 'Alice',
      name: 'Durand',
    );
    stubSearch(results: [duplicate]);
    when(
      () => scaffold.repository.groupsMembershipPost(body: any(named: 'body')),
    ).thenAnswer((_) async => scaffold.repository.ok(group));

    final container = containerWith();
    await pumpSearchUser(tester, container);

    await tester.tap(find.byType(CustomIconButton));
    // The plus is a WaitingButton whose onTap awaits the sheet closing, so a
    // Loader spins as long as the sheet is open: fixed frame budget, never
    // pumpAndSettle (the rule from admin_groups_management).
    await tester.pump();
    await settle(tester, frames: 14);
    await tester.enterText(find.byType(TextField).last, 'alice');
    await settle(tester, frames: 8);

    // Two "Alice Durand"s are on screen: the member row under the sheet and
    // the search result in it — the sheet's result is the last one.
    await tester.tap(find.text('Alice Durand').last);
    await settle(tester, frames: 8);

    verifyNever(
      () => scaffold.repository.groupsMembershipPost(body: any(named: 'body')),
    );
    expect(find.text('Member added'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing a member asks first, then DELETEs and toasts', (
    tester,
  ) async {
    when(
      () =>
          scaffold.repository.groupsMembershipDelete(body: any(named: 'body')),
    ).thenAnswer((_) async => scaffold.repository.okVoid());

    final container = containerWith();
    await pumpSearchUser(tester, container);

    await tester.tap(trashIcon().first);
    await tester.pumpAndSettle();

    expect(find.text('Remove member from group?'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    verify(
      () =>
          scaffold.repository.groupsMembershipDelete(body: any(named: 'body')),
    ).called(1);
    expect(find.text('Group updated'), findsOneWidget);
    expect(find.text('Success'), findsOneWidget);

    await drainToast(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed removal toasts the update error', (tester) async {
    when(
      () =>
          scaffold.repository.groupsMembershipDelete(body: any(named: 'body')),
    ).thenAnswer((_) async => scaffold.repository.fail<void>(500));

    final container = containerWith();
    await pumpSearchUser(tester, container);

    await tester.tap(trashIcon().first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Error while updating'), findsOneWidget);
    // TypeMsg.msg, not TypeMsg.error: the delete-failure arm of SearchUser
    // fires the toast with the success TITLE over the error description.
    // Pinned as-built so a future fix of the wiring shows up here.
    expect(find.text('Success'), findsOneWidget);

    await drainToast(tester);
    expect(tester.takeException(), isNull);
  });
}
