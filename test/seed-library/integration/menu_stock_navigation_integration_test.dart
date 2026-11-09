import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/seed-library/providers/species_type_list_provider.dart';
import 'package:titan/seed-library/tools/constants.dart';

import '../../shared/app_scaffold.dart';
import '../seed_library_fixtures.dart';

/// The stock card on the root menu lands on the stocks page (empty branch),
/// and pulling it reloads the waiting plant list.
/// One test per file: qlevar keeps the active route branch in
/// process-global state, so a second router-driven test here would render
/// this session's page instead of its own (convention 19).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the stock card lands on the empty stocks page', (tester) async {
    final container = scaffold.makeContainer(user: seedLibraryAdminUser);
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);

    stubSeedLibrary(scaffold);

    container.read(speciesTypeListProvider);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/seed_library',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 10);

    await revealMenu(tester, menuCard(SeedLibraryTextConstants.stock));
    await tester.tap(menuCard(SeedLibraryTextConstants.stock));
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 10);

    expect(find.text(SeedLibraryTextConstants.stocks), findsOneWidget);
    expect(find.text(SeedLibraryTextConstants.noStockPlants), findsOneWidget);

    // The page's pull-to-refresh (`stocks_page.dart:27-28`) reloads the
    // waiting plant list. Slow, stepped drag: see the species file.
    clearInteractions(scaffold.repository);
    await pullToRefresh(tester);
    verify(() => scaffold.repository.seedLibraryPlantsWaitingGet()).called(1);
    expect(tester.takeException(), isNull);
  });
}
