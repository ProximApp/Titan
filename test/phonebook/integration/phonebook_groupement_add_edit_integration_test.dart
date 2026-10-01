import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_groupement_provider.dart';
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
      stubPhonebookPictures(scaffold);
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
}
