import 'package:flutter_test/flutter_test.dart';
import 'package:titan/seed-library/providers/species_type_list_provider.dart';
import 'package:titan/seed-library/tools/constants.dart';

import '../../shared/app_scaffold.dart';
import '../seed_library_fixtures.dart';

/// The deposit card on the root menu lands on the plant deposit page.
/// One test per file: qlevar keeps the active route branch in
/// process-global state, so a second router-driven test here would render
/// this session's page instead of its own (convention 19).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the deposit card lands on the deposit page', (tester) async {
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

    await revealMenu(tester, menuCard(SeedLibraryTextConstants.seedDeposit));
    await tester.tap(menuCard(SeedLibraryTextConstants.seedDeposit));
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 10);

    expect(find.text('Déposer une plante'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
