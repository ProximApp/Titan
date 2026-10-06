import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The plant deposit page (`/seed_library/seed_deposit`, 119 executable
/// lines): the seed-library admin form to add a stock plant from an
/// ancestor plant or directly from a species. The seed-library admin group
/// id matches the existing shells (see isSeedLibraryAdminProvider).
const seedLibraryAdminGroupId = '09153d2a-14f4-49a4-be57-5d0f265261b9';

final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [
    CoreGroupSimple(name: 'admin_seed_library', id: seedLibraryAdminGroupId),
  ],
);

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

void stubSeedLibrary(IntegrationScaffold scaffold) {
  when(
    () => scaffold.repository.seedLibraryInformationGet(),
  ).thenAnswer((_) async => chopperResponse(SeedLibraryInformation.empty()));
  when(
    () => scaffold.repository.seedLibrarySpeciesGet(),
  ).thenAnswer((_) async => chopperListResponse([species()]));
  // syncMyPlantListProvider (the ancestor row + the not-available gate)
  // reads the users/me endpoint.
  when(() => scaffold.repository.seedLibraryPlantsUsersMeGet()).thenAnswer(
    (_) async => chopperListResponse([
      waitingPlant('mine-1', 'BAS-0100'),
      waitingPlant('mine-2', 'BAS-0101'),
    ]),
  );
  // plantListProvider (the ancestor/stock list the deposit adds to). Its
  // success path builds the reference dialog from plantList.last, so the
  // list must be non-empty.
  when(() => scaffold.repository.seedLibraryPlantsWaitingGet()).thenAnswer(
    (_) async => chopperListResponse([waitingPlant('wait-1', 'BAS-0200')]),
  );
}

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
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('the deposit form renders the waiting plants and species', (
    tester,
  ) async {
    stubSeedLibrary(scaffold);

    await pumpDeposit(tester, scaffold.makeContainer(user: adminUser));

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
    stubSeedLibrary(scaffold);
    // The POST answer carries the NEW stock reference the backend assigns;
    // the dialog must show it, not the stale pre-add last (ledger #28).
    when(
      () => scaffold.repository.seedLibraryPlantsPost(body: any(named: 'body')),
    ).thenAnswer(
      (_) async => chopperResponse(
        PlantSimple.empty().copyWith(id: 'np-1', reference: 'BAS-0300'),
      ),
    );

    final container = scaffold.makeContainer(user: adminUser);
    await pumpDeposit(tester, container);

    // Select the species card, fill the seed quantity, save.
    await tester.tap(find.text('ZZZ'), warnIfMissed: false);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
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
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

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
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(find.byType(AlertDialog), findsNothing);
    await scaffold.drainToast(tester);
  });

  testWidgets(
    'the empty required field blocks the submit with an inline error',
    (tester) async {
      stubSeedLibrary(scaffold);

      await pumpDeposit(tester, scaffold.makeContainer(user: adminUser));

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
    stubSeedLibrary(scaffold);
    when(
      () => scaffold.repository.seedLibraryPlantsUsersMeGet(),
    ).thenAnswer((_) async => chopperListResponse(<PlantSimple>[]));

    await pumpDeposit(tester, scaffold.makeContainer());

    // Non-admin with an empty my-plants list: the whole form is replaced
    // by the explanation (my plants come from the users/me endpoint,
    // stubbed empty here).
    expect(find.textContaining('dépôt de plantes'), findsOneWidget);
    expect(find.text('Ajouter'), findsNothing);
  });
}
