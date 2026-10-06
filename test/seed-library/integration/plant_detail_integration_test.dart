import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/seed-library/providers/plant_complete_provider.dart';
import 'package:titan/seed-library/providers/species_list_provider.dart';

import '../../shared/app_scaffold.dart';

const speciesId = 'sp-1';

SpeciesComplete species({int difficulty = 2, String? card}) =>
    SpeciesComplete.empty().copyWith(
      id: speciesId,
      prefix: 'BAS',
      name: 'Basilic',
      difficulty: difficulty,
      speciesType: SpeciesType.plantesAromatiques,
      card: card,
    );

/// A borrowed, not-yet-planted plant: shows the "Je la plante maintenant"
/// button and no death button.
PlantComplete plant({PlantState? state, DateTime? plantingDate}) =>
    PlantComplete.empty().copyWith(
      id: 'plant-1',
      reference: 'BAS-0001',
      nickname: 'Basilic du bureau',
      speciesId: speciesId,
      state: state ?? PlantState.rCupRE,
      propagationMethod: PropagationMethod.graine,
      nbSeedsEnvelope: 12,
      borrowingDate: DateTime(2026, 1, 5),
      plantingDate: plantingDate,
      currentNote: 'Arrosage le lundi',
    );

void stubSeedLibrary(IntegrationScaffold scaffold) {
  when(
    () => scaffold.repository.seedLibraryInformationGet(),
  ).thenAnswer((_) async => chopperResponse(SeedLibraryInformation.empty()));
  when(
    () => scaffold.repository.seedLibraryPlantsUsersMeGet(),
  ).thenAnswer((_) async => chopperListResponse(<PlantSimple>[]));
  when(
    () => scaffold.repository.seedLibrarySpeciesGet(),
  ).thenAnswer((_) async => chopperListResponse([species()]));
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Boots the app deep-linked on the plant detail route. The page reads
  /// plantProvider but nothing on this route triggers loadPlant, so the
  /// test sets the plant AFTER the pump; the species list is pre-warmed
  /// BEFORE it (the detail page's bare species.firstWhere crashes when the
  /// plant arrives while the species list is still empty — the shipped
  /// deep-link state, README ledger #26).
  Future<void> pumpPlantDetail(
    WidgetTester tester, {
    required PlantComplete currentPlant,
  }) async {
    final container = scaffold.makeContainer();
    container.read(syncSpeciesListProvider);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/seed_library/plants/plant_detail',
      pumpAndSettle: false,
    );
    container.read(plantProvider.notifier).setPlant(currentPlant);
    await settle(tester, frames: 8);
  }

  group('Editable plant detail', () {
    testWidgets('renders the borrowed-plant detail with its species info', (
      tester,
    ) async {
      stubSeedLibrary(scaffold);

      await pumpPlantDetail(tester, currentPlant: plant());

      expect(find.text('Détail de la plante'), findsOneWidget);
      // The nickname pre-fills the name field; the reference line shows
      // because a nickname exists.
      expect(find.text('Référence : BAS-0001'), findsOneWidget);
      expect(find.text('Espèce : Basilic'), findsOneWidget);
      // Raw enum name (same cosmetic bug as the TypesBar, ledger #23).
      expect(find.text('Type : plantesAromatiques'), findsOneWidget);
      expect(find.textContaining('Difficulté :'), findsOneWidget);
      // Two difficulty stars for difficulty 2.
      expect(
        find.byWidgetPredicate((w) => w is Icon && w.icon == Icons.star),
        findsNWidgets(2),
      );
      expect(find.text('Méthode de propagation : graine'), findsOneWidget);
      expect(find.textContaining('Quantité de graines : 12'), findsOneWidget);
      // en locale short date for the borrowing date.
      expect(find.textContaining("Date d'emprunt :"), findsOneWidget);
      expect(find.textContaining('1/5/2026'), findsOneWidget);
      // The QR secret is NOT rendered on the editable detail page.
      expect(find.byType(QrImageView), findsNothing);
      // Borrowed-not-planted: the planting button, no death button.
      expect(find.text('Je la plante maintenant'), findsOneWidget);
      expect(find.text('Plante morte'), findsNothing);
    });

    testWidgets('planting now PATCHes today and flips the page state', (
      tester,
    ) async {
      stubSeedLibrary(scaffold);
      when(
        () => scaffold.repository.seedLibraryPlantsPlantIdPatch(
          plantId: any(named: 'plantId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => chopperResponseVoid());

      await pumpPlantDetail(tester, currentPlant: plant());

      await tester.tap(find.text('Je la plante maintenant'));
      await settle(tester, frames: 8);

      // The PATCH body carries a (today) planting date.
      final captured =
          verify(
                () => scaffold.repository.seedLibraryPlantsPlantIdPatch(
                  plantId: 'plant-1',
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as PlantEdit;
      expect(captured.plantingDate, isNotNull);
      // The date field label switched to the planting date and the
      // planting button is gone (plant.plantingDate != null branch).
      expect(find.text('Date de plantation'), findsOneWidget);
      expect(find.text('Je la plante maintenant'), findsNothing);
    });

    testWidgets('the save button PATCHes nickname + note changes', (
      tester,
    ) async {
      stubSeedLibrary(scaffold);
      when(
        () => scaffold.repository.seedLibraryPlantsPlantIdPatch(
          plantId: any(named: 'plantId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => chopperResponseVoid());

      await pumpPlantDetail(tester, currentPlant: plant());

      // Change the note (multiline field) and the nickname.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Notes'),
        'Arrosage le mardi',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom'),
        'Basilic géant',
      );

      // Release the field focus so the tap reaches the button
      // (convention 12).
      await scaffold.unfocus(tester);
      await tester.ensureVisible(find.text('Sauvegarder les modifications'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Sauvegarder les modifications'));
      await settle(tester, frames: 10);

      final captured =
          verify(
                () => scaffold.repository.seedLibraryPlantsPlantIdPatch(
                  plantId: 'plant-1',
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as PlantEdit;
      expect(captured.currentNote, 'Arrosage le mardi');
      expect(captured.nickname, 'Basilic géant');
      // Success toast from the French constants (before it auto-closes).
      expect(find.text('Plante modifiée'), findsOneWidget);
      await scaffold.drainToast(tester);
    });

    testWidgets('the death flow confirms and PATCHes the consommée state', (
      tester,
    ) async {
      stubSeedLibrary(scaffold);
      final planted = plant(
        state: PlantState.rCupRE,
        plantingDate: DateTime(2026, 2, 1),
      );
      when(
        () => scaffold.repository.seedLibraryPlantsPlantIdPatch(
          plantId: any(named: 'plantId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => chopperResponseVoid());

      await pumpPlantDetail(tester, currentPlant: planted);

      // Planted + alive: the death button shows, the planting button does
      // not.
      expect(find.text('Plante morte'), findsOneWidget);
      expect(find.text('Je la plante maintenant'), findsNothing);

      // The button sits below the fold of the page's scroll view.
      await tester.ensureVisible(find.text('Plante morte'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Plante morte'));
      await settle(tester, frames: 8);
      // While the dialog is open the button's WaitingButton is still
      // awaiting the dialog future, so only the dialog title carries the
      // label; the descriptions text proves the dialog is up.
      expect(
        find.text('Voulez-vous déclarer la plante morte ?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Confirm'));
      await settle(tester, frames: 12);

      final captured =
          verify(
                () => scaffold.repository.seedLibraryPlantsPlantIdPatch(
                  plantId: 'plant-1',
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as PlantEdit;
      expect(captured.state, PlantState.consommE);
      // The date entry label flips to the death date and the success toast
      // shows (before it auto-closes).
      expect(find.text('Date de mort'), findsOneWidget);
      expect(find.text('Plante modifiée'), findsOneWidget);
      await scaffold.drainToast(tester);
    });

    testWidgets('a failed save shows the error toast', (tester) async {
      stubSeedLibrary(scaffold);
      when(
        () => scaffold.repository.seedLibraryPlantsPlantIdPatch(
          plantId: any(named: 'plantId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response<void>(http.Response('err', 400), null),
      );

      await pumpPlantDetail(tester, currentPlant: plant());

      await scaffold.unfocus(tester);
      await tester.ensureVisible(find.text('Sauvegarder les modifications'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Sauvegarder les modifications'));
      await settle(tester, frames: 10);

      expect(find.text('Erreur lors de la modification'), findsOneWidget);
      await scaffold.drainToast(tester);
    });
  });
}
