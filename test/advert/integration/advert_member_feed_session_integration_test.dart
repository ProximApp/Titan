import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/advert/router.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The member FEED session in one test (convention 19 — one router-pushing
/// test per file): both AdvertCard logo paths (real bytes → CircleAvatar,
/// 404 → placeholder image, initials avatar in the loading window), both
/// poster paths, the long-text expand/collapse with
/// its tappable link recognizer, the pull-to-refresh closure, and the
/// Admin button that chains into the admin page.
/// A genuinely decodable PNG — `fileBytes` feeds `Image.memory`, and raw
/// text (or hand-typed base64) throws `Invalid image data` on paint.
Future<Uint8List> solidPng() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 8, 8),
    Paint()..color = const Color(0xFF00FF00),
  );
  final image = await recorder.endRecording().toImage(8, 8);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

final bde = Association.empty().copyWith(id: 'asso-1', name: 'BDE');
final coop = Association.empty().copyWith(id: 'asso-2', name: 'La Coop');

final longAdvert = AdvertComplete.empty().copyWith(
  id: 'a-1',
  title: '',
  // One single link word long enough to trip the 100-char truncation: the
  // whole paragraph is then one recogniser span, so a tap at the
  // paragraph's centre lands on it (spaces between links could land on a
  // recognizer-less separator span).
  content: 'https://example.org${'x' * 120}',
  advertiserId: 'asso-1',
  date: DateTime(2026, 5, 1),
);

final shortAdvert = AdvertComplete.empty().copyWith(
  id: 'a-2',
  title: 'Week-end',
  content: 'Petite annonce très courte',
  advertiserId: 'asso-2',
  date: null,
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'member feed: card branches, voir plus, link tap, refresh, Admin',
    (tester) async {
      final container = scaffold.makeContainer(myAssociations: [bde]);
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      // Engine work (Picture → PNG) needs real async inside fake-async tests.
      final png = (await tester.runAsync(solidPng))!;

      when(
        () => scaffold.repository.advertAdvertsGet(),
      ).thenAnswer((_) async => chopperListResponse([longAdvert, shortAdvert]));
      when(() => scaffold.repository.associationsGet()).thenAnswer((_) async {
        // Deliberately slow: the card's `when(loading: …)` branch must see
        // at least one frame before the data lands (the virtual clock in
        // tests advances with the pump loop below).
        await Future<void>.delayed(const Duration(milliseconds: 1600));
        return chopperListResponse([bde, coop]);
      });
      when(
        () => scaffold.repository.associationsAssociationIdLogoGet(
          associationId: any(named: 'associationId'),
        ),
      ).thenAnswer((invocation) async {
        final id = invocation.namedArguments[#associationId] as String? ?? '';
        if (id == 'asso-1') {
          return chopper.Response<List<int>>(
            http.Response.bytes(png, 200),
            png,
          );
        }
        // Hyperion answers a missing logo with a 404: fileBytes reads as
        // empty and the card falls back to its placeholder image. (A thrown
        // loader error would not reach the orElseBuilder — MapNotifier's
        // autoLoad does not catch — it would escape as an unhandled async
        // error and fail the test.) The delay outlives the 1600ms
        // associationsGet above, so between the two the bar item and the
        // card paint their orElseBuilder initials avatar with the real
        // association name already loaded.
        await Future<void>.delayed(const Duration(milliseconds: 2000));
        return chopper.Response<List<int>>(
          http.Response('{"detail": "File does not exist"}', 404),
          const [],
          error: 'File does not exist',
        );
      });
      when(
        () => scaffold.repository.advertAdvertsAdvertIdPictureGet(
          advertId: any(named: 'advertId'),
        ),
      ).thenAnswer((invocation) async {
        final id = invocation.namedArguments[#advertId] as String? ?? '';
        if (id == 'a-1') {
          return chopper.Response<List<int>>(
            http.Response.bytes(png, 200),
            png,
          );
        }
        return chopper.Response<List<int>>(
          http.Response('{"detail": "File does not exist"}', 404),
          [],
          error: 'File does not exist',
        );
      });

      final fake = FakeUrlLauncher(launchSucceeds: true);
      stubUrlLauncher(fake);

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: AdvertRouter.root,
        pumpAndSettle: false,
      );
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      // In the window where the association list has landed (1600ms) but
      // the delayed asso-2 logo has not (2000ms), both the bar item and
      // the card show their initials avatar: 'La Coop' → 'LC'.
      var sawInitials = false;
      for (var i = 0; i < 15 && !sawInitials; i++) {
        await tester.pump(const Duration(milliseconds: 80));
        sawInitials = find.text('LC').evaluate().isNotEmpty;
      }
      expect(sawInitials, isTrue);
      await settle(tester, frames: 10);

      // Association bar (the list branch, not the user list).
      expect(find.text('BDE'), findsWidgets);
      // Card 1: long/expandable content with a link; card 2: short content
      // with a null date (the empty date branch).
      expect(
        find.textContaining('https://example.org', findRichText: true),
        findsWidgets,
      );
      expect(
        find.textContaining('Petite annonce', findRichText: true),
        findsWidgets,
      );
      expect(find.text('Week-end'), findsNothing); // inside the RichText
      expect(find.text('voir plus'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Expand: the truncation branch flips and the label toggles.
      await tester.ensureVisible(find.text('voir plus'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('voir plus'));
      await settle(tester);
      expect(find.text('voir moins'), findsOneWidget);

      // The link span's TapGestureRecognizer → openLink.
      final link = find.textContaining(
        'https://example.org',
        findRichText: true,
      );
      await tester.ensureVisible(link);
      await settle(tester, frames: 2);
      await tester.tap(link);
      await settle(tester);
      expect(fake.launched, isNotEmpty);
      expect(fake.launched.first, startsWith('https://example.org'));

      // Pull to refresh: the Refresher onRefresh closure. Scroll back to the
      // top first — a refresh pull only triggers from the top edge.
      final feedScroll = find.textContaining(
        'Petite annonce',
        findRichText: true,
      );
      await tester.drag(feedScroll, const Offset(0, 1500));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await tester.fling(feedScroll, const Offset(0, 300), 1000);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await settle(tester, frames: 10);
      expect(tester.takeException(), isNull);

      // The Admin button (a member sees it) chains into the admin page.
      expect(find.text('Admin'), findsOneWidget);
      await tester.ensureVisible(find.text('Admin'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Admin'));
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await settle(tester, frames: 10);
      expect(find.text('Post'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
