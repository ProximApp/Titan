import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/seed-library/providers/difficulty_filter_provider.dart';
import 'package:titan/seed-library/tools/constants.dart';

import '../../shared/app_scaffold.dart';

/// The species add-edit form (`/seed_library/species/add_edit_species`,
/// 132 uncovered lines): its validators (3-char unique prefix, integer
/// seed count), the type and difficulty gates, and the create POST
/// round-trip.
///
/// Own file for the deep-link rule; the admin gate uses the real
/// admin_seed_library group id. The UI strings are French constants, so
/// assertions quote them verbatim.
final adminUser = models.CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [
    models.CoreGroupSimple.empty().copyWith(
      name: 'admin_seed_library',
      id: '09153d2a-14f4-49a4-be57-5d0f265261b9',
    ),
  ],
);

models.SpeciesComplete species() => models.SpeciesComplete.empty().copyWith(
  id: 'sp-1',
  name: 'Basilic',
  prefix: 'BAS',
  difficulty: 2,
);

void stubSpeciesData(IntegrationScaffold scaffold) {
  when(
    () => scaffold.repository.seedLibrarySpeciesGet(),
  ).thenAnswer((_) async => chopperListResponse([species()]));
  when(() => scaffold.repository.seedLibrarySpeciesTypesGet()).thenAnswer(
    (_) async => chopperResponse(
      SpeciesTypesReturn(
        speciesType: [
          SpeciesType.plantesAromatiques,
          SpeciesType.plantesPotagRes,
        ],
      ),
    ),
  );
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pumpAddSpecies(WidgetTester tester) async {
    stubSpeciesData(scaffold);
    scaffold.setWideSurface(tester);
    final container = scaffold.makeContainer(user: adminUser);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/seed_library/species/add_edit_species',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<void> pumpFrames(WidgetTester tester, [int frames = 16]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('the add form renders with types bar and fields', (tester) async {
    await pumpAddSpecies(tester);

    expect(QR.currentPath, '/seed_library/species/add_edit_species');
    expect(find.text(SeedLibraryTextConstants.addSpecies), findsOneWidget);
    expect(find.text(SeedLibraryTextConstants.name), findsOneWidget);
    expect(find.text(SeedLibraryTextConstants.prefix), findsOneWidget);
    expect(find.text(SeedLibraryTextConstants.difficulty), findsOneWidget);
    // canBeEmpty fields render their label with the (Optional) suffix.
    expect(find.text('Carte (Optional)'), findsOneWidget);
    expect(
      find.text('Nombre de graines recommandées (Optional)'),
      findsOneWidget,
    );
    expect(find.text('Temps de maturation (Optional)'), findsOneWidget);
    // The type chips render from the types endpoint — the RAW Dart enum
    // names, not the JSON labels (cosmetic quirk, asserted as rendered).
    expect(find.text('plantesAromatiques'), findsOneWidget);
    expect(find.text('plantesPotagRes'), findsOneWidget);
    // Empty species: submit reads Ajouter.
    expect(find.text(SeedLibraryTextConstants.add), findsOneWidget);
  });

  testWidgets('validation refuses an empty name and a malformed prefix', (
    tester,
  ) async {
    await pumpAddSpecies(tester);
    final fields = find.byType(TextFormField);

    // Empty required name: the form validator fails and the error toast
    // shows.
    await tester.tap(find.text(SeedLibraryTextConstants.add));
    await pumpFrames(tester);
    expect(find.text(SeedLibraryTextConstants.emptyFieldError), findsOneWidget);
    await scaffold.drainToast(tester);

    // Prefix of the wrong shape: inline field error, submit still refused.
    await tester.enterText(fields.first, 'Tomate');
    await tester.enterText(fields.at(1), 'TO');
    await tester.ensureVisible(find.text(SeedLibraryTextConstants.add));
    await tester.tap(find.text(SeedLibraryTextConstants.add));
    await pumpFrames(tester);
    expect(
      find.text(SeedLibraryTextConstants.prefixLengthError),
      findsOneWidget,
    );
    await scaffold.drainToast(tester);
  });

  testWidgets('creating a species POSTs with the chosen type and difficulty', (
    tester,
  ) async {
    await pumpAddSpecies(tester);
    when(
      () =>
          scaffold.repository.seedLibrarySpeciesPost(body: any(named: 'body')),
    ).thenAnswer(
      (_) async => chopper.Response<models.SpeciesComplete>(
        http.Response('b', 200),
        null,
      ),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.text(SeedLibraryTextConstants.addSpecies)),
    );
    // Pick the type through the real chip (label = Dart enum name), and
    // the difficulty through the same write the slider makes. Both writes
    // rebuild the page on the next frame, so let that land BEFORE filling
    // the fields — an enterText that pumps the rebuild loses its text.
    await tester.tap(find.text('plantesAromatiques'));
    container.read(difficultyFilterProvider.notifier).setFilter(3);
    await pumpFrames(tester, 2);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'Tomate');
    await tester.enterText(fields.at(1), 'TOM');
    await tester.enterText(fields.at(2), 'card-1');
    await tester.enterText(fields.at(3), '10');
    await tester.enterText(fields.at(4), '90');

    // The submit sits below the fold; a dropped tap would silently skip
    // the POST (convention 8).
    await tester.ensureVisible(find.text(SeedLibraryTextConstants.add));
    await tester.tap(find.text(SeedLibraryTextConstants.add));
    await pumpFrames(tester, 20);

    final captured =
        verify(
              () => scaffold.repository.seedLibrarySpeciesPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as SpeciesBase;
    expect(captured.name, 'Tomate');
    expect(captured.prefix, 'TOM');
    expect(captured.difficulty, 3);
    expect(captured.speciesType, SpeciesType.plantesAromatiques);
    expect(captured.nbSeedsRecommended, 10);
    await scaffold.drainToast(tester);
  });
}
