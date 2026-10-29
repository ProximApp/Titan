import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';

import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_groupement_provider.dart';
import 'package:titan/phonebook/router.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';

import '../phonebook_fixtures.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    shellTestSetUp(scaffold);
  });

  testWidgets('deep link to /phonebook lists associations by groupement', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubAssociationAndProfilePictures(scaffold);
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
    stubAssociationAndProfilePictures(scaffold);
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

  testWidgets('an empty catalog shows the no-association state', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
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
      initialPath: PhonebookRouter.root,
      pumpAndSettle: false,
    );
    await settle(tester);

    // The empty branch of the main page's Async2Children builder.
    expect(find.text('No association found'), findsOneWidget);
  });

  testWidgets('the filter button opens the modal with the vertical chip bar '
      'and closes it', (tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubAssociationAndProfilePictures(scaffold);
    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([
        association('a-1', 'Robot Club'),
        association('a-2', 'Café Théâtre', groupementId: 'grp-2'),
      ]),
    );
    // Two groupements is what makes onFilter non-null (a lone one drops
    // the filter button entirely).
    when(() => scaffold.repository.phonebookGroupementsGet()).thenAnswer(
      (_) async => chopperListResponse([
        groupement('grp-1', 'Clubs'),
        groupement('grp-2', 'Culture'),
      ]),
    );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: PhonebookRouter.root,
      pumpAndSettle: false,
    );
    await settle(tester);

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.adjustmentsHorizontal,
      ),
    );
    await tester.pump();
    await settle(tester, frames: 8);

    expect(find.text('Filter'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    // The modal embeds the groupement bar with its vertical sizing branch.
    // Chips are scoped to the modal: the cards behind it print the same
    // groupement names.
    final modal = find.byType(BottomModalTemplate);
    expect(modal, findsOneWidget);
    expect(
      find.descendant(of: modal, matching: find.text('Clubs')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: modal, matching: find.text('Culture')),
      findsOneWidget,
    );

    // Selecting a chip drives the filtered-list provider behind the modal.
    await tester.tap(
      find.descendant(of: modal, matching: find.text('Culture')),
    );
    await settle(tester, frames: 4);
    expect(container.read(associationGroupementProvider).id, 'grp-2');

    await tester.tap(find.text('Close'));
    await settle(tester, frames: 8);
    expect(find.text('Filter'), findsNothing);
    expect(find.text('Café Théâtre'), findsOneWidget);
    expect(find.text('Robot Club'), findsNothing);
  });

  testWidgets('pull-to-refresh reloads the groupements and associations', (
    tester,
  ) async {
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
    await settle(tester);
    expect(find.text('Robot Club'), findsOneWidget);

    // Count only the refresh's reads: the initial mount already happened.
    var groupementCalls = 0;
    var associationCalls = 0;
    when(() => scaffold.repository.phonebookGroupementsGet())
        .thenAnswer((_) async {
          groupementCalls++;
          return chopperListResponse([groupement('grp-1', 'Clubs')]);
        });
    when(() => scaffold.repository.phonebookAssociationsGet())
        .thenAnswer((_) async {
          associationCalls++;
          return chopperListResponse([association('a-1', 'Robot Club')]);
        });

    // The host takes Refresher's iOS branch (CupertinoSliverRefreshControl).
    await tester.fling(
      find.byType(CustomScrollView).first,
      const Offset(0, 300),
      1000,
    );
    await tester.pump(); // release the drag
    await tester.pump(const Duration(seconds: 1)); // control asks for data
    await tester.pump(const Duration(seconds: 1)); // reloads settle
    await settle(tester, frames: 6);

    expect(groupementCalls, 1);
    expect(associationCalls, 1);
    // The page rebuilt from the fresh reads instead of falling apart.
    expect(find.text('Robot Club'), findsOneWidget);
  });
}
