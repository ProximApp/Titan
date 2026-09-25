import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_groupement_provider.dart';
import 'package:titan/phonebook/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(MockAssociationGroupementBase.any);
  });

  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    shellTestSetUp(scaffold);
  });

  testWidgets(
    'deep link to /phonebook/admin/add_edit_association/add_edit_groupement prefills the selected groupement',
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
      when(
        () => scaffold.repository.phonebookAssociationsGet(),
      ).thenAnswer((_) async => chopperListResponse(<AssociationComplete>[]));
      when(() => scaffold.repository.phonebookGroupementsGet()).thenAnswer(
        (_) async => chopperListResponse([groupement('grp-1', 'Clubs')]),
      );

      container
          .read(associationGroupementProvider.notifier)
          .setAssociationGroupement(groupement('grp-1', 'Clubs'));

      await scaffold.pumpApp(
        tester,
        container,
        initialPath:
            '${PhonebookRouter.root}${PhonebookRouter.admin}${PhonebookRouter.addEditAssociation}${PhonebookRouter.addEditGroupement}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // The edit-mode title proves the pre-selected groupement reached the
      // form; the name label proves the form itself rendered.
      expect(find.text('Edit association groupement'), findsOneWidget);
      expect(find.text('Groupement name'), findsOneWidget);
    },
  );

  testWidgets('the groupement form refuses an empty name then creates', (
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
    when(() => scaffold.repository.phonebookAssociationsGet())
        .thenAnswer((_) async => chopperListResponse(<AssociationComplete>[]));
    when(
      () => scaffold.repository.phonebookGroupementsGet(),
    ).thenAnswer((_) async => chopperListResponse(<AssociationGroupement>[]));

    var createCalls = 0;
    when(
      () => scaffold.repository.phonebookGroupementsPost(
        body: any(named: 'body'),
      ),
    ).thenAnswer((invocation) async {
      createCalls++;
      final body =
          invocation.namedArguments[#body] as AssociationGroupementBase;
      return chopperResponse(
        MockAssociationGroupement.any.copyWith(
          id: 'grp-new',
          name: body.name,
          managerGroupId: body.managerGroupId,
        ),
      );
    });

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${PhonebookRouter.root}${PhonebookRouter.admin}'
          '${PhonebookRouter.addEditAssociation}'
          '${PhonebookRouter.addEditGroupement}',
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.text('Add an association groupement'), findsOneWidget);
    expect(find.text('Groupement name'), findsOneWidget);

    // Empty input is rejected locally; no groupement is sent.
    await tester.tap(find.text('Add'));
    await settle(tester, frames: 4);
    expect(createCalls, 0);
    await scaffold.drainToast(tester);

    await tester.enterText(find.byType(TextField).first, 'Culture');
    await scaffold.unfocus(tester);
    await tester.tap(find.text('Add'));
    await settle(tester, frames: 6);

    expect(createCalls, 1);
    final captured =
        verify(
              () => scaffold.repository.phonebookGroupementsPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as AssociationGroupementBase;
    expect(captured.name, 'Culture');
    expect(captured.managerGroupId, isEmpty);
    expect(find.text('Association added'), findsOneWidget);
    await scaffold.drainToast(tester);
  });
}
