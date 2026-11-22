import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/flappybird/class/pipe.dart';
import 'package:titan/flappybird/providers/bird_provider.dart';
import 'package:titan/flappybird/providers/current_best_score.dart';
import 'package:titan/flappybird/providers/pipe_list_provider.dart';
import 'package:titan/flappybird/providers/game_loop_provider.dart';
import 'package:titan/flappybird/providers/score_list_provider.dart';
import 'package:titan/flappybird/providers/user_score_provider.dart';
import 'package:titan/flappybird/router.dart';
import 'package:titan/flappybird/ui/pages/game_page/game_page.dart';
import 'package:titan/flappybird/ui/pages/game_page/pipe_handler.dart';
import 'package:titan/flappybird/ui/pages/leaderboard_page/leaderboard_item.dart';
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

/// The two fallbacks the leaderboard had never rendered: a score list that is
/// still loading, and a best score that failed.
class _LoadingScores extends ScoreListNotifier {
  @override
  AsyncValue<List<FlappyBirdScoreInDB>> build() => const AsyncLoading();
}

/// One pipe parked in the scoring band, high up enough that the bird (which
/// starts dead centre) is not inside it: the loop then scores it on its first
/// tick, which no amount of real gameplay could be made deterministic about.
class _ScoringPipes extends PipeListNotifier {
  @override
  List<Pipe> build() => [Pipe(position: -0.5, height: 100)];
}

class _ErrUserScore extends UserScoreNotifier {
  @override
  AsyncValue<FlappyBirdScoreCompleteFeedBack> build() =>
      AsyncValue.error('best down', StackTrace.current);
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

  testWidgets('a tap once the game is running flaps instead of restarting', (
    tester,
  ) async {
    // The same GestureDetector has two arms: start (the first press) and jump
    // (every press after). Only the start arm had ever run.
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await pumpWidgetAt(
      tester,
      const GamePage(),
      container: container,
      surface: const ui.Size(800, 600),
    );
    await settle(tester, frames: 4);

    await tester.tap(find.text('T A P   T O   P L A Y'));
    await tester.pump();
    // A few ticks of falling, so the flap has something to reset.
    await tester.pump(const Duration(milliseconds: 40));
    final before = container.read(birdProvider);
    expect(before.time, greaterThan(0));

    // The play area itself (the blue box under the score bar).
    await tester.tapAt(tester.getCenter(find.byType(PipeHandler)));
    await tester.pump();

    final after = container.read(birdProvider);
    // `jump()` restarts the fall from where the bird is and snaps the angle:
    // the fall clock goes back to zero instead of growing with the loop.
    expect(after.time, 0);
    expect(after.angle, isNot(before.angle));
    expect(after.initialPosition, before.birdPosition);
    // Still running: the start screen has not come back.
    expect(find.text('T A P   T O   P L A Y'), findsNothing);

    container.read(timerProvider.notifier).stop();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pipe that passes scores once and the run posts the best', (
    tester,
  ) async {
    // The loop's scoring block (`position` inside the band, not yet passed)
    // and the game-over block that posts a new best had never run: real pipes
    // drift and the bird dies before one arrives. Parking a pipe in the band
    // makes the first 10 ms tick score it.
    final container = scaffold.makeContainer(
      providerOverrides: [pipeListProvider.overrideWith(_ScoringPipes.new)],
    );
    addTearDown(container.dispose);

    await pumpWidgetAt(
      tester,
      const GamePage(),
      container: container,
      surface: const ui.Size(800, 600),
    );
    await settle(tester, frames: 4);

    await tester.tap(find.text('T A P   T O   P L A Y'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 12));

    expect(container.read(birdProvider).score, 1);
    // The piped `bestScore` local is still 0 in this frame, so the run also
    // raises the record.
    expect(container.read(bestScoreProvider), 1);

    // Let the bird fall out of bounds: score 1 beats the stale 0, so the run
    // is posted.
    for (
      var i = 0;
      i < 120 && find.byType(AlertDialog).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(find.text('GAME OVER!'), findsOneWidget);
    verify(
      () => scaffold.repository.flappybirdScoresPost(body: any(named: 'body')),
    ).called(1);

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

  testWidgets('a pending leaderboard and a failed best show their fallbacks', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        scoreListProvider.overrideWith(() => _LoadingScores()),
        userScoreProvider.overrideWith(() => _ErrUserScore()),
      ],
    );
    addTearDown(container.dispose);

    await pumpWidgetAt(tester, const LeaderBoardPage(), container: container);

    // Loading scores above, the best score's error text below.
    expect(find.text('Loading'), findsOneWidget);
    expect(find.text('best down'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the silver medal is a different colour from the gold', (
    tester,
  ) async {
    // `position == 2` is the only step of the medal colour ladder nothing had
    // rendered: the seeded leaderboards carry a first place and nothing else.
    await pumpWidgetAt(
      tester,
      LeaderBoardItem(
        score: FlappyBirdScoreCompleteFeedBack(
          user: CoreUserSimple.empty().copyWith(
            nickname: 'runner-up',
            firstname: 'Run',
            name: 'Nerup',
          ),
          value: 7,
          position: 2,
          creationTime: DateTime(2026, 1, 1),
        ),
      ),
    );

    final position = tester.widget<Text>(find.text('2. '));
    expect(position.style!.color, Colors.grey.shade400);
    expect(find.text('runner-up'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
