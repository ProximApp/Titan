import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
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
      stubPhonebookPictures(scaffold);
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
}
