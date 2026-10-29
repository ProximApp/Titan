import 'dart:convert';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
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

/// The card's download button against a pdf that cannot be fetched: the
/// `await phPdf` inside the tap throws into the catch, which toasts instead
/// of reaching file_saver (whose native save dialog does not exist in
/// tests). The /ph main page underneath carries the same failing provider
/// into its own AsyncChild error text — a different string from the toast's
/// bare exception, so the assertions stay unambiguous.
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

  testWidgets('a failing pdf download toasts instead of saving', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);

    when(() => scaffold.repository.phGet()).thenAnswer(
      (_) async => chopperListResponse(<PaperComplete>[
        paperFixture('p1', 'Journal March', 2026, 3),
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
    ).thenThrow(Exception('pdf unavailable'));

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

    // `await phPdf` only rejects once Riverpod's default build-retry backoff
    // (10 retries, 200ms→6.4s ≈ 31.6s total) exhausts the mocked failure and
    // the provider settles into a terminal AsyncError. Jump the fake clock
    // past the whole chain so the catch can toast.
    await tester.pump(const Duration(seconds: 40));
    await settle(tester);

    expect(find.text('Exception: pdf unavailable'), findsOneWidget);
    // Drain the error toast (autoClose 2500ms + 400ms animation).
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
