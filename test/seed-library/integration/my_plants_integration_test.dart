import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/seed-library/providers/plant_complete_provider.dart';
import 'package:titan/seed-library/providers/species_list_provider.dart';
import 'package:titan/seed-library/providers/species_type_list_provider.dart';
import 'package:titan/seed-library/tools/constants.dart';

import '../../shared/app_scaffold.dart';

/// MY PLANTS (`/seed_library/plants`): the three PersonalPlantCard states
/// (planted + maturation countdown, dead behind the checkbox, waiting
/// with no dates), the empty and filtered-empty messages, the checkbox and
/// search/filters interactions, plus the editable detail page's species
/// help button and its failed-death arm.
final species = SpeciesComplete.empty().copyWith(
  id: 'sp-1',
  prefix: 'BAS',
  name: 'Basilic',
  difficulty: 3,
  speciesType: SpeciesType.plantesAromatiques,
  startSeason: DateTime(2026, 4, 1),
  timeMaturation: 40,
  card: 'https://fiche.example/help',
);

final alivePlant = PlantSimple.empty().copyWith(
  id: 'p-alive',
  reference: 'BAS-0200',
  nickname: 'Basilic vivant',
  speciesId: 'sp-1',
  state: PlantState.rCupRE,
  propagationMethod: PropagationMethod.graine,
  nbSeedsEnvelope: 8,
  plantingDate: DateTime(2026, 1, 10),
);

final deadPlant = PlantSimple.empty().copyWith(
  id: 'p-dead',
  reference: 'BAS-0300',
  nickname: 'Basilic mort',
  speciesId: 'sp-1',
  state: PlantState.consommE,
  propagationMethod: PropagationMethod.graine,
  nbSeedsEnvelope: 4,
  plantingDate: DateTime(2026, 1, 20),
);

final waitingPlant = PlantSimple.empty().copyWith(
  id: 'p-wait',
  reference: 'BAS-0400',
  nickname: 'Basilic en attente',
  speciesId: 'sp-1',
  state: PlantState.enAttente,
  propagationMethod: PropagationMethod.bouture,
);

PlantComplete detailPlant({PlantState? state, DateTime? plantingDate}) =>
    PlantComplete.empty().copyWith(
      id: 'p-alive',
      reference: 'BAS-0200',
      nickname: 'Basilic vivant',
      speciesId: 'sp-1',
      state: state ?? PlantState.enAttente,
      propagationMethod: PropagationMethod.graine,
      nbSeedsEnvelope: 8,
      borrowingDate: DateTime(2025, 12, 1),
      plantingDate: plantingDate,
      currentNote: 'Arroser une fois par semaine',
    );

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  void stubPlants(
    IntegrationScaffold scaffold, {
    List<PlantSimple> mine = const [],
  }) {
    when(
      () => scaffold.repository.seedLibraryInformationGet(),
    ).thenAnswer((_) async => chopperResponse(SeedLibraryInformation.empty()));
    when(
      () => scaffold.repository.seedLibrarySpeciesGet(),
    ).thenAnswer((_) async => chopperListResponse([species]));
    when(
      () => scaffold.repository.seedLibraryPlantsWaitingGet(),
    ).thenAnswer((_) async => chopperListResponse(<PlantSimple>[]));
    when(
      () => scaffold.repository.seedLibraryPlantsUsersMeGet(),
    ).thenAnswer((_) async => chopperListResponse(mine));
    when(() => scaffold.repository.seedLibrarySpeciesTypesGet()).thenAnswer(
      (_) async => chopperResponse(
        // FiltersBar prepends plantesAromatiques — the rest must come from
        // the server (with the default `autre` filter among them) or the
        // SpeciesType dropdown's value assertion fires.
        SpeciesTypesReturn(
          speciesType: SpeciesType.values
              .where((t) => t != SpeciesType.plantesAromatiques)
              .toList(),
        ),
      ),
    );
  }

  Future<void> pumpMyPlants(WidgetTester tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    // Pre-warm before the first frame: FiltersBar is expanded on mount and
    // its SpeciesType dropdown asserts on an empty item list.
    container.read(speciesTypeListProvider);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/seed_library/plants',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 10);
  }

  // FIRST navigation of the file: my plants itself.
  testWidgets(
    'renders the three card states, toggles death and filters the list',
    (tester) async {
      stubPlants(scaffold, mine: [alivePlant, deadPlant, waitingPlant]);
      when(
        () => scaffold.repository.seedLibraryPlantsPlantIdGet(
          plantId: any(named: 'plantId'),
        ),
      ).thenAnswer((_) async => chopperResponse(detailPlant()));

      await pumpMyPlants(tester);

      expect(find.text(SeedLibraryTextConstants.myPlants), findsWidgets);
      expect(
        find.text(SeedLibraryTextConstants.showDeadPlants),
        findsOneWidget,
      );
      // Alive + waiting cards visible; the dead one is behind the
      // unchecked "show dead plants" box.
      expect(find.text('Basilic vivant'), findsOneWidget);
      expect(find.text('Basilic en attente'), findsOneWidget);
      expect(find.text('Basilic mort'), findsNothing);
      expect(find.text(SeedLibraryTextConstants.deathDate), findsNothing);
      expect(find.text(SeedLibraryTextConstants.plantingDate), findsOneWidget);
      // The maturation countdown row (40 days from a January planting →
      // negative → red; the row exists either way).
      expect(
        find.textContaining(SeedLibraryTextConstants.timeUntilMaturation),
        findsOneWidget,
      );
      expect(find.textContaining(SeedLibraryTextConstants.days), findsWidgets);
      expect(tester.takeException(), isNull);

      // Reveal the dead plant: the consumed branch of PersonalPlantCard.
      await tester.tap(find.byType(Checkbox));
      await settle(tester);
      expect(find.text('Basilic mort'), findsOneWidget);
      expect(find.text(SeedLibraryTextConstants.deathDate), findsOneWidget);

      // Search with no match reaches the filtered-empty message (the
      // unfiltered list is not empty, so it is the second branch).
      await tester.enterText(find.byType(TextField).first, 'zzz-rien');
      await settle(tester);
      expect(
        find.text(SeedLibraryTextConstants.noFilteredPlants),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField).first, '');
      await settle(tester);
      expect(
        find.text(SeedLibraryTextConstants.noFilteredPlants),
        findsNothing,
      );

      // Into the editable plant detail (the /plants child route — a
      // different page from the stock borrow detail).
      await tester.ensureVisible(find.text('Basilic vivant'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Basilic vivant'));
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await settle(tester, frames: 10);

      verify(
        () =>
            scaffold.repository.seedLibraryPlantsPlantIdGet(plantId: 'p-alive'),
      ).called(1);
      expect(find.text(SeedLibraryTextConstants.plantingNow), findsOneWidget);
      expect(find.text('Basilic vivant'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  // NOTE: the FiltersBar interaction session moved to
  // my_plants_filters_integration_test.dart (convention 19: one
  // router-pushing test per file).

  testWidgets('an empty my-plants list shows the no-plants message', (
    tester,
  ) async {
    stubPlants(scaffold, mine: []);
    await pumpMyPlants(tester);

    expect(
      find.text(SeedLibraryTextConstants.noPersonalPlants),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the species help button launches, dead-plant flow fails', (
    tester,
  ) async {
    final fake = FakeUrlLauncher(launchSucceeds: true);
    stubUrlLauncher(fake);
    stubPlants(scaffold, mine: [alivePlant]);
    when(
      () => scaffold.repository.seedLibraryPlantsPlantIdPatch(
        plantId: any(named: 'plantId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<void>(http.Response('err', 400), null),
    );

    final container = scaffold.makeContainer();
    scaffold.setWideSurface(tester);
    // Deep direct link into the editable detail; the page reads
    // plantProvider, which nothing here loads, so set it after the pump.
    container.read(syncSpeciesListProvider);
    container.read(speciesTypeListProvider);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/seed_library/plants/plant_detail',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    container
        .read(plantProvider.notifier)
        .setPlant(
          detailPlant(
            state: PlantState.rCupRE,
            plantingDate: DateTime(2026, 2, 1),
          ),
        );
    await settle(tester, frames: 10);
    addTearDown(container.dispose);

    // Species-help (card != null) — the branch the stock detail shares but
    // only reachable here through the editable page's own button.
    final help = find.text(SeedLibraryTextConstants.speciesHelp);
    expect(help, findsOneWidget);
    await tester.ensureVisible(help);
    await settle(tester, frames: 2);
    await tester.tap(help);
    await settle(tester);
    expect(fake.launched, ['https://fiche.example/help']);

    // Failed death PATCH: dialog → Confirm → 400 → error toast and the
    // date label still says planting, not death.
    final death = find.text(SeedLibraryTextConstants.deadPlant);
    await tester.ensureVisible(death);
    await settle(tester, frames: 2);
    await tester.tap(death);
    await settle(tester, frames: 6);
    expect(find.text(SeedLibraryTextConstants.deadMsg), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 12);
    expect(find.text(SeedLibraryTextConstants.updatingError), findsOneWidget);
    expect(find.text(SeedLibraryTextConstants.deathDate), findsNothing);
    expect(tester.takeException(), isNull);
    await scaffold.drainToast(tester);
  });
}
