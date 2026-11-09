import 'dart:convert';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/ph/router.dart';
import 'package:titan/ph/ui/pages/past_ph_selection_page/ph_card.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/layouts/card_button.dart';

import '../../shared/app_scaffold.dart';
import '../ph_fixtures.dart';

/// The card's download button against a pdf that CAN be fetched: the bytes go
/// to the save dialog and the card announces the save.
///
/// `downloadFile` picks `saveAs` on macOS and calls it through a pigeon
/// channel, so answering that channel is the seam — the real routing runs and
/// only the plugin's reply is replaced. (The failing half lives in
/// `ph_card_download_integration_test.dart`.)
///
/// A valid 1x1 PNG: PhCard renders the cover bytes as an Image.memory, and
/// invalid image data crashes the codec.
final coverPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// The download button is `GestureDetector > CardButton > HeroIcon` with the
/// tray icon; matching on the icon keeps the finder off the card itself.
Finder downloadButton() => find.byWidgetPredicate(
  (w) =>
      w is GestureDetector &&
      w.child is CardButton &&
      (w.child as CardButton).child is HeroIcon &&
      ((w.child as CardButton).child as HeroIcon).icon ==
          HeroIcons.arrowDownTray,
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('a fetched pdf is handed to the save dialog and announced', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);

    when(() => scaffold.repository.phGet()).thenAnswer(
      (_) async => chopperListResponse(<PaperComplete>[
        paperFixture('p1', 'Journal April', 2026, 4),
      ]),
    );
    when(
      () =>
          scaffold.repository.phPaperIdCoverGet(paperId: any(named: 'paperId')),
    ).thenAnswer(
      (_) async => chopper.Response<List<int>>(
        http.Response.bytes(coverPng, 200),
        coverPng,
      ),
    );
    when(
      () => scaffold.repository.phPaperIdPdfGet(paperId: any(named: 'paperId')),
    ).thenAnswer(
      (_) async => chopper.Response<List<int>>(
        http.Response.bytes(Uint8List.fromList([1, 2, 3]), 200),
        Uint8List.fromList([1, 2, 3]),
      ),
    );

    const saveAsChannel =
        'dev.flutter.pigeon.file_saver.FileSaverHostApi.saveAs';
    var saveCalls = 0;
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(saveAsChannel, (
      message,
    ) async {
      saveCalls++;
      return const StandardMessageCodec().encodeMessage(<Object?>[
        '/tmp/Journal April.pdf',
      ]);
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        saveAsChannel,
        null,
      ),
    );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${PhRouter.root}${PhRouter.past_ph_selection}',
      pumpAndSettle: false,
    );
    await settle(tester);
    expect(find.byType(PhCard), findsOneWidget);

    // The card sits below the 1080px test viewport — bring the button on
    // screen before tapping or the hit test misses.
    await tester.ensureVisible(downloadButton());
    await tester.pump();
    await tester.tap(downloadButton());
    await settle(tester, frames: 20);

    expect(saveCalls, 1);
    expect(find.text('Successfully downloaded'), findsOneWidget);
    // Drain the success toast (autoClose 2500ms + 400ms animation).
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
