import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_groupement_provider.dart';
import 'package:titan/phonebook/providers/association_provider.dart';
import 'package:titan/phonebook/router.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';
import '../phonebook_fixtures.dart';

/// The admin page's + button — the one router hop in this file (qlevar
/// 1.12.4 runs the init-path middleware chain only on an isolate's first
/// navigation, so every gating file owns a single deep link and hop).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    shellTestSetUp(scaffold);
  });

  testWidgets('the + button on the admin page resets and opens the add form', (
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

    // Both selections preloaded: the + onPressed resets them before it
    // navigates, and only this tap reaches those two lines.
    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));
    container
        .read(associationGroupementProvider.notifier)
        .setAssociationGroupement(groupement('grp-1', 'Clubs'));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${PhonebookRouter.root}${PhonebookRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.text('Associations'), findsOneWidget);
    // The header's plus (first in tree order; cards below may carry their
    // own icons).
    await tester.tap(
      find
          .byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus)
          .first,
    );
    for (
      var i = 0;
      i < 20 && find.text('Add an association').evaluate().isEmpty;
      i++
    ) {
      await settle(tester, frames: 4);
    }

    expect(find.text('Add an association'), findsOneWidget);
    expect(container.read(associationProvider).id, '');
    expect(container.read(associationGroupementProvider).id, '');
  });
}
