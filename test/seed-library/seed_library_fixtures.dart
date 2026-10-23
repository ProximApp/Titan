import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../shared/app_scaffold.dart';

/// The admin user the seed-library shells mount as: `user-1` carrying the
/// admin_seed_library group (the group id and the build live here).
const seedLibraryAdminGroupId = '09153d2a-14f4-49a4-be57-5d0f265261b9';

/// Build a seed-library administrator with the module-admin group.
CoreUser seedLibraryAdminUserFixture({String id = 'user-1'}) =>
    CoreUser.empty().copyWith(
      id: id,
      groups: [
        CoreGroupSimple.empty().copyWith(
          id: seedLibraryAdminGroupId,
          name: 'admin_seed_library',
        ),
      ],
    );

final seedLibraryAdminUser = seedLibraryAdminUserFixture();

/// Stubs the five read endpoints every seed-library page fans out to on
/// mount: the information banner, my plants, the waiting/stock list, the
/// species list and the species-type dropdown catalog. Every shell file
/// used to rebuild this block by hand.
///
/// [speciesTypes] defaults to every type EXCEPT plantesAromatiques — the
/// shape the dropdown expects (the widget prepends that one itself, so a
/// server list carrying it trips the DropdownButton value assertion).
void stubSeedLibrary(
  IntegrationScaffold scaffold, {
  SeedLibraryInformation? information,
  List<SpeciesComplete> species = const [],
  List<PlantSimple> mine = const [],
  List<PlantSimple> waiting = const [],
  List<SpeciesType>? speciesTypes,
}) {
  when(() => scaffold.repository.seedLibraryInformationGet()).thenAnswer(
    (_) async => chopperResponse(information ?? SeedLibraryInformation.empty()),
  );
  when(() => scaffold.repository.seedLibraryPlantsUsersMeGet())
      .thenAnswer((_) async => chopperListResponse(mine));
  when(() => scaffold.repository.seedLibraryPlantsWaitingGet())
      .thenAnswer((_) async => chopperListResponse(waiting));
  when(() => scaffold.repository.seedLibrarySpeciesGet())
      .thenAnswer((_) async => chopperListResponse(species));
  when(() => scaffold.repository.seedLibrarySpeciesTypesGet()).thenAnswer(
    (_) async => chopperResponse(
      SpeciesTypesReturn(
        speciesType:
            speciesTypes ??
            SpeciesType.values
                .where((t) => t != SpeciesType.plantesAromatiques)
                .toList(),
      ),
    ),
  );
}

/// The three my-plants card states the my-plants shells render: one alive
/// and planted, one dead behind its checkbox, one still waiting.
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

/// Tap targets on the species pages and menu: the icon the button carries.
Finder pencil() =>
    find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.pencil);
Finder trash() =>
    find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.trash);
Finder plusCard() =>
    find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus);

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
