import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/recommendation/router.dart';

import '../../shared/app_scaffold.dart';

Recommendation recommendation(String id, String title, String summary) =>
    Recommendation.empty().copyWith(
      id: id,
      title: title,
      summary: summary,
      description: 'Directed by someone. $summary',
      creation: DateTime(2026),
    );

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('deep link to /recommendation lists the recommendations', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    when(
      () => scaffold.repository.recommendationRecommendationsGet(),
    ).thenAnswer(
      (_) async => chopperListResponse([
        recommendation(
          'r-1',
          'Perfect Blue',
          'Animated psychological thriller',
        ),
        recommendation('r-2', 'Paprika', 'Dream-entering detective story'),
      ]),
    );
    // Logos auto-load; a 404 falls back to the placeholder asset.
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

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: RecommendationRouter.root,
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.text('Perfect Blue'), findsOneWidget);
    expect(find.text('Paprika'), findsOneWidget);
    expect(
      find.textContaining('Animated psychological thriller'),
      findsOneWidget,
    );
  });
}
