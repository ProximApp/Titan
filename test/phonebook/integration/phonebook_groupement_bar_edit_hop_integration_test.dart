import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_groupement_provider.dart';
import 'package:titan/phonebook/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';
import '../phonebook_fixtures.dart';

/// The editable groupement bar's Edit action: it stores the long-pressed
/// groupement and hops to the groupement form. One router hop per file —
/// qlevar 1.12.4 runs the init-path middleware chain only on the isolate's
/// first navigation.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    shellTestSetUp(scaffold);
  });

  testWidgets('long-press then Edit opens the groupement form for that chip', (
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
    await settle(tester, frames: 12);

    expect(find.text('Clubs'), findsOneWidget);

    await tester.longPress(find.text('Clubs'));
    await tester.pump();
    await settle(tester, frames: 8);
    expect(find.text('Edit'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    for (
      var i = 0;
      i < 20 && find.text('Edit association groupement').evaluate().isEmpty;
      i++
    ) {
      await settle(tester, frames: 4);
    }

    // The form mounted for the stored groupement: edit-mode title, prefilled
    // name from the chip.
    expect(find.text('Edit association groupement'), findsOneWidget);
    expect(find.text('Groupement name'), findsOneWidget);
    expect(container.read(associationGroupementProvider).id, 'grp-1');
    // Scoped to the form's own field: the parent association form (still in
    // the stack below the child route) also carries TextFields.
    final nameField = tester.widget<TextField>(
      find.ancestor(
        of: find.text('Groupement name'),
        matching: find.byType(TextField),
      ),
    );
    expect(nameField.controller!.text, 'Clubs');
  });
}
