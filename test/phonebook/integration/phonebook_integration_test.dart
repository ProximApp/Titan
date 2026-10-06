import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/phonebook_fixtures.dart';
import 'package:titan/phonebook/router.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    phonebookSetUp(scaffold);
  });

  testWidgets('deep link to /phonebook lists associations by groupement', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubPhonebookPictures(scaffold);
    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([
        association('a-1', 'Robot Club'),
        association('a-2', 'Café Théâtre', groupementId: 'grp-1'),
      ]),
    );
    when(() => scaffold.repository.phonebookGroupementsGet()).thenAnswer(
      (_) async => chopperListResponse([groupement('grp-1', 'Clubs')]),
    );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: PhonebookRouter.root,
      pumpAndSettle: false,
    );
    await settle(tester);

    // Both association cards render (plain Text, not RichText).
    expect(find.text('Robot Club'), findsOneWidget);
    expect(find.text('Café Théâtre'), findsOneWidget);
    // The search bar's hint is the l10n string.
    expect(find.text('Search'), findsOneWidget);
  });

  testWidgets('the search filter removes non-matching associations live', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubPhonebookPictures(scaffold);
    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([
        association('a-1', 'Robot Club'),
        association('a-2', 'Café Théâtre'),
      ]),
    );
    when(() => scaffold.repository.phonebookGroupementsGet()).thenAnswer(
      (_) async => chopperListResponse([groupement('grp-1', 'Clubs')]),
    );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: PhonebookRouter.root,
      pumpAndSettle: false,
    );
    await settle(tester);

    // Type into the real search TextField.
    await tester.enterText(find.byType(TextField), 'robot');
    await settle(tester, frames: 6);

    expect(find.text('Robot Club'), findsOneWidget);
    expect(find.text('Café Théâtre'), findsNothing);
  });
}
