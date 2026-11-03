import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/flappybird/class/bird.dart';
import 'package:titan/flappybird/providers/bird_image_provider.dart';
import 'package:titan/flappybird/providers/bird_provider.dart';
import 'package:titan/flappybird/providers/pipe_image_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/user/providers/user_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bird setters replace their slices of the state', () async {
    final container = ProviderContainer(
      overrides: [userProvider.overrideWithValue(CoreUser.empty())],
    );
    addTearDown(container.dispose);
    final notifier = container.read(birdProvider.notifier);
    // The build-time asset load and its recolor callback settle first, so
    // the explicit setBirdImage below is the last write to the state.
    await pumpEventQueue();

    notifier.setBird(Bird.empty().copyWith(score: 7));
    expect(container.read(birdProvider).score, 7);

    notifier.setUser(
      CoreUserSimple.empty().copyWith(firstname: 'Ada', name: 'Lovelace'),
    );
    expect(container.read(birdProvider).user.firstname, 'Ada');

    notifier.setBirdImage(const SizedBox.shrink());
    expect(container.read(birdProvider).birdImage, isA<SizedBox>());

    // Flush any trailing recolor callback while the container is alive.
    await pumpEventQueue();
  });

  test('the image providers keep the bytes they are given', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final birdImage = container.read(birdImageProvider.notifier);
    final pipeImage = container.read(pipeImageProvider.notifier);
    // Both assets decode during this flush, so setList is the final write.
    await pumpEventQueue();

    birdImage.setList(Uint8List.fromList([1, 2, 3]));
    pipeImage.setList(Uint8List.fromList([4, 5]));

    expect(container.read(birdImageProvider), [1, 2, 3]);
    expect(container.read(pipeImageProvider), [4, 5]);
  });
}
