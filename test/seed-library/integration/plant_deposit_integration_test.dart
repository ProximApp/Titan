import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/repository_test_support.dart' show chopperError;
import '../seed_library_fixtures.dart';

/// The plant deposit page (`/seed_library/seed_deposit`, 119 executable
/// lines): the seed-library admin form to add a stock plant from an
/// ancestor plant or directly from a species. The seed-library admin group
/// id matches the existing shells (see isSeedLibraryAdminProvider).
SpeciesComplete species({String id = 'sp-1', String name = 'Basilic'}) =>
    SpeciesComplete.empty().copyWith(
      id: id,
      prefix: 'ZZZ',
      name: name,
      difficulty: 2,
      speciesType: SpeciesType.plantesAromatiques,
      nbSeedsRecommended: 40,
    );

PlantSimple waitingPlant(String id, String reference) =>
    PlantSimple.empty().copyWith(
      id: id,
      reference: reference,
      speciesId: 'sp-1',
      state: PlantState.enAttente,
      propagationMethod: PropagationMethod.bouture,
    );

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pumpDeposit(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/seed_library/seed_deposit',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);
  }

  testWidgets('the deposit form renders the waiting plants and species', (
    tester,
  ) async {
    stubSeedLibrary(
      scaffold,
      species: [species()],
      mine: [
        waitingPlant('mine-1', 'BAS-0100'),
        waitingPlant('mine-2', 'BAS-0101'),
      ],
      waiting: [waitingPlant('wait-1', 'BAS-0200')],
    );

    await pumpDeposit(
      tester,
      scaffold.makeContainer(user: seedLibraryAdminUser),
    );

    expect(find.text('Déposer une plante'), findsOneWidget);
    expect(find.text('Ancêtre'), findsOneWidget);
    // The user's plants are the ancestor candidates (each card shows its
    // species name + reference).
    expect(find.text('BAS-0100'), findsOneWidget);
    expect(find.text('BAS-0101'), findsOneWidget);
    // Admins also get the species row (a non-admin without my-plants sees
    // the not-available message instead — covered by the last test).
    expect(find.text('Espèce'), findsOneWidget);
    expect(find.text('Basilic'), findsNWidgets(3));
    // The graine propagation method is the default, so the seed quantity
    // field shows (without the recommendation hint: no species selected
    // yet).
    expect(find.textContaining('Quantité de graines'), findsOneWidget);
    expect(find.textContaining('environ'), findsNothing);
  });

  testWidgets('a deposit from a species round-trips the POST', (tester) async {
    stubSeedLibrary(
      scaffold,
      species: [species()],
      mine: [
        waitingPlant('mine-1', 'BAS-0100'),
        waitingPlant('mine-2', 'BAS-0101'),
      ],
      waiting: [waitingPlant('wait-1', 'BAS-0200')],
    );
    // The POST answer carries the NEW stock reference the backend assigns;
    // the dialog must show it, not the stale pre-add last (ledger #28).
    when(
      () => scaffold.repository.seedLibraryPlantsPost(body: any(named: 'body')),
    ).thenAnswer(
      (_) async => chopperResponse(
        PlantSimple.empty().copyWith(id: 'np-1', reference: 'BAS-0300'),
      ),
    );

    final container = scaffold.makeContainer(user: seedLibraryAdminUser);
    await pumpDeposit(tester, container);

    // Select the species card, fill the seed quantity, save.
    await tester.tap(find.text('ZZZ'), warnIfMissed: false);
    await settle(tester, frames: 4);
    // Selecting a species adds the recommendation hint to the field label.
    expect(find.textContaining('environ 40'), findsOneWidget);
    final quantityField = find
        .ancestor(
          of: find.textContaining('Quantité de graines'),
          matching: find.byType(TextFormField),
        )
        .first;
    await tester.enterText(quantityField, '12');
    await scaffold.unfocus(tester);
    await tester.ensureVisible(find.text('Ajouter'));
    await settle(tester, frames: 2);
    await tester.tap(find.text('Ajouter'));
    await settle(tester, frames: 14);

    final captured =
        verify(
              () => scaffold.repository.seedLibraryPlantsPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as PlantCreation;
    expect(captured.speciesId, 'sp-1');
    expect(captured.ancestorId, isNull);
    expect(captured.nbSeedsEnvelope, 12);
    expect(captured.propagationMethod, PropagationMethod.graine);

    // Success: the toast shows and the reference dialog carries the NEW
    // stock reference read from the current plantListProvider state (the
    // POST's add() appended it — the pre-add last was BAS-0200, ledger
    // #28 fixed).
    expect(find.text('Plante ajoutée'), findsOneWidget);
    expect(find.textContaining('BAS-0300'), findsOneWidget);
    expect(find.textContaining('BAS-0200'), findsNothing);
    // Dismiss the dialog through its OK button.
    await tester.tap(find.text('OK'));
    await settle(tester, frames: 8);
    expect(find.byType(AlertDialog), findsNothing);
    await scaffold.drainToast(tester);
  });

  testWidgets(
    'the empty required field blocks the submit with an inline error',
    (tester) async {
      stubSeedLibrary(
        scaffold,
        species: [species()],
        mine: [
          waitingPlant('mine-1', 'BAS-0100'),
          waitingPlant('mine-2', 'BAS-0101'),
        ],
        waiting: [waitingPlant('wait-1', 'BAS-0200')],
      );

      await pumpDeposit(
        tester,
        scaffold.makeContainer(user: seedLibraryAdminUser),
      );

      // No ancestor, no species: the guard fires with the choosing toast.
      await scaffold.unfocus(tester);
      await tester.ensureVisible(find.text('Ajouter'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Ajouter'));
      await tester.pump();
      await tester.pump();

      // The empty required quantity field shows its inline validator error
      // (noValueError "This field is required") and no POST is attempted.
      expect(find.text('This field is required'), findsOneWidget);
      verifyNever(
        () =>
            scaffold.repository.seedLibraryPlantsPost(body: any(named: 'body')),
      );
      await scaffold.drainToast(tester);
    },
  );

  testWidgets('a user without plants sees the not-available message', (
    tester,
  ) async {
    stubSeedLibrary(
      scaffold,
      species: [species()],
      mine: [
        waitingPlant('mine-1', 'BAS-0100'),
        waitingPlant('mine-2', 'BAS-0101'),
      ],
      waiting: [waitingPlant('wait-1', 'BAS-0200')],
    );
    when(() => scaffold.repository.seedLibraryPlantsUsersMeGet())
        .thenAnswer((_) async => chopperListResponse(<PlantSimple>[]));

    await pumpDeposit(tester, scaffold.makeContainer());

    // Non-admin with an empty my-plants list: the whole form is replaced
    // by the explanation (my plants come from the users/me endpoint,
    // stubbed empty here).
    expect(find.textContaining('dépôt de plantes'), findsOneWidget);
    expect(find.text('Ajouter'), findsNothing);
  });

  testWidgets('an orphan species does not take the deposit page down', (
    tester,
  ) async {
    // Unlike the plants and stock lists — which go through
    // myPlantsFilteredListProvider and drop plants whose species is gone —
    // the deposit page maps the RAW my-plants list, so an orphan
    // `speciesId` reaches SmallPlantCard's unguarded
    // `species.firstWhere(...)` and threw "Bad state: No element" straight
    // out of build, killing the whole form. The ancestor branch (the
    // ternary one line above the list) does the same lookup and is pinned
    // by the tap below.
    stubSeedLibrary(
      scaffold,
      species: [species()],
      mine: [
        waitingPlant('mine-1', 'BAS-0100').copyWith(speciesId: 'sp-deleted'),
      ],
    );

    await pumpDeposit(
      tester,
      scaffold.makeContainer(user: seedLibraryAdminUser),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Déposer une plante'), findsOneWidget);
    // The orphan card still lists, under the empty species' blank label.
    expect(find.text('BAS-0100'), findsOneWidget);

    // Selecting it drives the ancestor branch of the same lookup.
    await tester.tap(find.text('BAS-0100'));
    await settle(tester, frames: 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('re-tapping the chosen plant and species clears them', (
    tester,
  ) async {
    stubSeedLibrary(
      scaffold,
      species: [species()],
      mine: [waitingPlant('mine-1', 'BAS-0100')],
    );
    await pumpDeposit(
      tester,
      scaffold.makeContainer(user: seedLibraryAdminUser),
    );

    // Select the ancestor: the species row disappears while one is chosen.
    await tester.tap(find.text('BAS-0100'));
    await settle(tester, frames: 8);
    expect(find.text('Espèce'), findsNothing);

    // Re-tapping the selected card clears the choice, which brings the
    // species row back.
    await tester.tap(find.text('BAS-0100'));
    await settle(tester, frames: 8);
    expect(find.text('Espèce'), findsOneWidget);

    // The same toggle on the species card.
    await tester.tap(find.text('ZZZ'));
    await settle(tester, frames: 6);
    expect(find.textContaining('environ 40'), findsOneWidget);
    await tester.tap(find.text('ZZZ'));
    await settle(tester, frames: 6);
    expect(find.textContaining('environ 40'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching to bouture drops the seed quantity field', (
    tester,
  ) async {
    stubSeedLibrary(
      scaffold,
      species: [species()],
      mine: [waitingPlant('mine-1', 'BAS-0100')],
    );
    await pumpDeposit(
      tester,
      scaffold.makeContainer(user: seedLibraryAdminUser),
    );

    expect(find.textContaining('Quantité de graines'), findsOneWidget);
    await tester.tap(find.text('bouture'));
    await settle(tester, frames: 6);

    expect(find.textContaining('Quantité de graines'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a deposit with no plant or species reports the choice', (
    tester,
  ) async {
    stubSeedLibrary(
      scaffold,
      species: [species()],
      mine: [waitingPlant('mine-1', 'BAS-0100')],
    );
    await pumpDeposit(
      tester,
      scaffold.makeContainer(user: seedLibraryAdminUser),
    );

    final quantityField = find
        .ancestor(
          of: find.textContaining('Quantité de graines'),
          matching: find.byType(TextFormField),
        )
        .first;
    await tester.enterText(quantityField, '5');
    await scaffold.unfocus(tester);
    await tester.ensureVisible(find.text('Ajouter'));
    await settle(tester, frames: 2);
    await tester.tap(find.text('Ajouter'));
    await settle(tester, frames: 10);

    expect(
      find.text('Veuillez choisir une espèce ou un ancêtre'),
      findsOneWidget,
    );
    verifyNever(
      () => scaffold.repository.seedLibraryPlantsPost(body: any(named: 'body')),
    );
    await scaffold.drainToast(tester);
  });

  testWidgets('a refused deposit reports the error and stays put', (
    tester,
  ) async {
    stubSeedLibrary(
      scaffold,
      species: [species()],
      mine: [waitingPlant('mine-1', 'BAS-0100')],
    );
    when(
      () => scaffold.repository.seedLibraryPlantsPost(body: any(named: 'body')),
    ).thenAnswer((_) async => chopperError<PlantSimple>(500));
    await pumpDeposit(
      tester,
      scaffold.makeContainer(user: seedLibraryAdminUser),
    );

    await tester.tap(find.text('ZZZ'));
    await settle(tester, frames: 4);
    final quantityField = find
        .ancestor(
          of: find.textContaining('Quantité de graines'),
          matching: find.byType(TextFormField),
        )
        .first;
    await tester.enterText(quantityField, '7');
    await scaffold.unfocus(tester);
    await tester.ensureVisible(find.text('Ajouter'));
    await settle(tester, frames: 2);
    await tester.tap(find.text('Ajouter'));
    await settle(tester, frames: 14);

    expect(find.text("Erreur lors de l'ajout"), findsOneWidget);
    // No reference dialog: nothing was created.
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
    await scaffold.drainToast(tester);
  });

  testWidgets('a deposit from an ancestor posts the ancestor and its species', (
    tester,
  ) async {
    stubSeedLibrary(
      scaffold,
      species: [species()],
      mine: [waitingPlant('mine-1', 'BAS-0100')],
    );
    // The ancestor's own note pre-fills the notes field when it is picked.
    when(
      () => scaffold.repository.seedLibraryPlantsPlantIdGet(
        plantId: any(named: 'plantId'),
      ),
    ).thenAnswer(
      (_) async => chopperResponse(
        PlantComplete.empty().copyWith(
          id: 'mine-1',
          reference: 'BAS-0100',
          currentNote: 'Bouture du jardin',
        ),
      ),
    );
    when(
      () => scaffold.repository.seedLibraryPlantsPost(body: any(named: 'body')),
    ).thenAnswer(
      (_) async => chopperResponse(
        PlantSimple.empty().copyWith(id: 'np-1', reference: 'BAS-0301'),
      ),
    );

    await pumpDeposit(
      tester,
      scaffold.makeContainer(user: seedLibraryAdminUser),
    );

    await tester.tap(find.text('BAS-0100'));
    await settle(tester, frames: 10);
    // The loaded ancestor's note replaced the empty field.
    expect(find.text('Bouture du jardin'), findsOneWidget);

    final quantityField = find
        .ancestor(
          of: find.textContaining('Quantité de graines'),
          matching: find.byType(TextFormField),
        )
        .first;
    await tester.enterText(quantityField, '3');
    await scaffold.unfocus(tester);
    await tester.ensureVisible(find.text('Ajouter'));
    await settle(tester, frames: 2);
    await tester.tap(find.text('Ajouter'));
    await settle(tester, frames: 14);

    final captured =
        verify(
              () => scaffold.repository.seedLibraryPlantsPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as PlantCreation;
    // The ancestor branch: its id stands in, and the species comes from the
    // chosen plant rather than from the selection.
    expect(captured.ancestorId, 'mine-1');
    expect(captured.speciesId, 'sp-1');
    await scaffold.drainToast(tester);
  });

  testWidgets('a non-admin with no choice is told to pick an ancestor', (
    tester,
  ) async {
    stubSeedLibrary(
      scaffold,
      species: [species()],
      mine: [waitingPlant('mine-1', 'BAS-0100')],
    );
    // A plain user with one of their own plants: no species row, so the only
    // way forward is an ancestor and the guard says exactly that.
    when(() => scaffold.repository.seedLibraryPlantsUsersMeGet()).thenAnswer(
      (_) async => chopperListResponse([waitingPlant('mine-1', 'BAS-0100')]),
    );

    await pumpDeposit(tester, scaffold.makeContainer());

    expect(find.text('Espèce'), findsNothing);
    final quantityField = find
        .ancestor(
          of: find.textContaining('Quantité de graines'),
          matching: find.byType(TextFormField),
        )
        .first;
    await tester.enterText(quantityField, '4');
    await scaffold.unfocus(tester);
    await tester.ensureVisible(find.text('Ajouter'));
    await settle(tester, frames: 2);
    await tester.tap(find.text('Ajouter'));
    await settle(tester, frames: 10);

    expect(find.text('Veuillez choisir un ancêtre'), findsOneWidget);
    verifyNever(
      () => scaffold.repository.seedLibraryPlantsPost(body: any(named: 'body')),
    );
    await scaffold.drainToast(tester);
  });
}
