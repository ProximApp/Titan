import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_groupement_provider.dart';
import 'package:titan/phonebook/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';
import '../phonebook_fixtures.dart';

/// qlevar_router 1.12.4 only processes the init-path middleware chain on the
/// first navigation of an isolate, so this file owns exactly one router hop:
/// the main page's Admin shortcut into /phonebook/admin.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    shellTestSetUp(scaffold);
  });

  testWidgets('the Admin shortcut on the main page opens the admin shell', (
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

    // Preselect a groupement: the hop's onTap resets it, which is the arm
    // only this navigation can reach.
    container
        .read(associationGroupementProvider.notifier)
        .setAssociationGroupement(groupement('grp-1', 'Clubs'));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: PhonebookRouter.root,
      pumpAndSettle: false,
    );
    await settle(tester);

    // The admin shortcut renders for the admin_phonebook group.
    expect(find.text('Admin'), findsOneWidget);
    await tester.tap(find.text('Admin'));
    for (
      var i = 0;
      i < 20 && find.text('Associations').evaluate().isEmpty;
      i++
    ) {
      await settle(tester, frames: 4);
    }

    // The admin shell mounted and the groupement selection was cleared
    // before the hop.
    expect(find.text('Associations'), findsOneWidget);
    expect(container.read(associationGroupementProvider).id, '');
  });
}
