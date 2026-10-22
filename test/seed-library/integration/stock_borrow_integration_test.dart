import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/seed-library/providers/species_list_provider.dart';
import 'package:titan/seed-library/providers/species_type_list_provider.dart';
import 'package:titan/seed-library/tools/constants.dart';

import '../../shared/app_scaffold.dart';

/// The STOCK half of seed-library: `/seed_library/stock` (stocks_page, its
/// PlantCard, the research/filters bar) and its child
/// `/seed_library/stock/plant_detail` — the borrow-only PlantDetailPage,
/// 82 lines that no other test reaches (the plants route renders the
/// *editable* detail page instead, a different widget).
///
/// Strings are the French constants, quoted through the constants class
/// where they are long or dynamic.
final species = SpeciesComplete.empty().copyWith(
  id: 'sp-1',
  prefix: 'BAS',
  name: 'Basilic',
  difficulty: 3,
  speciesType: SpeciesType.plantesAromatiques,
  startSeason: DateTime(2026, 4, 1),
  endSeason: DateTime(2026, 9, 30),
  timeMaturation: 40,
  card: 'https://fiche.example/help',
);

final stockPlant = PlantSimple.empty().copyWith(
  id: 'w-1',
  reference: 'BAS-0100',
  nickname: 'Basilic du pot',
  speciesId: 'sp-1',
  state: PlantState.enAttente,
  propagationMethod: PropagationMethod.graine,
  nbSeedsEnvelope: 12,
);

final detailPlant = PlantComplete.empty().copyWith(
  id: 'w-1',
  reference: 'BAS-0100',
  nickname: 'Basilic du pot',
  speciesId: 'sp-1',
  state: PlantState.enAttente,
  propagationMethod: PropagationMethod.graine,
  nbSeedsEnvelope: 25,
  borrowingDate: DateTime(2026, 1, 5),
  previousNote: 'Arroser matin et soir',
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  void stubStock(IntegrationScaffold scaffold) {
    when(
      () => scaffold.repository.seedLibraryInformationGet(),
    ).thenAnswer((_) async => chopperResponse(SeedLibraryInformation.empty()));
    when(() => scaffold.repository.seedLibraryPlantsUsersMeGet())
        .thenAnswer((_) async => chopperListResponse(<PlantSimple>[]));
    when(() => scaffold.repository.seedLibrarySpeciesGet())
        .thenAnswer((_) async => chopperListResponse([species]));
    when(() => scaffold.repository.seedLibraryPlantsWaitingGet())
        .thenAnswer((_) async => chopperListResponse([stockPlant]));
    // The species-type dropdown prepends plantesAromatiques, so the server
    // list must carry every OTHER type (incl. the default filter `autre`)
    // or the DropdownButton value assertion fires.
    when(() => scaffold.repository.seedLibrarySpeciesTypesGet()).thenAnswer(
      (_) async => chopperResponse(
        SpeciesTypesReturn(
          speciesType: SpeciesType.values
              .where((t) => t != SpeciesType.plantesAromatiques)
              .toList(),
        ),
      ),
    );
    when(
      () => scaffold.repository.seedLibraryPlantsPlantIdGet(
        plantId: any(named: 'plantId'),
      ),
    ).thenAnswer((_) async => chopperResponse(detailPlant));
  }

  testWidgets('the stock list filters, then a card opens the borrow detail', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubStock(scaffold);
    final fake = FakeUrlLauncher(launchSucceeds: true);
    stubUrlLauncher(fake);
    when(
      () => scaffold.repository.seedLibraryPlantsPlantIdBorrowPatch(
        plantId: any(named: 'plantId'),
      ),
    ).thenAnswer((_) async => chopperResponse(detailPlant));
    // Pre-warm the species list before the first frame (ledger #26): the
    // detail page does a bare firstWhere and crashes on an empty list.
    container.read(syncSpeciesListProvider);
    // …and the species TYPE list: FiltersBar is expanded on mount and its
    // SpeciesType dropdown asserts if the default value is built against
    // an empty item list.
    container.read(speciesTypeListProvider);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/seed_library/stock',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 10);

    // --- stocks page
    expect(find.text(SeedLibraryTextConstants.stocks), findsOneWidget);
    expect(find.text('Basilic'), findsWidgets);
    expect(find.text('Basilic du pot'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Icon && w.icon == Icons.star),
      findsNWidgets(3),
    );
    expect(tester.takeException(), isNull);

    // ResearchBar: a non-matching search empties the (non-empty) list.
    await tester.enterText(find.byType(TextField).first, 'zzz-rien');
    await settle(tester);
    expect(find.text(SeedLibraryTextConstants.noStockPlants), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '');
    await settle(tester);
    expect(find.text(SeedLibraryTextConstants.noStockPlants), findsNothing);

    // FiltersBar mounts collapsed behind its "Filtres" header — expand it.
    // Season: the plant's species starts in April, so Été
    // (Jul-Sep) hides it and "Toutes" brings it back.
    await tester.tap(find.text(SeedLibraryTextConstants.filters));
    await settle(tester);
    await tester.tap(find.byType(DropdownButton<String>).first);
    await settle(tester);
    await tester.tap(find.text(SeedLibraryTextConstants.summer));
    await settle(tester);
    expect(find.text(SeedLibraryTextConstants.noStockPlants), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<String>).first);
    await settle(tester);
    await tester.tap(find.text(SeedLibraryTextConstants.all));
    await settle(tester);
    expect(find.text(SeedLibraryTextConstants.noStockPlants), findsNothing);

    // Difficulty slider: sweep to 5 (species is 3 → empty) and back to 0.
    await tester.drag(find.byType(Slider), const Offset(1200, 0));
    await settle(tester);
    expect(find.text(SeedLibraryTextConstants.noStockPlants), findsOneWidget);
    await tester.drag(find.byType(Slider), const Offset(-1200, 0));
    await settle(tester);
    expect(find.text(SeedLibraryTextConstants.noStockPlants), findsNothing);

    // --- into the borrow-only detail
    await tester.ensureVisible(find.text('Basilic du pot'));
    await settle(tester, frames: 2);
    await tester.tap(find.text('Basilic du pot'));
    await settle(tester);

    verify(
      () => scaffold.repository.seedLibraryPlantsPlantIdGet(plantId: 'w-1'),
    ).called(1);
    expect(find.text(SeedLibraryTextConstants.plantDetail), findsOneWidget);
    expect(find.text('Référence : BAS-0100'), findsOneWidget);
    expect(find.text('Espèce : Basilic'), findsOneWidget);
    expect(find.text('Type : plantesAromatiques'), findsOneWidget);
    expect(find.text(SeedLibraryTextConstants.difficulty), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Icon && w.icon == Icons.star),
      findsNWidgets(3),
    );
    expect(
      find.textContaining(SeedLibraryTextConstants.plantationPeriod),
      findsOneWidget,
    );
    expect(
      find.textContaining(SeedLibraryTextConstants.timeUntilMaturation),
      findsOneWidget,
    );
    expect(find.text(SeedLibraryTextConstants.speciesHelp), findsOneWidget);
    expect(
      find.textContaining(
        '${SeedLibraryTextConstants.propagationMethod} graine',
      ),
      findsOneWidget,
    );
    // graine propagation shows the seed count…
    expect(
      find.text('${SeedLibraryTextConstants.seedQuantity} 25'),
      findsOneWidget,
    );
    // …and a non-empty previousNote shows the notes block.
    expect(find.text(SeedLibraryTextConstants.notes), findsOneWidget);
    expect(find.text('Arroser matin et soir'), findsOneWidget);
    expect(find.text(SeedLibraryTextConstants.borrowPlant), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Species-help button → openLink reaches the platform.
    await tester.ensureVisible(find.text(SeedLibraryTextConstants.speciesHelp));
    await settle(tester, frames: 2);
    await tester.tap(find.text(SeedLibraryTextConstants.speciesHelp));
    await settle(tester);
    expect(fake.launched, ['https://fiche.example/help']);

    // Borrow: PATCH, toast, list surgery, QR.back to the stock page.
    await tester.ensureVisible(find.text(SeedLibraryTextConstants.borrowPlant));
    await settle(tester, frames: 2);
    await tester.tap(find.text(SeedLibraryTextConstants.borrowPlant));
    await settle(tester, frames: 10);

    verify(
      () => scaffold.repository.seedLibraryPlantsPlantIdBorrowPatch(
        plantId: 'w-1',
      ),
    ).called(1);
    expect(find.text(SeedLibraryTextConstants.borrowedPlant), findsOneWidget);
    await scaffold.drainToast(tester);
    // QR.back() landed on the stock page again.
    expect(find.text(SeedLibraryTextConstants.plantDetail), findsNothing);
    expect(find.text(SeedLibraryTextConstants.stocks), findsOneWidget);
  });
}
