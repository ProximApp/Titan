import 'dart:convert';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/cinema/providers/session_poster_map_provider.dart';
import 'package:titan/cinema/router.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The cinema admin gate is a plain Provider over userProvider.groups, so
/// the signed-in user carries the admin_cinema group id.
const adminCinemaGroupId = 'ce5f36e6-5377-489f-9696-de70e2477300';

/// A valid 1x1 PNG: the codec crashes on invalid image bytes.
final posterPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

CineSessionComplete session(String id, String name) =>
    CineSessionComplete.empty().copyWith(
      id: id,
      name: name,
      overview: 'A heart-warming tale of $name',
      start: DateTime(2026, 12, 18, 20),
      duration: 7200,
    );

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'the admin + card opens the session form and creates one through the real cinemaSessionsPost',
    (tester) async {
      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(
          groups: [
            CoreGroupSimple.empty().copyWith(
              id: adminCinemaGroupId,
              name: 'admin_cinema',
            ),
          ],
        ),
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      // AdminSessionCard ships with a 1px vertical overflow in its fixed-
      // height button row (same class as LoanCard/BookingCard); swallow
      // exactly that, anything else stays fatal.
      scaffold.absorbLayoutOverflows(tester);
      when(() => scaffold.repository.cinemaSessionsGet()).thenAnswer(
        (_) async => chopperListResponse([session('c-1', 'Blade Runner')]),
      );
      when(
        () => scaffold.repository.cinemaSessionsSessionIdPosterGet(
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response<List<int>>(
          http.Response('{"detail": "File does not exist"}', 404),
          [],
          error: 'File does not exist',
        ),
      );
      // The form's no-poster gate reads the poster map for the create-mode
      // session id (""). Pre-seeding it stands in for the picked/fetched
      // poster bytes the real flow produces; feeding the Poster URL field
      // instead would need a live HTTP fetch, which the test binding always
      // answers with an empty 400 body (undecodable).
      container
          .read(sessionPosterMapProvider.notifier)
          .setTData('', AsyncData([Image.memory(posterPng)]));
      CineSessionBase? capturedSession;
      when(
        () => scaffold.repository.cinemaSessionsPost(body: any(named: 'body')),
      ).thenAnswer((inv) async {
        capturedSession = inv.namedArguments[#body] as CineSessionBase;
        return chopperResponse(
          session('c-new', 'Blade Runner').copyWith(id: 'c-new'),
        );
      });

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '${CinemaRouter.root}${CinemaRouter.admin}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // The admin page renders its + card and the existing session card.
      expect(find.text('Blade Runner'), findsOneWidget);

      // The + card navigates to the add-edit page (deferred route: poll).
      // HeroIcons is the app's custom enum, not IconData: find the HeroIcon
      // widget by its icon field.
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.plus,
        ),
      );
      for (
        var i = 0;
        i < 20 && find.text('Add a session').evaluate().isEmpty;
        i++
      ) {
        await settle(tester, frames: 4);
      }
      expect(find.text('Add a session'), findsOneWidget);
      // Create mode: the name field is empty.
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Name').first)
            .controller!
            .text,
        '',
      );

      // Fill the required fields. The poster comes from the pre-seeded map
      // (see above), which satisfies the no-poster gate on submit.
      await tester.enterText(
        find.widgetWithText(TextField, 'Name').first,
        'Akira',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Session day').first,
        '12/18/2026 20:00',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Duration').first,
        '02:00',
      );
      await settle(tester, frames: 4);

      // Submit: the real POST fires with the form values and the page pops
      // back to the admin page with the success toast. The submit button
      // sits below the fold — scroll it into view first.
      await tester.dragUntilVisible(
        find.text('Add'),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await settle(tester, frames: 2);
      await tester.tap(find.text('Add'));
      await settle(tester, frames: 12);

      expect(capturedSession, isNotNull);
      expect(capturedSession!.name, 'Akira');
      expect(capturedSession!.start.year, 2026);
      expect(capturedSession!.start.month, 12);
      expect(capturedSession!.duration, 120);
      // Back on the admin page with the success toast.
      expect(find.text('Session added'), findsOneWidget);
      // Drain the toast timer.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
