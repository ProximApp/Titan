import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_provider.dart';
import 'package:titan/tools/ui/styleguide/list_item_toggle.dart';
import 'package:titan/phonebook/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';
import '../phonebook_fixtures.dart';

/// The groups page's AdminMiddleware gates on isAdminProvider (plain admin).

void main() {
  setUpAll(() {
    registerFallbackValue(AssociationGroupsEdit(associatedGroups: const []));
  });

  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    shellTestSetUp(scaffold);
  });

  testWidgets(
    'deep link to /phonebook/admin/edit_association_groups toggles the association groups',
    (tester) async {
      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(
          groups: [
            CoreGroupSimple.empty().copyWith(id: adminGroupId, name: 'admin'),
          ],
        ),
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      stubAssociationAndProfilePictures(scaffold);
      when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
        (_) async => chopperListResponse([association('a-1', 'Robot Club')]),
      );
      // The page's toggle list renders the real groups catalog.
      when(() => scaffold.repository.groupsGet()).thenAnswer(
        (_) async => chopperListResponse([
          CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'Bureau'),
          CoreGroupSimple.empty().copyWith(id: 'g-2', name: 'Respos'),
        ]),
      );

      container
          .read(associationProvider.notifier)
          .setAssociation(association('a-1', 'Robot Club'));

      await scaffold.pumpApp(
        tester,
        container,
        initialPath:
            '${PhonebookRouter.root}${PhonebookRouter.admin}${PhonebookRouter.editAssociationGroups}',
        pumpAndSettle: false,
      );
      await settle(tester);

      expect(find.textContaining('Manage Robot Club groups'), findsOneWidget);
      expect(find.text('Bureau'), findsOneWidget);
      expect(find.text('Respos'), findsOneWidget);
    },
  );

  testWidgets('toggling a group then Update groups PATCHes and confirms', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(id: adminGroupId, name: 'admin'),
        ],
      ),
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubAssociationAndProfilePictures(scaffold);
    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([
        association('a-1', 'Robot Club').copyWith(associatedGroups: []),
      ]),
    );
    when(() => scaffold.repository.groupsGet()).thenAnswer(
      (_) async => chopperListResponse([
        CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'Bureau'),
        CoreGroupSimple.empty().copyWith(id: 'g-2', name: 'Respos'),
      ]),
    );
    when(
      () => scaffold.repository.phonebookAssociationsAssociationIdGroupsPatch(
        associationId: any(named: 'associationId'),
        body: any(named: 'body'),
      ),
      // The groups PATCH endpoint returns Response<void>: success is
      // status-only, the body is never read back.
    ).thenAnswer((_) async => chopperResponseVoid());

    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${PhonebookRouter.root}${PhonebookRouter.admin}${PhonebookRouter.editAssociationGroups}',
      pumpAndSettle: false,
    );
    await settle(tester);

    // The toggle adds the group to the local selection.
    await tester.tap(find.text('Bureau'));
    await settle(tester, frames: 4);

    await tester.tap(find.text('Update groups'));
    await settle(tester, frames: 8);

    final captured = verify(
      () => scaffold.repository.phonebookAssociationsAssociationIdGroupsPatch(
        associationId: captureAny(named: 'associationId'),
        body: captureAny(named: 'body'),
      ),
    ).captured;
    expect(captured[0], 'a-1');
    expect((captured[1] as AssociationGroupsEdit).associatedGroups, ['g-1']);
    // Success arm: toast, then the reset + back that clears the selection.
    expect(find.text('Groups updated'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('a rejected groups PATCH toasts the error and stays put', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(id: adminGroupId, name: 'admin'),
        ],
      ),
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubAssociationAndProfilePictures(scaffold);
    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([association('a-1', 'Robot Club')]),
    );
    when(() => scaffold.repository.groupsGet()).thenAnswer(
      (_) async => chopperListResponse([
        CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'Bureau'),
        CoreGroupSimple.empty().copyWith(id: 'g-2', name: 'Respos'),
      ]),
    );
    when(
      () => scaffold.repository.phonebookAssociationsAssociationIdGroupsPatch(
        associationId: any(named: 'associationId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperError<AssociationComplete>(500));

    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${PhonebookRouter.root}${PhonebookRouter.admin}${PhonebookRouter.editAssociationGroups}',
      pumpAndSettle: false,
    );
    await settle(tester);

    await tester.tap(find.text('Respos'));
    await settle(tester, frames: 4);
    await tester.tap(find.text('Update groups'));
    await settle(tester, frames: 8);

    // The else arm: error toast, no navigation away.
    expect(find.text('Error during update'), findsOneWidget);
    expect(find.textContaining('Manage Robot Club groups'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('a selected group toggles back off', (tester) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(id: adminGroupId, name: 'admin'),
        ],
      ),
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubAssociationAndProfilePictures(scaffold);
    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([association('a-1', 'Robot Club')]),
    );
    when(() => scaffold.repository.groupsGet()).thenAnswer(
      (_) async => chopperListResponse([
        CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'Bureau'),
        CoreGroupSimple.empty().copyWith(id: 'g-2', name: 'Respos'),
      ]),
    );
    when(
      () => scaffold.repository.phonebookAssociationsAssociationIdGroupsPatch(
        associationId: any(named: 'associationId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${PhonebookRouter.root}${PhonebookRouter.admin}${PhonebookRouter.editAssociationGroups}',
      pumpAndSettle: false,
    );
    await settle(tester);

    // Select, then unselect: the second tap is the removing arm of the
    // toggle and puts the local selection back where it started.
    await tester.tap(find.text('Bureau'));
    await settle(tester, frames: 4);
    expect(
      tester
          .widget<ToggleListItem>(find.widgetWithText(ToggleListItem, 'Bureau'))
          .selected,
      isTrue,
    );
    await tester.tap(find.text('Bureau'));
    await settle(tester, frames: 4);
    expect(
      tester
          .widget<ToggleListItem>(find.widgetWithText(ToggleListItem, 'Bureau'))
          .selected,
      isFalse,
    );

    await tester.tap(find.text('Update groups'));
    await settle(tester, frames: 8);

    final captured = verify(
      () => scaffold.repository.phonebookAssociationsAssociationIdGroupsPatch(
        associationId: captureAny(named: 'associationId'),
        body: captureAny(named: 'body'),
      ),
    ).captured;
    expect((captured[1] as AssociationGroupsEdit).associatedGroups, isEmpty);
    expect(find.text('Groups updated'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('pull-to-refresh reloads the groups catalog and associations', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(id: adminGroupId, name: 'admin'),
        ],
      ),
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubAssociationAndProfilePictures(scaffold);
    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([association('a-1', 'Robot Club')]),
    );
    when(() => scaffold.repository.groupsGet()).thenAnswer(
      (_) async => chopperListResponse([
        CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'Bureau'),
      ]),
    );

    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${PhonebookRouter.root}${PhonebookRouter.admin}${PhonebookRouter.editAssociationGroups}',
      pumpAndSettle: false,
    );
    await settle(tester);
    expect(find.text('Bureau'), findsOneWidget);

    // Count only the refresh's reads: the mount already happened.
    var associationCalls = 0;
    var groupCalls = 0;
    when(() => scaffold.repository.phonebookAssociationsGet())
        .thenAnswer((_) async {
          associationCalls++;
          return chopperListResponse([association('a-1', 'Robot Club')]);
        });
    when(() => scaffold.repository.groupsGet()).thenAnswer((_) async {
      groupCalls++;
      return chopperListResponse([
        CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'Bureau'),
      ]);
    });

    await tester.fling(
      find.byType(CustomScrollView).first,
      const Offset(0, 300),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await settle(tester, frames: 6);

    expect(associationCalls, 1);
    expect(groupCalls, 1);
    expect(find.text('Bureau'), findsOneWidget);
  });
}
