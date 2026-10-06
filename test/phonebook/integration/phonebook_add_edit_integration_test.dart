import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_groupement_provider.dart';
import 'package:titan/phonebook/providers/association_provider.dart';
import 'package:titan/phonebook/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/phonebook_fixtures.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    phonebookSetUp(scaffold);
  });

  testWidgets(
    'deep link to /phonebook/admin/add_edit_association shows the add form',
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
      stubPhonebookPictures(scaffold);
      when(
        () => scaffold.repository.phonebookAssociationsGet(),
      ).thenAnswer((_) async => chopperListResponse(<AssociationComplete>[]));
      when(() => scaffold.repository.phonebookGroupementsGet()).thenAnswer(
        (_) async => chopperListResponse([groupement('grp-1', 'Clubs')]),
      );

      await scaffold.pumpApp(
        tester,
        container,
        initialPath:
            '${PhonebookRouter.root}${PhonebookRouter.admin}${PhonebookRouter.addEditAssociation}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // Add mode: no association selected. TextEntry renders the label via
      // InputDecoration.labelText; canBeEmpty fields get " (Optional)".
      expect(find.text('Add an association'), findsOneWidget);
      expect(find.text('Association name'), findsOneWidget);
      expect(find.text('Description (Optional)'), findsOneWidget);
    },
  );

  testWidgets(
    'the add_edit_association form prefills from the selected association in edit mode',
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
      stubPhonebookPictures(scaffold);
      when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
        (_) async => chopperListResponse([association('a-1', 'Robot Club')]),
      );
      when(() => scaffold.repository.phonebookGroupementsGet()).thenAnswer(
        (_) async => chopperListResponse([groupement('grp-1', 'Clubs')]),
      );

      container
          .read(associationProvider.notifier)
          .setAssociation(association('a-1', 'Robot Club'));
      container
          .read(associationGroupementProvider.notifier)
          .setAssociationGroupement(groupement('grp-1', 'Clubs'));

      await scaffold.pumpApp(
        tester,
        container,
        initialPath:
            '${PhonebookRouter.root}${PhonebookRouter.admin}${PhonebookRouter.addEditAssociation}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // Edit mode title (a second "Edit" is the submit Button's label).
      expect(find.text('Edit'), findsNWidgets(2));
      expect(find.text('Robot Club'), findsOneWidget);
      expect(find.text('We build robots'), findsOneWidget);
    },
  );
}
