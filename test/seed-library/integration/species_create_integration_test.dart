import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/seed-library/tools/constants.dart';

import '../../shared/app_scaffold.dart';
import '../seed_library_fixtures.dart';

/// The species CREATE form in one session (convention 19 — one
/// router-pushing test per file): plus card → validation and difficulty
/// gates → create with both months set (the create branch's
/// DateTime(2021, …) arms) → back to the list → second round where the
/// POST returns 400 and the form stays up with addingError.
SpeciesComplete persil() => SpeciesComplete.empty().copyWith(
  id: 'sp-9',
  name: 'Persil',
  prefix: 'PER',
  difficulty: 3,
  speciesType: SpeciesType.plantesAromatiques,
  timeMaturation: 40,
  nbSeedsRecommended: 100,
  card: 'https://fiche.example/help',
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'the plus card gates on difficulty then creates, and a 400 toasts',
    (tester) async {
      final container = scaffold.makeContainer(user: seedLibraryAdminUser);
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      stubSeedLibrary(scaffold);
      when(
        () => scaffold.repository.seedLibrarySpeciesPost(
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => chopperResponse(persil()));

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

      // Empty branch: the page offers only the plus card.
      expect(find.text(SeedLibraryTextConstants.noSpecies), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The plus handler resets the filters and navigates.
      await tester.ensureVisible(plusCard());
      await settle(tester, frames: 2);
      await tester.tap(plusCard());
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await settle(tester, frames: 10);
      expect(find.text(SeedLibraryTextConstants.addSpecies), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Persil');
      await tester.enterText(fields.at(1), 'PER');
      await scaffold.unfocus(tester);

      // The empty-field validation arm: clear the required name.
      await tester.enterText(fields.at(0), '');
      await scaffold.unfocus(tester);
      await tester.ensureVisible(find.text(SeedLibraryTextConstants.add));
      await settle(tester, frames: 2);
      await tester.tap(find.text(SeedLibraryTextConstants.add));
      await settle(tester, frames: 10);
      expect(
        find.text(SeedLibraryTextConstants.emptyFieldError),
        findsOneWidget,
      );
      await scaffold.drainToast(tester);
      await tester.enterText(fields.at(0), 'Persil');
      await scaffold.unfocus(tester);

      // Difficulty gate: the plus handler reset the slider to 0.
      await tester.ensureVisible(find.text(SeedLibraryTextConstants.add));
      await settle(tester, frames: 2);
      await tester.tap(find.text(SeedLibraryTextConstants.add));
      await settle(tester, frames: 10);
      expect(
        find.text(SeedLibraryTextConstants.emptyDifficultyError),
        findsOneWidget,
      );
      await scaffold.drainToast(tester);

      // Lift the slider to 5 and set BOTH months so the create branch's
      // DateTime(2021, …) arms execute.
      await tester.drag(find.byType(Slider), const Offset(1200, 0));
      await settle(tester, frames: 4);
      final monthDropdowns = find.byType(DropdownButton<String>);
      expect(monthDropdowns, findsNWidgets(2));
      await tester.ensureVisible(monthDropdowns.first);
      await settle(tester, frames: 2);
      await tester.tap(monthDropdowns.first);
      await settle(tester, frames: 4);
      await tester.tap(find.text('Janvier'));
      await settle(tester, frames: 4);
      await tester.ensureVisible(monthDropdowns.last);
      await settle(tester, frames: 2);
      await tester.tap(monthDropdowns.last);
      await settle(tester, frames: 4);
      await tester.tap(find.text('Février'));
      await settle(tester, frames: 4);

      await scaffold.unfocus(tester);
      await tester.ensureVisible(find.text(SeedLibraryTextConstants.add));
      await settle(tester, frames: 2);
      await tester.tap(find.text(SeedLibraryTextConstants.add));
      await settle(tester, frames: 12);

      verify(
        () => scaffold.repository.seedLibrarySpeciesPost(
          body: any(named: 'body'),
        ),
      ).called(1);
      expect(find.text(SeedLibraryTextConstants.addedSpecies), findsOneWidget);
      await scaffold.drainToast(tester);
      // QR.back() → the new card is on the list.
      expect(find.text(SeedLibraryTextConstants.speciesPlural), findsOneWidget);
      expect(find.text('Persil'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Second round: a rejected create toasts the adding error and stays
      // on the form (no QR.back).
      when(
        () => scaffold.repository.seedLibrarySpeciesPost(
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            chopper.Response<SpeciesComplete>(http.Response('err', 400), null),
      );
      await tester.ensureVisible(plusCard());
      await settle(tester, frames: 2);
      await tester.tap(plusCard());
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await settle(tester, frames: 10);

      final secondRound = find.byType(TextFormField);
      await tester.enterText(secondRound.at(0), 'Ciboulette');
      await tester.enterText(secondRound.at(1), 'CIB');
      await scaffold.unfocus(tester);
      await tester.drag(find.byType(Slider), const Offset(1200, 0));
      await settle(tester, frames: 4);

      await tester.ensureVisible(find.text(SeedLibraryTextConstants.add));
      await settle(tester, frames: 2);
      await tester.tap(find.text(SeedLibraryTextConstants.add));
      await settle(tester, frames: 12);

      expect(find.text(SeedLibraryTextConstants.addingError), findsOneWidget);
      await scaffold.drainToast(tester);
      expect(find.text(SeedLibraryTextConstants.addSpecies), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
