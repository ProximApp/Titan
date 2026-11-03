import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';
import '../phonebook_fixtures.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    shellTestSetUp(scaffold);
  });

  testWidgets(
    'deep link to /phonebook/admin lists editable associations for the admin_phonebook group',
    (tester) async {
      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(
          groups: [
            CoreGroupSimple.empty().copyWith(
              id: phonebookAdminGroupId,
              name: 'admin_phonebook',
            ),
          ],
        ),
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      stubAssociationAndProfilePictures(scaffold);
      when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
        (_) async => chopperListResponse([
          association('a-1', 'Robot Club'),
          association('a-2', 'Ghost Assoc').copyWith(deactivated: true),
        ]),
      );
      when(() => scaffold.repository.phonebookGroupementsGet()).thenAnswer(
        (_) async => chopperListResponse([groupement('grp-1', 'Clubs')]),
      );
      when(() => scaffold.repository.phonebookRoletagsGet()).thenAnswer(
        (_) async => chopperResponse(RoleTagsReturn(tags: ['President'])),
      );

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '${PhonebookRouter.root}${PhonebookRouter.admin}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // The admin list shows the "Associations" header and the editable
      // card for the live association.
      expect(find.text('Associations'), findsOneWidget);
      expect(find.text('Robot Club'), findsOneWidget);
    },
  );

  testWidgets('pull-to-refresh reloads the associations and role tags', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(
            id: phonebookAdminGroupId,
            name: 'admin_phonebook',
          ),
        ],
      ),
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubAssociationAndProfilePictures(scaffold);
    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([association('a-1', 'Robot Club')]),
    );
    when(() => scaffold.repository.phonebookGroupementsGet()).thenAnswer(
      (_) async => chopperListResponse([groupement('grp-1', 'Clubs')]),
    );
    when(() => scaffold.repository.phonebookRoletagsGet()).thenAnswer(
      (_) async => chopperResponse(RoleTagsReturn(tags: ['President'])),
    );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${PhonebookRouter.root}${PhonebookRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester);
    expect(find.text('Robot Club'), findsOneWidget);

    // Count only the refresh's reads: the initial mount already happened.
    var associationCalls = 0;
    var roleTagCalls = 0;
    when(() => scaffold.repository.phonebookAssociationsGet())
        .thenAnswer((_) async {
          associationCalls++;
          return chopperListResponse([association('a-1', 'Robot Club')]);
        });
    when(() => scaffold.repository.phonebookRoletagsGet())
        .thenAnswer((_) async {
          roleTagCalls++;
          return chopperResponse(RoleTagsReturn(tags: ['President']));
        });

    // The host takes Refresher's iOS branch (CupertinoSliverRefreshControl).
    await tester.fling(
      find.byType(CustomScrollView).first,
      const Offset(0, 300),
      1000,
    );
    await tester.pump(); // release the drag
    await tester.pump(const Duration(seconds: 1)); // control asks for data
    await tester.pump(const Duration(seconds: 1)); // reloads settle
    await settle(tester, frames: 6);

    expect(associationCalls, 1);
    expect(roleTagCalls, 1);
    // The page rebuilt from the fresh reads instead of falling apart.
    expect(find.text('Robot Club'), findsOneWidget);
  });
}
