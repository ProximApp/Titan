import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/flappybird/ui/pages/game_page/game_page.dart';
import 'package:titan/flappybird/ui/pages/leaderboard_page/leaderboard_page.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    when(() => scaffold.repository.flappybirdScoresGet()).thenAnswer(
      (_) async => scaffold.repository.ok([
        FlappyBirdScoreInDB.empty().copyWith(
          id: 's1',
          value: 12,
          user: CoreUserSimple.empty().copyWith(
            id: 'u1',
            firstname: 'Zoé',
            name: 'Martin',
          ),
        ),
      ]),
    );
    when(() => scaffold.repository.flappybirdScoresMeGet()).thenAnswer(
      (_) async => scaffold.repository.ok(
        FlappyBirdScoreCompleteFeedBack.empty().copyWith(
          position: 3,
          value: 4,
          user: CoreUserSimple.empty().copyWith(
            firstname: 'Me',
            name: 'Player',
          ),
        ),
      ),
    );
    when(
      () => scaffold.repository.flappybirdScoresPost(body: any(named: 'body')),
    ).thenAnswer(
      (_) async => scaffold.repository.ok(FlappyBirdScoreInDB.empty()),
    );
  });

  testWidgets('the trophy routes to the leaderboard over the real scores', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/flappybird',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    expect(QR.currentPath, '/flappybird');
    expect(find.byType(GamePage), findsOneWidget);
    expect(find.text('T A P   T O   P L A Y'), findsOneWidget);

    // The trophy is the template's only navigation; its onPressed refreshes
    // both leaderboard sources before routing to the child page.
    final trophy = find.byWidgetPredicate(
      (w) => w is HeroIcon && w.icon == HeroIcons.trophy,
      description: 'HeroIcon(trophy)',
    );
    await tester.tap(
      find.ancestor(of: trophy, matching: find.byType(IconButton)).first,
    );
    await settle(tester, frames: 24);

    expect(QR.currentPath, '/flappybird/leaderboard');
    expect(find.byType(LeaderBoardPage), findsOneWidget);
    expect(find.text('LeaderBoard'), findsOneWidget);
    // The list renders position and score as plain Text; the name rides in
    // an AutoSizeText, which find.text deliberately does not match.
    expect(find.text('1. '), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is AutoSizeText && (w.data ?? '').contains('Zoé'),
        description: 'AutoSizeText(Zoé)',
      ),
      findsOneWidget,
    );
    // The bottom section shows the personal best from the me-endpoint.
    expect(find.text('3. '), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
