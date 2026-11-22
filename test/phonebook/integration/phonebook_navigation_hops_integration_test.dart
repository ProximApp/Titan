import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_groupement_provider.dart';
import 'package:titan/phonebook/providers/association_provider.dart';
import 'package:titan/phonebook/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';
import '../phonebook_fixtures.dart';

/// Two navigation edges of the phonebook shell:
///
/// 1. a card on `/phonebook` selecting its association and opening it,
/// 2. the shell's back button clearing the selected groupement when it
///    leaves one of the paths that scope it.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    shellTestSetUp(scaffold);
  });

  testWidgets('a card on the phonebook main page selects and opens its '
      'association', (tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubAssociationAndProfilePictures(scaffold);
    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([association('a-1', 'Robot Club')]),
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
    await settle(tester, frames: 20);

    expect(find.text('Robot Club'), findsOneWidget);
    expect(find.text('Clubs'), findsOneWidget);

    // The card's tap is the only route into an association from the list.
    await tester.tap(find.text('Robot Club'));
    await settle(tester, frames: 24);

    expect(container.read(associationProvider).id, 'a-1');
    expect(container.read(associationGroupementProvider).id, 'grp-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving a scoped page with the shell back button clears the '
      'selected groupement', (tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubAssociationAndProfilePictures(scaffold);
    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([association('a-1', 'Robot Club')]),
    );
    when(() => scaffold.repository.phonebookGroupementsGet()).thenAnswer(
      (_) async => chopperListResponse([groupement('grp-1', 'Clubs')]),
    );
    when(
      () => scaffold.repository.phonebookAssociationsAssociationIdMembersGet(
        associationId: any(named: 'associationId'),
      ),
    ).thenAnswer((_) async => chopperListResponse(<MemberComplete>[]));

    container
        .read(associationGroupementProvider.notifier)
        .setAssociationGroupement(groupement('grp-1', 'Clubs'));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${PhonebookRouter.root}${PhonebookRouter.associationDetail}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);
    expect(container.read(associationGroupementProvider).id, 'grp-1');

    // The page's own shell renders the back button on this scoped path; it
    // must drop the groupement so the next visit starts unscoped.
    final back = find.byType(IconButton);
    expect(back, findsOneWidget);
    await tester.tap(back);
    await settle(tester, frames: 24);

    expect(container.read(associationGroupementProvider).id, '');
    expect(tester.takeException(), isNull);
  });
}
