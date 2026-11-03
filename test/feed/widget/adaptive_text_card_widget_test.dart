import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/feed/tools/image_color_utils.dart';
import 'package:titan/feed/ui/widgets/adaptive_text_card.dart';
import 'package:titan/tools/constants.dart';

import '../../shared/app_scaffold.dart';

/// A 1x1 PNG: its sampling window has no rows, so `getDominantColor` lands
/// on the `pixelCount == 0` fallback.
final Uint8List onePixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// `AdaptiveTextCard` and its inherited half: the card publishes the
/// analyzing/hasImage flags, `AdaptiveTextProvider.of` reads them back (the
/// lookup every adaptive text in the feed performs), the analyzer runs
/// against a real image down to the no-sampled-rows fallback, and the
/// notifier's `refresh()` re-runs it and lands back in data — plus a pair
/// of AWAITED `getDominantColor` calls (ledger #37) so the function's tail
/// is exercised on every run instead of only when the engine's decode
/// happens to land before teardown.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the card publishes its flags and refresh settles back to data', (
    tester,
  ) async {
    final container = scaffold.makeLoggedOutContainer();
    addTearDown(container.dispose);
    // ONE instance: the family key is compared by identity, so the widget and
    // the reads below have to share it.
    final imageKey = MemoryImage(onePixel);

    await scaffold.pumpWidgetApp(
      tester,
      AdaptiveTextCard(
        hasImage: true,
        imageProvider: imageKey,
        child: Builder(
          builder: (context) {
            final inherited = AdaptiveTextProvider.of(context);
            return Text(
              'analyzing=${inherited?.isAnalyzing} '
              'image=${inherited?.hasImage}',
            );
          },
        ),
      ),
      container,
    );
    // Image decoding runs on the engine's async lane, which the fake async
    // test clock never drains: give it real time before pumping frames.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await settle(tester, frames: 16);

    // The analysis resolves: 1x1 → no sampled rows → the fallback colour.
    final state = container.read(dominantColorProvider(imageKey));
    expect(state, isA<AsyncData<Color?>>());
    expect(state.value, ColorConstants.main);

    // refresh() re-runs the same analysis through loading → data.
    container.read(dominantColorProvider(imageKey).notifier).refresh();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await settle(tester, frames: 8);
    expect(
      container.read(dominantColorProvider(imageKey)),
      isA<AsyncData<Color?>>(),
    );
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  // Ledger #37: `getDominantColor` awaits `Image.toByteData()`, real engine
  // work the fake-async clock cannot drive — the old coverage of this file
  // depended on whether the decode finished before teardown (+/-18 lines).
  // Awaiting the future inside `runAsync` removes the race: both exits of
  // the sampler run on every execution.
  testWidgets('getDominantColor resolves on the awaited engine lane', (
    tester,
  ) async {
    // 1x1: the sampling window has no rows → the fallback colour.
    final fallback = await tester.runAsync(
      () => getDominantColor(MemoryImage(onePixel)),
    );
    expect(fallback, ColorConstants.main);

    // A real 8x8 solid blue image: startY = 5, so one row of two sampled
    // pixels — the averaging branch and its loop bodies.
    final sampled = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawRect(
        const ui.Rect.fromLTWH(0, 0, 8, 8),
        ui.Paint()..color = const ui.Color(0xFF0000FF),
      );
      final image = await recorder.endRecording().toImage(8, 8);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      return getDominantColor(MemoryImage(png!.buffer.asUint8List()));
    });
    expect(sampled, const Color(0xFF0000FF));
    expect(tester.takeException(), isNull);
  });
}
