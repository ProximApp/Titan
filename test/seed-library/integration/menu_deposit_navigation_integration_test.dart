import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/seed-library/providers/species_type_list_provider.dart';
import 'package:titan/seed-library/tools/constants.dart';

import '../../shared/app_scaffold.dart';

/// The deposit card on the root menu lands on the plant deposit page.
/// One test per file: qlevar keeps the active route branch in
/// process-global state, so a second router-driven test here would render
/// this session's page instead of its own (convention 19).
const seedLibraryAdminGroupId = '09153d2a-14f4-49a4-be57-5d0f265261b9';

final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [
    CoreGroupSimple.empty().copyWith(
      name: 'admin_seed_library',
      id: seedLibraryAdminGroupId,
    ),
  ],
);

/// Tap target for a menu card: its label; the GestureDetector ancestor
/// handles the hit.
Finder menuCard(String text) => find.text(text);

/// Scroll the sliver GridView until the label materialises, then bring it
/// into the viewport.
Future<void> revealMenu(WidgetTester tester, Finder label) async {
  for (var i = 0; i < 8 && tester.elementList(label).isEmpty; i++) {
    await tester.drag(find.byType(GridView).first, const Offset(0, -260));
    await tester.pump(const Duration(milliseconds: 120));
  }
  if (tester.elementList(label).isNotEmpty) {
    await tester.ensureVisible(label);
    await settle(tester, frames: 2);
  }
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the deposit card lands on the deposit page', (tester) async {
    final container = scaffold.makeContainer(user: adminUser);
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);

    when(
      () => scaffold.repository.seedLibraryInformationGet(),
    ).thenAnswer((_) async => chopperResponse(SeedLibraryInformation.empty()));
    when(
      () => scaffold.repository.seedLibraryPlantsUsersMeGet(),
    ).thenAnswer((_) async => chopperListResponse(<PlantSimple>[]));
    when(
      () => scaffold.repository.seedLibraryPlantsWaitingGet(),
    ).thenAnswer((_) async => chopperListResponse(<PlantSimple>[]));
    when(
      () => scaffold.repository.seedLibrarySpeciesGet(),
    ).thenAnswer((_) async => chopperListResponse(<SpeciesComplete>[]));
    when(() => scaffold.repository.seedLibrarySpeciesTypesGet()).thenAnswer(
      (_) async => chopperResponse(
        SpeciesTypesReturn(
          speciesType: SpeciesType.values
              .where((t) => t != SpeciesType.plantesAromatiques)
              .toList(),
        ),
      ),
    );

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
