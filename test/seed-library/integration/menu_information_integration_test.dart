import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/seed-library/providers/species_type_list_provider.dart';
import 'package:titan/seed-library/tools/constants.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../seed_library_fixtures.dart';

/// The admin root menu (`/seed_library`) and the information branch: every
/// MenuCardUi closure that opens a link or the information icon, the
/// information page, and the gated edit-information form's validation /
/// success / failure arms — ONE router-pushing session, because qlevar
/// keeps the active route branch in process-global state (convention 19):
/// a second router-driven test in this file would render this session's
/// leftover page instead. The species/stock/deposit card navigations live
/// in their own single-test files.
final information = SeedLibraryInformation.empty().copyWith(
  description: 'Le potager partagé',
  contact: 'potager@asso.fr',
  facebookUrl: 'https://fb.example/potager',
  forumUrl: 'https://forum.example/potager',
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'the help cards launch their links and the info icon opens informations',
    (tester) async {
      final container = scaffold.makeContainer(user: seedLibraryAdminUser);
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);

      stubSeedLibrary(scaffold, information: information);
      final fake = FakeUrlLauncher(launchSucceeds: true);
      stubUrlLauncher(fake);

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

      // All six admin cards are present (reveal each row first; rows below
      // the viewport are neither mounted nor hittable).
      await revealMenu(
        tester,
        menuCard(SeedLibraryTextConstants.speciesSimple),
      );
      expect(menuCard(SeedLibraryTextConstants.speciesSimple), findsOneWidget);
      expect(menuCard(SeedLibraryTextConstants.myPlants), findsOneWidget);
      expect(menuCard(SeedLibraryTextConstants.stock), findsOneWidget);
      expect(menuCard(SeedLibraryTextConstants.seedDeposit), findsOneWidget);
      await revealMenu(tester, menuCard(SeedLibraryTextConstants.helpSheets));
      expect(menuCard(SeedLibraryTextConstants.helpSheets), findsOneWidget);
      expect(menuCard(SeedLibraryTextConstants.forum), findsOneWidget);

      // The two link cards route through openLink, not the router.
      await revealMenu(tester, menuCard(SeedLibraryTextConstants.helpSheets));
      await tester.tap(menuCard(SeedLibraryTextConstants.helpSheets));
      await settle(tester);
      await revealMenu(tester, menuCard(SeedLibraryTextConstants.forum));
      await tester.tap(menuCard(SeedLibraryTextConstants.forum));
      await settle(tester);
      expect(fake.launched, [
        'https://fb.example/potager',
        'https://forum.example/potager',
      ]);

      // The template's right icon exists only at the root…
      Finder infoIcon() => find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.informationCircle,
      );
      expect(infoIcon(), findsOneWidget);
      await tester.ensureVisible(infoIcon());
      await settle(tester, frames: 2);
      await tester.tap(infoIcon());
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await settle(tester, frames: 10);

      // …and lands on the information page.
      expect(find.text(SeedLibraryTextConstants.information), findsOneWidget);
      expect(find.text('Le potager partagé'), findsOneWidget);
      expect(find.text(SeedLibraryTextConstants.contact), findsOneWidget);
      expect(find.text('potager@asso.fr'), findsOneWidget);
      expect(
        find.text(SeedLibraryTextConstants.editInformation),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      // Into the admin-gated edit form.
      await tester.ensureVisible(
        find.text(SeedLibraryTextConstants.editInformation),
      );
      await settle(tester, frames: 2);
      await tester.tap(find.text(SeedLibraryTextConstants.editInformation));
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await settle(tester, frames: 10);

      expect(find.text(SeedLibraryTextConstants.description), findsOneWidget);
      expect(find.text(SeedLibraryTextConstants.contact), findsWidgets);
      expect(
        find.widgetWithText(TextFormField, 'Le potager partagé'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'potager@asso.fr'),
        findsOneWidget,
      );

      when(
        () => scaffold.repository.seedLibraryInformationPatch(
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => chopperResponseVoid());

      // Validation arm first: emptying the required contact field toasts
      // emptyFieldError and stays on the form.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'potager@asso.fr'),
        '',
      );
      await scaffold.unfocus(tester);
      await tester.ensureVisible(find.text(SeedLibraryTextConstants.update));
      await settle(tester, frames: 2);
      await tester.tap(find.text(SeedLibraryTextConstants.update));
      await settle(tester, frames: 10);
      expect(
        find.text(SeedLibraryTextConstants.emptyFieldError),
        findsOneWidget,
      );
      await scaffold.drainToast(tester);

      // Success arm: PATCH 200 → toast → QR.back to the information page.
      // Four fields: description, contact, facebook url, forum url —
      // refilled by position (the contact field was emptied above).
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(1), 'contact@asso.fr');
      await scaffold.unfocus(tester);
      await tester.ensureVisible(find.text(SeedLibraryTextConstants.update));
      await settle(tester, frames: 2);
      await tester.tap(find.text(SeedLibraryTextConstants.update));
      await settle(tester, frames: 10);

      verify(
        () => scaffold.repository.seedLibraryInformationPatch(
          body: any(named: 'body'),
        ),
      ).called(1);
      expect(
        find.text(SeedLibraryTextConstants.updatedInformation),
        findsOneWidget,
      );
      await scaffold.drainToast(tester);
      // QR.back() → information page again.
      expect(find.text(SeedLibraryTextConstants.information), findsOneWidget);

      // Failure arm: 400 → error toast.
      when(
        () => scaffold.repository.seedLibraryInformationPatch(
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response<void>(http.Response('err', 400), null),
      );
      await tester.ensureVisible(
        find.text(SeedLibraryTextConstants.editInformation),
      );
      await settle(tester, frames: 2);
      await tester.tap(find.text(SeedLibraryTextConstants.editInformation));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await settle(tester, frames: 10);
      await tester.enterText(fields.at(0), 'nouveau');
      await scaffold.unfocus(tester);
      await tester.ensureVisible(find.text(SeedLibraryTextConstants.update));
      await settle(tester, frames: 2);
      await tester.tap(find.text(SeedLibraryTextConstants.update));
      await settle(tester, frames: 10);
      expect(find.text(SeedLibraryTextConstants.updatingError), findsOneWidget);
      await scaffold.drainToast(tester);
    },
  );
}
