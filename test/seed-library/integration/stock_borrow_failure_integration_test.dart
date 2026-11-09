import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/seed-library/providers/species_list_provider.dart';
import 'package:titan/seed-library/providers/species_type_list_provider.dart';
import 'package:titan/seed-library/tools/constants.dart';

import '../../shared/app_scaffold.dart';
import '../seed_library_fixtures.dart';

/// `plant_detail_page.dart:172` is the borrow button's failure toast: when
/// the PATCH does not go through, the page has to say so instead of showing
/// the "borrowed" message. The happy path lives in
/// `stock_borrow_integration_test.dart`, which cannot carry the failure case
/// too — qlevar honours only the first mid-test navigation in an isolate, so
/// the second detail visit has to be this file's first.
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
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('a refused borrow reports the error instead of the receipt', (
    tester,
  ) async {
    stubSeedLibrary(scaffold, species: [species], waiting: [stockPlant]);
    when(
      () => scaffold.repository.seedLibraryPlantsPlantIdGet(
        plantId: any(named: 'plantId'),
      ),
    ).thenAnswer((_) async => chopperResponse(detailPlant));
    when(
      () => scaffold.repository.seedLibraryPlantsPlantIdBorrowPatch(
        plantId: any(named: 'plantId'),
      ),
    ).thenAnswer((_) async => scaffold.repository.fail<void>(500));

    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    // Both lists are primed before the first frame: the detail page's own
    // lookups are bare firstWhere calls.
    container.read(syncSpeciesListProvider);
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

    await tester.ensureVisible(find.text('Basilic du pot'));
    await settle(tester, frames: 2);
    await tester.tap(find.text('Basilic du pot'));
    await settle(tester, frames: 10);

    await tester.ensureVisible(find.text(SeedLibraryTextConstants.borrowPlant));
    await settle(tester, frames: 2);
    await tester.tap(find.text(SeedLibraryTextConstants.borrowPlant));
    await settle(tester, frames: 10);

    verify(
      () => scaffold.repository.seedLibraryPlantsPlantIdBorrowPatch(
        plantId: 'w-1',
      ),
    ).called(1);
    expect(find.text(SeedLibraryTextConstants.addingError), findsOneWidget);
    expect(find.text(SeedLibraryTextConstants.borrowedPlant), findsNothing);
    await scaffold.drainToast(tester);
    expect(tester.takeException(), isNull);
  });
}
