import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/flappybird/providers/game_loop_provider.dart';
import 'package:titan/flappybird/providers/score_list_provider.dart';
import 'package:titan/flappybird/providers/user_score_provider.dart';
import 'package:titan/flappybird/router.dart';
import 'package:titan/flappybird/ui/pages/game_page/game_page.dart';
import 'package:titan/flappybird/ui/pages/leaderboard_page/leaderboard_page.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

class _ErrScores extends ScoreListNotifier {
  @override
  AsyncValue<List<FlappyBirdScoreInDB>> build() =>
      AsyncValue.error('boom', StackTrace.current);
}

class _LoadingUserScore extends UserScoreNotifier {
  @override
  AsyncValue<FlappyBirdScoreCompleteFeedBack> build() => const AsyncLoading();
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    // The game page reads (and so builds) both leaderboard sources, and a
    // passing pipe can post a score mid-run.
    when(
      () => scaffold.repository.flappybirdScoresGet(),
    ).thenAnswer((_) async => scaffold.repository.ok(<FlappyBirdScoreInDB>[]));
    when(() => scaffold.repository.flappybirdScoresMeGet()).thenAnswer(
      (_) async =>
          scaffold.repository.ok(FlappyBirdScoreCompleteFeedBack.empty()),
    );
    when(
      () => scaffold.repository.flappybirdScoresPost(body: any(named: 'body')),
    ).thenAnswer(
      (_) async => scaffold.repository.ok(FlappyBirdScoreInDB.empty()),
    );
  });

  testWidgets('the game runs to game over and restarts both ways', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    // The score Row overflows the 360px phone surface (its silkscreen
    // labels are wide); the game targets the wider desktop layout.
    await pumpWidgetAt(
      tester,
      const GamePage(),
      container: container,
      surface: const ui.Size(800, 600),
    );
    await settle(tester, frames: 4);

    expect(find.text('T A P   T O   P L A Y'), findsOneWidget);
    expect(find.text('S C O R E'), findsOneWidget);
    expect(find.text('R E C O R D'), findsOneWidget);

    // The first tap flips gameState and starts the 10ms loop; the bird
    // falls out of bounds within a second of game time, the loop stops
    // itself and the dialog comes up.
    await tester.tap(find.text('T A P   T O   P L A Y'));
    await tester.pump();
    expect(find.text('T A P   T O   P L A Y'), findsNothing);

    for (
      var i = 0;
      i < 120 && find.byType(AlertDialog).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('GAME OVER!'), findsOneWidget);

    // Restart 1: the dialog-body gesture resets bird and pipes.
    await tester.tap(find.text('GAME OVER!'));
    await settle(tester, frames: 6);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('T A P   T O   P L A Y'), findsOneWidget);

    // Restart 2: a second full run dismissed through the refresh button.
    await tester.tap(find.text('T A P   T O   P L A Y'));
    await tester.pump();
    for (
      var i = 0;
      i < 120 && find.byType(AlertDialog).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.byIcon(Icons.refresh));
    await settle(tester, frames: 6);
    expect(find.text('T A P   T O   P L A Y'), findsOneWidget);

    // Belt: no periodic timer may outlive the test.
    container.read(timerProvider.notifier).stop();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the module exposes its localized name and description', (
    tester,
  ) async {
    String? name;
    String? description;
    await pumpWidgetAt(
      tester,
      Builder(
        builder: (context) {
          name = FlappyBirdRouter.module.getName(context);
          description = FlappyBirdRouter.module.getDescription(context);
          return const SizedBox();
        },
      ),
    );

    expect(name, 'Flappy Bird');
    expect(description, isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed leaderboard and a pending best show their fallbacks', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        scoreListProvider.overrideWith(() => _ErrScores()),
        userScoreProvider.overrideWith(() => _LoadingUserScore()),
      ],
    );
    addTearDown(container.dispose);

    await pumpWidgetAt(tester, const LeaderBoardPage(), container: container);

    expect(find.text('boom'), findsOneWidget);
    expect(find.text('Loading'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
