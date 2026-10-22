import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/seed-library/tools/constants.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The species MANAGEMENT list: the SpeciesPage itself (the plus-card
/// handler, the per-card edit/delete closures, both toast arms of the
/// deletion) and the SpeciesCard's pencil/trash buttons in their dialog
/// flow. ONE test per file: the edit and create FORMS push deeper routes
/// and live in their own files (convention 19 — qlevar keeps the active
/// route branch in process-global state, so a second router-driven test
/// here would render this session's page instead of its own).
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

SpeciesComplete species({
  String id = 'sp-1',
  String name = 'Basilic',
  String prefix = 'BAS',
}) => SpeciesComplete.empty().copyWith(
  id: id,
  name: name,
  prefix: prefix,
  difficulty: 3,
  speciesType: SpeciesType.plantesAromatiques,
  startSeason: DateTime(2026, 4, 1),
  timeMaturation: 40,
  nbSeedsRecommended: 100,
  card: 'https://fiche.example/help',
);

Finder pencil() =>
    find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.pencil);
Finder trash() =>
    find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.trash);
Finder plusCard() =>
    find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  void stubSpeciesPage(
    IntegrationScaffold scaffold,
    List<SpeciesComplete> list,
  ) {
    when(
      () => scaffold.repository.seedLibraryInformationGet(),
    ).thenAnswer((_) async => chopperResponse(SeedLibraryInformation.empty()));
    when(() => scaffold.repository.seedLibraryPlantsUsersMeGet())
        .thenAnswer((_) async => chopperListResponse(<PlantSimple>[]));
    when(() => scaffold.repository.seedLibraryPlantsWaitingGet())
        .thenAnswer((_) async => chopperListResponse(<PlantSimple>[]));
    when(() => scaffold.repository.seedLibrarySpeciesGet())
        .thenAnswer((_) async => chopperListResponse(list));
    when(() => scaffold.repository.seedLibrarySpeciesTypesGet()).thenAnswer(
      (_) async => chopperResponse(
        SpeciesTypesReturn(
          speciesType: SpeciesType.values
              .where((t) => t != SpeciesType.plantesAromatiques)
              .toList(),
        ),
      ),
    );
  }

  Future<ProviderContainer> pumpSpecies(WidgetTester tester) async {
    final container = scaffold.makeContainer(user: adminUser);
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/seed_library/species',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 10);
    return container;
  }

  // FIRST (and only) navigation of the file: the species admin page itself.
  testWidgets('deleting a species confirms, and both outcomes toast', (
    tester,
  ) async {
    stubSpeciesPage(scaffold, [
      species(),
      species(id: 'sp-2', name: 'Tomate', prefix: 'TOM'),
    ]);
    when(
      () => scaffold.repository.seedLibrarySpeciesSpeciesIdDelete(
        speciesId: any(named: 'speciesId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<void>(http.Response('err', 400), null),
    );

    await pumpSpecies(tester);

    expect(find.text(SeedLibraryTextConstants.speciesPlural), findsOneWidget);
    expect(find.text('Basilic'), findsOneWidget);
    expect(find.text('Tomate'), findsOneWidget);
    expect(pencil(), findsNWidgets(2));
    expect(trash(), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(trash().first);
    await settle(tester, frames: 2);
    // Failure arm first: dialog → Confirm → 400 → error toast, card stays.
    await tester.tap(trash().first);
    await settle(tester, frames: 4);
    expect(find.text(SeedLibraryTextConstants.deleting), findsOneWidget);
    expect(find.text(SeedLibraryTextConstants.deleteSpecies), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 10);
    expect(find.text(SeedLibraryTextConstants.deletingError), findsOneWidget);
    verify(
      () => scaffold.repository.seedLibrarySpeciesSpeciesIdDelete(
        speciesId: 'sp-1',
      ),
    ).called(1);
    await scaffold.drainToast(tester);
    expect(find.text('Basilic'), findsOneWidget);

    // Success arm: 200 → toast, the card leaves the list.
    when(
      () => scaffold.repository.seedLibrarySpeciesSpeciesIdDelete(
        speciesId: any(named: 'speciesId'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    await tester.ensureVisible(trash().first);
    await settle(tester, frames: 2);
    await tester.tap(trash().first);
    await settle(tester, frames: 4);
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 10);

    verify(
      () => scaffold.repository.seedLibrarySpeciesSpeciesIdDelete(
        speciesId: 'sp-1',
      ),
    ).called(1);
    expect(find.text(SeedLibraryTextConstants.deletedSpecies), findsOneWidget);
    await scaffold.drainToast(tester);
    expect(find.text('Basilic'), findsNothing);
    expect(find.text('Tomate'), findsOneWidget);
    expect(trash(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
