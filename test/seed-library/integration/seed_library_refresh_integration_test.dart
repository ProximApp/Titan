import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/seed-library/providers/species_type_list_provider.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../../shared/app_scaffold.dart';
import '../seed_library_fixtures.dart';

final refreshSpecies = SpeciesComplete.empty().copyWith(
  id: 'sp-1',
  prefix: 'BAS',
  name: 'Basilic',
);

final refreshPlant = PlantSimple.empty().copyWith(
  id: 'w-1',
  reference: 'BAS-0100',
  speciesId: 'sp-1',
);

/// The plants page's pull-to-refresh: it re-runs its loader, so the test
/// counts the requests the loader makes instead of trusting that the callback
/// is wired to something.
///
/// FiltersBar is expanded on mount and its species-type dropdown asserts on an
/// empty item list, so the provider is warmed before the first frame — the
/// same pre-warm the my-plants suite needs.
///
/// NOTE: the species and stock pages' identical `onRefresh` arms stay
/// uncovered. Neither page renders its Refresher under this harness: pumped at
/// `/seed_library/species` and `/seed_library/stock` (as admin, since both sit
/// behind the seed-library admin gate, and with their own endpoints stubbed)
/// their subtrees never mount, so the callback cannot be reached from a test
/// without inventing a page that is not the real one.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pumpPage(WidgetTester tester, String path) async {
    // The species and stock pages sit behind the seed-library admin gate; as a
    // plain user they redirect to /feed and nothing of theirs is built.
    final container = scaffold.makeContainer(user: seedLibraryAdminUser);
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    container.read(speciesTypeListProvider);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: path,
      pumpAndSettle: false,
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 10);
  }

  Future<void> pullToRefresh(WidgetTester tester) async {
    final refresher = tester.widget<Refresher>(find.byType(Refresher).first);
    await tester.runAsync(() async {
      await refresher.onRefresh();
    });
    await settle(tester, frames: 10);
  }

  testWidgets('the plants page refetches the waiting plants', (tester) async {
    var requests = 0;
    stubSeedLibrary(scaffold, species: [refreshSpecies]);
    when(() => scaffold.repository.seedLibraryPlantsWaitingGet())
        .thenAnswer((_) async {
          requests++;
          return chopperListResponse([refreshPlant]);
        });

    await pumpPage(tester, '/seed_library/plants');
    final before = requests;

    await pullToRefresh(tester);

    expect(requests, before + 1);
    expect(tester.takeException(), isNull);
    await scaffold.unmountApp(tester);
  });
}
