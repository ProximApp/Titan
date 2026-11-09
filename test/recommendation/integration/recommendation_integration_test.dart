import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
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
    var loads = 0;
    when(() => scaffold.repository.recommendationRecommendationsGet())
        .thenAnswer((_) async {
          loads++;
          return chopperListResponse([
            recommendation(
              'r-1',
              'Perfect Blue',
              'Animated psychological thriller',
            ),
            recommendation('r-2', 'Paprika', 'Dream-entering detective story'),
          ]);
        });
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

    // Pull-to-refresh: the host takes Refresher's iOS branch
    // (CupertinoSliverRefreshControl), whose onRefresh is the list's reload.
    final loadsBefore = loads;
    await tester.fling(
      find.byType(CustomScrollView).first,
      const Offset(0, 300),
      1000,
    );
    await tester.pump(); // release the drag
    await tester.pump(const Duration(seconds: 1)); // control asks for data
    await tester.pump(const Duration(seconds: 1)); // reload settles
    expect(loads, loadsBefore + 1);
    expect(find.text('Perfect Blue'), findsOneWidget);
  });
}
