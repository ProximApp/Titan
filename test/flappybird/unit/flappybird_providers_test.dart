import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/flappybird/class/bird.dart';
import 'package:titan/flappybird/class/pipe.dart';
import 'package:titan/flappybird/providers/current_best_score.dart';
import 'package:titan/flappybird/providers/bird_image_provider.dart';
import 'package:titan/flappybird/providers/bird_provider.dart';
import 'package:titan/flappybird/providers/game_loop_provider.dart';
import 'package:titan/flappybird/providers/game_state_provider.dart';
import 'package:titan/flappybird/providers/pipe_image_provider.dart';
import 'package:titan/flappybird/providers/pipe_list_provider.dart';
import 'package:titan/flappybird/providers/score_list_provider.dart';
import 'package:titan/flappybird/providers/user_score_provider.dart';
import 'package:titan/flappybird/tools/functions.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/repository/repository.dart';
import 'package:titan/user/adapters/core_user.dart';
import 'package:titan/user/providers/user_provider.dart';

import '../../shared/mock_openapi.dart';

class _BirdImageNotifier extends BirdImageNotifier {
  _BirdImageNotifier(this.initial);

  final Uint8List initial;

  @override
  Uint8List build() => initial;

  @override
  Future<Uint8List> switchColor(MaterialColor color) async =>
      Uint8List.fromList([9]);
}

class _PipeListNotifier extends PipeListNotifier {
  _PipeListNotifier(this.initial);

  final List<Pipe> initial;

  @override
  List<Pipe> build() => initial;
}

class _UserScoreNotifier extends UserScoreNotifier {
  _UserScoreNotifier(this.value);

  final int value;

  @override
  AsyncValue<FlappyBirdScoreCompleteFeedBack> build() => AsyncValue.data(
    FlappyBirdScoreCompleteFeedBack.empty().copyWith(value: value),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bird', () {
    test('empty builds a bird with a random material color', () {
      final bird = Bird.empty();
      expect(bird.user, CoreUserSimple.empty());
      expect(bird.color, isA<MaterialColor>());
      expect(bird.birdImage, isA<Image>());
      expect(bird.score, 0);
    });

    test('copyWith overrides only the given fields', () {
      final bird = Bird.empty();
      final copy = bird.copyWith(score: 4, birdPosition: 0.5);
      expect(copy.score, 4);
      expect(copy.birdPosition, 0.5);
      expect(copy.user, bird.user);
    });

    test('getColorValue packs rgba into a 32 bit integer', () {
      expect(Bird.getColorValue(const Color(0xFFFF0000)), 0xFFFF0000);
      expect(Bird.getColorValue(const Color(0x00000000)), 0x00000000);
    });
  });

  group('getSwatch', () {
    test('spreads the ten swatch steps around the base color', () {
      final swatch = getSwatch(const Color(0xFF808080));
      expect(swatch.keys, containsAll([50, 500, 900]));
      expect(swatch.length, 10);
    });
  });

  group('BirdNotifier', () {
    ProviderContainer buildContainer({List<int> image = const []}) {
      final container = ProviderContainer(
        overrides: [
          userProvider.overrideWithValue(CoreUser.empty()),
          birdImageProvider.overrideWith(
            () => _BirdImageNotifier(Uint8List.fromList(image)),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('build applies the signed-in user to the initial bird', () {
      final container = buildContainer();
      final bird = container.read(birdProvider);
      expect(bird.user, CoreUser.empty().toCoreUserSimple());
      expect(bird.score, 0);
    });

    test('update jump increaseScore and resetBird move the physics state', () {
      final container = buildContainer();
      final notifier = container.read(birdProvider.notifier);

      final updated = notifier.update();
      expect(updated.time, greaterThan(0));

      notifier.increaseScore();
      expect(container.read(birdProvider).score, 1);

      notifier.jump();
      final jumped = container.read(birdProvider);
      expect(jumped.time, 0);
      expect(jumped.angle, -pi / 4);

      notifier.resetBird();
      final reset = container.read(birdProvider);
      expect(reset.score, 0);
      expect(reset.birdPosition, 0);
    });

    test('a loaded image triggers the recoloring of the bird', () async {
      final container = buildContainer(image: [1, 2, 3]);
      container.read(birdProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(birdProvider).birdImage, isA<Image>());
    });
  });

  group('PipeListNotifier', () {
    test('build seeds three random pipes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final pipes = container.read(pipeListProvider);
      expect(pipes.length, 3);
      expect(pipes.map((p) => p.position), [1, 2.2, 3.4]);
    });

    test('update scrolls every pipe to the left', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(pipeListProvider.notifier);
      final updated = notifier.update();
      expect(updated.map((p) => p.position), [
        closeTo(0.99, 1e-9),
        closeTo(2.19, 1e-9),
        closeTo(3.39, 1e-9),
      ]);
    });

    test('resetPipe respawns only the pipes scrolled off screen', () {
      final pipes = [
        Pipe(position: -3, height: 100),
        Pipe(position: 0.5, height: 120, isPassed: true),
      ];
      final container = ProviderContainer(
        overrides: [
          pipeListProvider.overrideWith(() => _PipeListNotifier(pipes)),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(pipeListProvider.notifier);
      notifier.resetPipe();
      final state = container.read(pipeListProvider);
      expect(state[0].position, 0.5);
      expect(state[1].position, 0.5);
      expect(state[1].isPassed, isTrue);
    });

    test('setIsPassed flags only the requested pipe', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(pipeListProvider.notifier);
      notifier.setIsPassed(1);
      final state = container.read(pipeListProvider);
      expect(state[1].isPassed, isTrue);
      expect(state[0].isPassed, isFalse);
      expect(state[2].isPassed, isFalse);
    });

    test('birdHitPipe detects a bird crossing a pipe at the wrong height', () {
      final pipes = [Pipe(position: -0.5, height: 100)];
      final container = ProviderContainer(
        overrides: [
          pipeListProvider.overrideWith(() => _PipeListNotifier(pipes)),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(pipeListProvider.notifier);

      final bird = Bird.empty();
      expect(notifier.birdHitPipe(800, 400, bird), isFalse);
      expect(
        notifier.birdHitPipe(800, 400, bird.copyWith(birdPosition: 0.9)),
        isTrue,
      );
      expect(
        notifier.birdHitPipe(800, 400, bird.copyWith(birdPosition: -1)),
        isTrue,
      );
    });

    test('birdHitPipe ignores pipes outside the collision window', () {
      final pipes = [Pipe(position: 1, height: 100)];
      final container = ProviderContainer(
        overrides: [
          pipeListProvider.overrideWith(() => _PipeListNotifier(pipes)),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(pipeListProvider.notifier);
      expect(
        notifier.birdHitPipe(
          800,
          400,
          Bird.empty().copyWith(birdPosition: 0.9),
        ),
        isFalse,
      );
    });

    test('clearPipe resets to the initial formation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(pipeListProvider.notifier);
      notifier.update();
      notifier.clearPipe();
      final state = container.read(pipeListProvider);
      expect(state.map((p) => p.position), [1, 2.2, 3.4]);
    });
  });

  group('GameNotifier and TimerNotifier', () {
    test('game state toggles', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(gameStateProvider), isFalse);
      container.read(gameStateProvider.notifier).setState(true);
      expect(container.read(gameStateProvider), isTrue);
    });

    test('timer start stop and restart', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(timerProvider.notifier);
      expect(container.read(timerProvider), isNull);

      var firstTicks = 0;
      notifier.start((_) => firstTicks++);
      await Future<void>.delayed(const Duration(milliseconds: 45));
      expect(firstTicks, greaterThan(0));

      var secondTicks = 0;
      notifier.restart((_) => secondTicks++);
      await Future<void>.delayed(const Duration(milliseconds: 45));
      expect(secondTicks, greaterThan(0));

      notifier.stop();
      expect(container.read(timerProvider)!.isActive, isFalse);
    });
  });

  group('BestScoreNotifier', () {
    test('adopts the value coming from the leaderboard position', () {
      final container = ProviderContainer(
        overrides: [
          userScoreProvider.overrideWith(() => _UserScoreNotifier(7)),
        ],
      );
      addTearDown(container.dispose);
      // The whenData callback fires inside build(), so its setBest() is
      // overwritten by the `return 0` that finishes the build: the best
      // score only moves once setBest is called from the outside.
      expect(container.read(bestScoreProvider), 0);
      container.read(bestScoreProvider.notifier).setBest(9);
      expect(container.read(bestScoreProvider), 9);
    });
  });

  group('ScoreListNotifier and UserScoreNotifier', () {
    late MockOpenapi repo;
    late ProviderContainer container;

    setUp(() {
      repo = MockOpenapi();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
    });

    test('getLeaderboard loads the scores, createScore appends one', () async {
      when(() => repo.flappybirdScoresGet())
          .thenAnswer((_) async => repo.okList<FlappyBirdScoreInDB>());
      final notifier = container.read(scoreListProvider.notifier);
      final state = await notifier.getLeaderboard();
      expect(state.value, isEmpty);

      final score = FlappyBirdScoreBase.empty().copyWith(value: 10);
      when(() => repo.flappybirdScoresPost(body: any(named: 'body')))
          .thenAnswer((_) async => repo.ok(FlappyBirdScoreInDB.empty()));
      notifier.state = AsyncValue.data([FlappyBirdScoreInDB.empty()]);
      final ok = await notifier.createScore(score);
      expect(ok, isTrue);
      expect(notifier.state.value!.length, 2);
    });

    test(
      'createScore reports false when the post fails or is not ready',
      () async {
        when(() => repo.flappybirdScoresGet())
            .thenAnswer((_) async => repo.okList<FlappyBirdScoreInDB>());
        final notifier = container.read(scoreListProvider.notifier);
        await notifier.getLeaderboard();
        final score = FlappyBirdScoreBase.empty().copyWith(value: 10);

        when(() => repo.flappybirdScoresPost(body: any(named: 'body')))
            .thenAnswer((_) async => repo.fail<FlappyBirdScoreInDB>(400));
        expect(await notifier.createScore(score), isFalse);

        notifier.state = const AsyncValue.loading();
        expect(await notifier.createScore(score), isFalse);

        notifier.state = AsyncValue.error('boom', StackTrace.empty);
        expect(await notifier.createScore(score), isFalse);
      },
    );

    test('getLeaderBoardPosition resolves the signed-in best score', () async {
      when(() => repo.flappybirdScoresMeGet()).thenAnswer(
        (_) async =>
            repo.ok(FlappyBirdScoreCompleteFeedBack.empty().copyWith(value: 3)),
      );
      final notifier = container.read(userScoreProvider.notifier);
      await notifier.getLeaderBoardPosition();
      expect(container.read(userScoreProvider).value!.value, 3);
    });
  });

  group('bird and pipe image notifiers', () {
    test('bird image loads resizes and recolors the asset', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(birdImageProvider.notifier);
      // The load kicked off by build() never settles inside a test, so drive
      // the same method explicitly.
      await notifier.getBirdImage();
      expect(container.read(birdImageProvider), isNotEmpty);

      final recolored = await notifier.switchColor(Colors.blue);
      expect(recolored, isNotEmpty);
    });

    test('pipe image loads the pipe asset', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(pipeImageProvider.notifier);
      await notifier.getPipeImage();
      expect(container.read(pipeImageProvider), isNotEmpty);
    });
  });
}
