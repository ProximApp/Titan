import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/seed-library/tools/constants.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The species EDIT form: pencil → prefilled add-edit page, end-month
/// selection (the update branch's DateTime(2021, …) arms), the success
/// toast + QR.back, and the 400 failure arm that stays on the form.
/// One test per file (convention 19 — qlevar's process-global route branch
/// would render this session's page for any later router-driven test).
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

SpeciesComplete species() => SpeciesComplete.empty().copyWith(
  id: 'sp-1',
  name: 'Basilic',
  prefix: 'BAS',
  difficulty: 3,
  speciesType: SpeciesType.plantesAromatiques,
  startSeason: DateTime(2026, 4, 1),
  timeMaturation: 40,
  nbSeedsRecommended: 100,
  card: 'https://fiche.example/help',
);

Finder pencil() =>
    find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.pencil);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the pencil opens the prefilled form and PATCHes, then fails', (
    tester,
  ) async {
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
    ).thenAnswer((_) async => chopperListResponse([species()]));
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
      () => scaffold.repository.seedLibrarySpeciesSpeciesIdPatch(
        speciesId: any(named: 'speciesId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

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

    await tester.ensureVisible(pencil());
    await settle(tester, frames: 2);
    await tester.tap(pencil());
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 10);

    // Prefilled edit form with the month buttons seeded from startSeason.
    expect(find.text(SeedLibraryTextConstants.editSpecies), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Basilic'), findsOneWidget);
    expect(find.text('Avril'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Edit name, set the end month (covers the DateTime(2021, …) arms of
    // the UPDATE branch the create-only test never reaches).
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Basilic'),
      'Basilic genovese',
    );
    final monthDropdowns = find.byType(DropdownButton<String>);
    expect(monthDropdowns, findsNWidgets(2));
    await tester.ensureVisible(monthDropdowns.last);
    await settle(tester, frames: 2);
    await tester.tap(monthDropdowns.last);
    await settle(tester, frames: 4);
    await tester.tap(find.text('Septembre'));
    await settle(tester, frames: 4);

    await scaffold.unfocus(tester);
    await tester.ensureVisible(find.text(SeedLibraryTextConstants.update));
    await settle(tester, frames: 2);
    await tester.tap(find.text(SeedLibraryTextConstants.update));
    await settle(tester, frames: 12);

    verify(
      () => scaffold.repository.seedLibrarySpeciesSpeciesIdPatch(
        speciesId: 'sp-1',
        body: any(named: 'body'),
      ),
    ).called(1);
    expect(find.text(SeedLibraryTextConstants.updatedSpecies), findsOneWidget);
    await scaffold.drainToast(tester);
    // QR.back() → the list now carries the new name.
    expect(find.text(SeedLibraryTextConstants.speciesPlural), findsOneWidget);
    expect(find.text('Basilic genovese'), findsOneWidget);

    // Failure arm: 400 keeps the form up with an error toast.
    when(
      () => scaffold.repository.seedLibrarySpeciesSpeciesIdPatch(
        speciesId: any(named: 'speciesId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<void>(http.Response('err', 400), null),
    );
    await tester.ensureVisible(pencil());
    await settle(tester, frames: 2);
    await tester.tap(pencil());
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 10);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Basilic genovese'),
      'Basilic',
    );
    await scaffold.unfocus(tester);
    await tester.ensureVisible(find.text(SeedLibraryTextConstants.update));
    await settle(tester, frames: 2);
    await tester.tap(find.text(SeedLibraryTextConstants.update));
    await settle(tester, frames: 12);
    expect(find.text(SeedLibraryTextConstants.updatingError), findsOneWidget);
    await scaffold.drainToast(tester);
    expect(find.text(SeedLibraryTextConstants.editSpecies), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
