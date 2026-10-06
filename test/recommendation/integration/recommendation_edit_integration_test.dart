import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/recommendation/providers/recommendation_provider.dart';
import 'package:titan/recommendation/router.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The recommendation admin gate is a plain Provider over userProvider.groups
/// (admin_recommandation).
const adminRecommendationGroupId = '389215b2-ea45-4991-adc1-4d3e471541cf';

/// The edit journey in its own file: navigation to the deferred add-edit
/// route after another journey wedges the router stack in the same process
/// (README convention 10).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'the information-page pencil opens the prefilled edit form and saves through the real PATCH',
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
      // The edited deal must exist in the loaded list: ListNotifierAPI's
      // in-place update replaces by id, and a deal absent from the list would
      // make the successful PATCH still report failure (RangeError on
      // indexWhere -1). In production the edit always opens from a rendered
      // card of the loaded list.
      when(
        () => scaffold.repository.recommendationRecommendationsGet(),
      ).thenAnswer(
        (_) async => chopperListResponse([
          Recommendation.empty().copyWith(
            id: 'r-1',
            title: 'Perfect Blue',
            summary: 'Animated psychological thriller',
            description: 'Directed by someone.',
            creation: DateTime(2026),
          ),
        ]),
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
      RecommendationEdit? capturedEdit;
      String? capturedId;
      when(
        () => scaffold.repository
            .recommendationRecommendationsRecommendationIdPatch(
              recommendationId: any(named: 'recommendationId'),
              body: any(named: 'body'),
            ),
      ).thenAnswer((inv) async {
        capturedEdit = inv.namedArguments[#body] as RecommendationEdit;
        capturedId = inv.namedArguments[#recommendationId] as String;
        return chopperResponseVoid();
      });

      // The information page renders from client-side state set by the list.
      container
          .read(recommendationProvider.notifier)
          .setRecommendation(
            Recommendation.empty().copyWith(
              id: 'r-1',
              title: 'Perfect Blue',
              summary: 'Animated psychological thriller',
              description: 'Directed by someone.',
              creation: DateTime(2026),
            ),
          );

      await scaffold.pumpApp(
        tester,
        container,
        initialPath:
            '${RecommendationRouter.root}${RecommendationRouter.information}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // The admin pencil sits in the card on the information page. HeroIcons
      // is the app's custom enum, not IconData: find the HeroIcon widget by
      // its icon field.
      expect(find.text('Perfect Blue'), findsOneWidget);
      await tester.tap(
        find
            .byWidgetPredicate(
              (w) => w is HeroIcon && w.icon == HeroIcons.pencil,
            )
            .first,
      );
      for (var i = 0; i < 20 && find.text('Edit').evaluate().isEmpty; i++) {
        await settle(tester, frames: 4);
      }
      expect(find.text('Edit'), findsOneWidget);
      // Edit mode: the form is prefilled from the tapped deal.
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Title').first)
            .controller!
            .text,
        'Perfect Blue',
      );

      // Rename and submit (button below the fold — scroll to it).
      await tester.enterText(
        find.widgetWithText(TextField, 'Title').first,
        'Perfect Blue — extended',
      );
      await settle(tester, frames: 4);
      await tester.dragUntilVisible(
        find.text('Edit'),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await settle(tester, frames: 2);
      await tester.tap(find.text('Edit'));
      await settle(tester, frames: 12);

      // The real PATCH fired for the right deal with the new title.
      expect(capturedEdit, isNotNull);
      expect(capturedEdit!.title, 'Perfect Blue — extended');
      expect(capturedEdit!.summary, 'Animated psychological thriller');
      expect(capturedId, 'r-1');
      // Back on the information page with the success toast; drain it.
      expect(find.text('Deal updated'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
