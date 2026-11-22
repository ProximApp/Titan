import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/raffle/router.dart';
import 'package:titan/raffle/tools/functions.dart';
import 'package:titan/raffle/tools/winning_ticket_background_painter.dart';

/// The raffle module's pure tools.
///
/// `raffleStatusTypeToString` is the label every admin card and log line
/// reads, and three of its four arms shipped unchecked: only `creation` was
/// ever exercised. `RaffleRouter.module` carries the all-modules label and
/// description and only resolves inside a localized tree.
///
/// The winning-ticket painter keeps its spheres alive for
/// `Sphere.livingTime` frames and drops the expired ones; the drop arm never
/// ran because no test ever repainted beyond a sphere's lifetime.
void main() {
  group('raffleStatusTypeToString', () {
    test('labels every raffle status, unknown included', () {
      expect(raffleStatusTypeToString(RaffleStatusType.creation), 'creation');
      expect(raffleStatusTypeToString(RaffleStatusType.open), 'open');
      expect(raffleStatusTypeToString(RaffleStatusType.lock), 'lock');
      expect(
        raffleStatusTypeToString(RaffleStatusType.swaggerGeneratedUnknown),
        'error',
      );
    });
  });

  testWidgets('the raffle module metadata resolves in a localized context', (
    tester,
  ) async {
    String? name;
    String? description;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', 'US')],
        home: Builder(
          builder: (context) {
            name = RaffleRouter.module.getName(context);
            description = RaffleRouter.module.getDescription(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(name, isNotEmpty);
    expect(description, isNotEmpty);
    expect(description, isNot(name));
    expect(RaffleRouter.module.root, '/tombola');
  });

  testWidgets('the winning-ticket painter drops a sphere once it expires', (
    tester,
  ) async {
    final animation = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 1),
    );
    addTearDown(animation.dispose);

    final painter = AmapBackgroundPainter(animation: animation);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = ui.Size(400, 400);

    // Every paint adds a sphere with probability 0.15 (before the loop) and
    // ages the spheres it keeps by one tick. Painting until the first sphere
    // a test can see has outlived its livingTime exercises the drop arm
    // deterministically, without depending on how many spheres the random
    // spawn happened to create.
    while (painter.spheres.isEmpty) {
      painter.paint(canvas, size);
    }
    final doomed = painter.spheres.first;
    var dropped = false;
    for (var i = 0; i < 2000 && !dropped; i++) {
      painter.paint(canvas, size);
      dropped = !painter.spheres.contains(doomed);
    }

    expect(
      dropped,
      isTrue,
      reason: 'the sphere outlived its livingTime and was never removed',
    );
  });
}
