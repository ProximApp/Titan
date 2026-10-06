import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/recommendation/providers/recommendation_provider.dart';
import 'package:titan/recommendation/router.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'deep link to /recommendation/information renders the pre-selected recommendation',
    (tester) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      when(
        () => scaffold.repository.recommendationRecommendationsGet(),
      ).thenAnswer((_) async => chopperListResponse(<Recommendation>[]));
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

      // The information page renders from client-side state set by the list.
      container
          .read(recommendationProvider.notifier)
          .setRecommendation(
            Recommendation.empty().copyWith(
              id: 'r-1',
              title: 'Perfect Blue',
              summary: 'Animated psychological thriller',
              description:
                  'Directed by someone. Animated psychological thriller',
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
      // Two deferred libraries in sequence (root, information page).
      await settle(tester, frames: 30);

      // The card title + summary render via the async logo entry; the
      // description renders in the layout card below.
      expect(find.text('Perfect Blue'), findsOneWidget);
      expect(find.textContaining('Directed by someone'), findsOneWidget);
    },
  );
}
