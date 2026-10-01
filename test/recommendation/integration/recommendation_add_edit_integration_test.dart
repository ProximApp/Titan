import 'dart:convert';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
// Not re-exported by image_picker; transitive of image_picker.
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart'
    as platform;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/recommendation/router.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// A valid 1x1 PNG: the codec crashes on invalid image bytes.
final posterPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// The create form's validator refuses any deal without an image, and the
/// only way in is the real ImagePicker. Faking the platform interface keeps
/// the whole real path alive (pick → read → compress → preview → upload)
/// with the 1x1 PNG as the picked file.
class FakeImagePickerPlatform extends platform.ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    platform.ImagePickerOptions options = const platform.ImagePickerOptions(),
  }) async {
    return XFile.fromData(posterPng, name: 'poster.png', mimeType: 'image/png');
  }
}

/// The recommendation admin gate is a plain Provider over userProvider.groups
/// (admin_recommandation).
const adminRecommendationGroupId = '389215b2-ea45-4991-adc1-4d3e471541cf';

Recommendation deal(String id, String title) => Recommendation.empty().copyWith(
  id: id,
  title: title,
  summary: 'Two-for-one tickets',
  description: 'Show your student card at the counter.',
  creation: DateTime(2026, 9, 1),
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'the admin + card opens the add-deal form and creates one through the real POST',
    (tester) async {
      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(
          groups: [
            CoreGroupSimple.empty().copyWith(
              id: adminRecommendationGroupId,
              name: 'admin_recommandation',
            ),
          ],
        ),
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      when(
        () => scaffold.repository.recommendationRecommendationsGet(),
      ).thenAnswer(
        (_) async => chopperListResponse([deal('r-1', 'Cinema deal')]),
      );
      when(
        () => scaffold.repository
            .recommendationRecommendationsRecommendationIdPictureGet(
              recommendationId: any(named: 'recommendationId'),
            ),
      ).thenAnswer(
        (_) async => chopper.Response<List<int>>(
          http.Response('{"detail": "File does not exist"}', 404),
          [],
          error: 'File does not exist',
        ),
      );
      RecommendationBase? capturedDeal;
      when(
        () => scaffold.repository.recommendationRecommendationsPost(
          body: any(named: 'body'),
        ),
      ).thenAnswer((inv) async {
        capturedDeal = inv.namedArguments[#body] as RecommendationBase;
        return chopperResponse(deal('r-new', 'Pizza tuesdays'));
      });
      // The picked logo uploads right after the POST succeeds.
      when(
        () => scaffold.repository
            .recommendationRecommendationsRecommendationIdPicturePost(
              recommendationId: any(named: 'recommendationId'),
              image: any(named: 'image'),
            ),
      ).thenAnswer(
        (_) async => chopperResponse(AppTypesStandardResponsesResult.empty()),
      );

      // Route the real ImagePicker to the fake platform (see above).
      platform.ImagePickerPlatform.instance = FakeImagePickerPlatform();

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: RecommendationRouter.root,
        pumpAndSettle: false,
      );
      await settle(tester);

      // The main page renders the admin + card above the existing deals.
      expect(find.text('Cinema deal'), findsOneWidget);

      // The + card navigates to the add-edit page (deferred route: poll).
      // HeroIcons is the app's custom enum, not IconData: find the HeroIcon
      // widget by its icon field.
      await tester.tap(
        find
            .byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus)
            .first,
      );
      for (var i = 0; i < 20 && find.text('Add').evaluate().isEmpty; i++) {
        await settle(tester, frames: 4);
      }
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Short summary'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      // Create mode: empty fields.
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Title').first)
            .controller!
            .text,
        '',
      );

      // Tap the image placeholder: the real ImagePicker (through the fake
      // platform above) "picks" the PNG, runs it through the real compress-
      // and-preview path and fills the form's logo state — the thing the
      // form validator demands on create.
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.photo,
        ),
      );
      await settle(tester, frames: 6);

      // Fill the required fields (Code is optional).
      await tester.enterText(
        find.widgetWithText(TextField, 'Title').first,
        'Pizza tuesdays',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Short summary').first,
        'Half price on all pizzas',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Description').first,
        'Every tuesday at Partneria, on presentation of the card.',
      );
      await settle(tester, frames: 4);

      // Submit: the real POST fires with the form values, the page pops back
      // and the success toast shows. The submit sits below the fold.
      await tester.dragUntilVisible(
        find.text('Add'),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await settle(tester, frames: 2);
      await tester.tap(find.text('Add'));
      await settle(tester, frames: 12);

      expect(capturedDeal, isNotNull);
      expect(capturedDeal!.title, 'Pizza tuesdays');
      expect(capturedDeal!.summary, 'Half price on all pizzas');
      expect(
        capturedDeal!.description,
        'Every tuesday at Partneria, on presentation of the card.',
      );
      // Back on the main page with the success toast.
      expect(find.text('Deal added'), findsOneWidget);
      // Drain the toast timer.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
