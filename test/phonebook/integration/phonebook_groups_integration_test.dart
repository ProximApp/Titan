import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_provider.dart';
import 'package:titan/phonebook/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/phonebook_fixtures.dart';

/// The groups page's AdminMiddleware gates on isAdminProvider (plain admin).
const plainAdminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    phonebookSetUp(scaffold);
  });

  testWidgets(
    'deep link to /phonebook/admin/edit_association_groups toggles the association groups',
    (tester) async {
      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(
          groups: [
            CoreGroupSimple.empty().copyWith(
              id: plainAdminGroupId,
              name: 'admin',
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
}
