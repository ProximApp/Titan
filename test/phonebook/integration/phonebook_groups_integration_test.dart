import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_provider.dart';
import 'package:titan/phonebook/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';

/// The groups page's AdminMiddleware gates on isAdminProvider (plain admin).

void main() {
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
}
