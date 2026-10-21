import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';
import 'package:titan/vote/providers/display_results.dart';
import 'package:titan/vote/providers/list_members.dart';
import 'package:titan/vote/ui/pages/list_pages/list_member.dart';

import '../../shared/app_scaffold.dart';

/// `ListMember` (the vote list's member row + its add-member bottom modal)
/// and the `SearchResult` list it embeds — the pair sat at ~25 % / 0 %.
///
/// Covers SearchResult's three branches (hidden until the search field fires
/// `onChanged`, cleared when the query empties, populated through
/// `filterUsers` otherwise) and `addMember`'s three outcomes: the empty-field
/// guard, the duplicate refusal with its toast, and the happy path that
/// records the member and resets both form fields. `addMember` is pure state
/// (no repository call), so only the user search needs a stub.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  final jane = CoreUserSimple.empty().copyWith(
    id: 'u-1',
    firstname: 'Jane',
    name: 'Doe',
  );

  void stubUserSearch() {
    when(
      () => scaffold.repository.usersSearchGet(
        query: any(named: 'query'),
        includedGroups: any(named: 'includedGroups'),
        excludedGroups: any(named: 'excludedGroups'),
        includedAccountTypes: any(named: 'includedAccountTypes'),
        excludedAccountTypes: any(named: 'excludedAccountTypes'),
      ),
    ).thenAnswer((_) async => chopperListResponse([jane]));
  }

  Future<ProviderContainer> pumpListMember(WidgetTester tester) async {
    final container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(container.dispose);
    await pumpWidgetAt(
      tester,
      const ListMember(),
      container: container,
      surface: const ui.Size(600, 1000),
      appFonts: true,
    );
    return container;
  }

  // The modal holds exactly two form fields: search first, role second.
  Finder searchField() => find.byType(TextFormField).at(0);
  Finder roleField() => find.byType(TextFormField).at(1);

  Future<void> openModal(WidgetTester tester) async {
    await tester.tap(find.byType(CustomIconButton));
    await settle(tester, frames: 8);
    expect(find.text('Add a member'), findsOneWidget);
  }

  testWidgets(
    'the modal searches, clears, re-searches, selects and records the member',
    (tester) async {
      stubUserSearch();
      final container = await pumpListMember(tester);
      expect(find.text('Members'), findsOneWidget);

      await openModal(tester);
      // The result list stays hidden until the field fires onChanged.
      expect(find.text('Jane Doe'), findsNothing);

      // Non-empty query → filterUsers through the real search endpoint.
      await tester.enterText(searchField(), 'jane');
      await settle(tester, frames: 8);
      verify(
        () => scaffold.repository.usersSearchGet(
          query: any(named: 'query'),
          includedGroups: any(named: 'includedGroups'),
          excludedGroups: any(named: 'excludedGroups'),
          includedAccountTypes: any(named: 'includedAccountTypes'),
          excludedAccountTypes: any(named: 'excludedAccountTypes'),
        ),
      ).called(1);
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(container.read(displayResult), isTrue);

      // Emptying the query goes through clear(), not a second search.
      await tester.enterText(searchField(), '');
      await settle(tester, frames: 4);
      expect(find.text('Jane Doe'), findsNothing);
      verifyNever(
        () => scaffold.repository.usersSearchGet(
          query: '',
          includedGroups: any(named: 'includedGroups'),
          excludedGroups: any(named: 'excludedGroups'),
          includedAccountTypes: any(named: 'includedAccountTypes'),
          excludedAccountTypes: any(named: 'excludedAccountTypes'),
        ),
      );

      // Re-search and pick the row: the field takes the name, the list hides.
      await tester.enterText(searchField(), 'jane');
      await settle(tester, frames: 8);
      expect(find.text('Jane Doe'), findsOneWidget);
      await tester.tap(find.text('Jane Doe'));
      await settle(tester, frames: 4);
      expect(
        tester.widget<TextFormField>(searchField()).controller!.text,
        'Jane Doe',
      );
      // The row itself is gone — displayResult flipped false (the field
      // legitimately still SHOWS the picked name, so no text findsNothing).
      expect(container.read(displayResult), isFalse);

      await tester.enterText(roleField(), 'president');
      await tester.tap(find.text('Add'));
      await settle(tester, frames: 8);

      final members = container.read(listMembersProvider);
      expect(members, hasLength(1));
      expect(members.single.userId, 'u-1');
      expect(members.single.role, 'president');
      expect(members.single.user, jane);
      // The success path resets both controllers.
      expect(tester.widget<TextFormField>(searchField()).controller!.text, '');
      expect(tester.widget<TextFormField>(roleField()).controller!.text, '');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Add guards the empty form and refuses a duplicate with a toast',
    (tester) async {
      stubUserSearch();
      final container = await pumpListMember(tester);
      container.read(listMembersProvider.notifier).setMembers([
        ListMemberComplete(userId: 'u-1', role: 'president', user: jane),
      ]);

      await openModal(tester);

      // Guard: nothing selected, nothing typed → silent return.
      await tester.tap(find.text('Add'));
      await settle(tester, frames: 4);
      expect(container.read(listMembersProvider), hasLength(1));
      expect(find.text('Member already added'), findsNothing);

      // Fill the form with the member that is already on the list: the
      // duplicate branch refuses and toasts instead of adding a second row.
      await tester.enterText(searchField(), 'jane');
      await settle(tester, frames: 8);
      await tester.tap(find.text('Jane Doe'));
      await settle(tester, frames: 4);
      await tester.enterText(roleField(), 'president');
      await tester.tap(find.text('Add'));
      await settle(tester, frames: 8);

      expect(container.read(listMembersProvider), hasLength(1));
      expect(
        find.text('Member already added', skipOffstage: false),
        findsOneWidget,
      );

      // Drain the toast's auto-close timer before the test ends.
      await tester.pump(const Duration(seconds: 8));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
