import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/seed-library/providers/species_type_list_provider.dart';
import 'package:titan/seed-library/tools/constants.dart';

import '../../shared/app_scaffold.dart';

/// My-plants FiltersBar interactions as their own router-pushing session
/// (convention 19 — qlevar's process-global route branch would render
/// another test's leftover page otherwise): expand the bar, sweep season,
/// species type and the difficulty slider across empty/non-empty states.
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

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the filters bar season/type/slide reshape the list', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    when(
      () => scaffold.repository.seedLibraryInformationGet(),
    ).thenAnswer((_) async => chopperResponse(SeedLibraryInformation.empty()));
    when(
      () => scaffold.repository.seedLibrarySpeciesGet(),
    ).thenAnswer((_) async => chopperListResponse([species]));
    when(
      () => scaffold.repository.seedLibraryPlantsWaitingGet(),
    ).thenAnswer((_) async => chopperListResponse(<PlantSimple>[]));
    when(() => scaffold.repository.seedLibraryPlantsUsersMeGet()).thenAnswer(
      (_) async => chopperListResponse([alivePlant, deadPlant, waitingPlant]),
    );
    when(() => scaffold.repository.seedLibrarySpeciesTypesGet()).thenAnswer(
      (_) async => chopperResponse(
        SpeciesTypesReturn(
          speciesType: SpeciesType.values
              .where((t) => t != SpeciesType.plantesAromatiques)
              .toList(),
        ),
      ),
    );

    // Pre-warm before the first frame: FiltersBar builds its expanded
    // children during the first build and the SpeciesType dropdown asserts
    // on an empty item list.
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

    expect(find.text('Basilic vivant'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // FiltersBar mounts collapsed behind its "Filtres" header — expand it.
    await tester.tap(find.text(SeedLibraryTextConstants.filters));
    await settle(tester);

    // Season: Été hides the April-start species → filtered empty.
    await tester.tap(find.byType(DropdownButton<String>).first);
    await settle(tester);
    await tester.tap(find.text(SeedLibraryTextConstants.summer));
    await settle(tester);
    expect(
      find.text(SeedLibraryTextConstants.noFilteredPlants),
      findsOneWidget,
    );
    await tester.tap(find.byType(DropdownButton<String>).first);
    await settle(tester);
    await tester.tap(find.text(SeedLibraryTextConstants.all));
    await settle(tester);
    expect(find.text('Basilic vivant'), findsOneWidget);

    // Type: the aromatiques species drops out under potagères…
    await tester.tap(find.byType(DropdownButton<SpeciesType>).first);
    await settle(tester);
    await tester.tap(find.text(SpeciesType.plantesPotagRes.name));
    await settle(tester);
    expect(
      find.text(SeedLibraryTextConstants.noFilteredPlants),
      findsOneWidget,
    );
    // …and returns.
    await tester.tap(find.byType(DropdownButton<SpeciesType>).first);
    await settle(tester);
    await tester.tap(find.text(SpeciesType.plantesAromatiques.name));
    await settle(tester);
    expect(find.text('Basilic vivant'), findsOneWidget);

    // Difficulty slider both ways (0 → 5 → 0).
    await tester.drag(find.byType(Slider), const Offset(1200, 0));
    await settle(tester);
    expect(
      find.text(SeedLibraryTextConstants.noFilteredPlants),
      findsOneWidget,
    );
    await tester.drag(find.byType(Slider), const Offset(-1200, 0));
    await settle(tester);
    expect(find.text('Basilic vivant'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
