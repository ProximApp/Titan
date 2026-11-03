import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/cinema/router.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../cinema_fixtures.dart';

/// The cinema admin gate is a plain Provider over userProvider.groups, so
/// the signed-in user carries the admin_cinema group id.
const adminCinemaGroupId = 'ce5f36e6-5377-489f-9696-de70e2477300';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    // The edit form's Poster URL fetch goes through package:http; without a
    // stub the binding answers 400 with an empty body and Image.memory dies.
    stubNetworkImages();
  });

  testWidgets(
    'the session card pencil opens the prefilled edit form and saves through the real PATCH',
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
      when(() => scaffold.repository.cinemaSessionsGet()).thenAnswer(
        (_) async => chopperListResponse([
          shortSession(
            'c-1',
            'Blade Runner',
            genre: 'Science fiction',
            tagline: 'The future is now',
          ),
        ]),
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
      CineSessionUpdate? capturedEdit;
      String? capturedSessionId;
      when(
        () => scaffold.repository.cinemaSessionsSessionIdPatch(
          sessionId: any(named: 'sessionId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((inv) async {
        capturedEdit = inv.namedArguments[#body] as CineSessionUpdate;
        capturedSessionId = inv.namedArguments[#sessionId] as String;
        return chopperResponse(
          shortSession(
            'c-1',
            'Blade Runner 2049',
            genre: 'Science fiction',
            tagline: 'The future is now',
          ),
        );
      });

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '${CinemaRouter.root}${CinemaRouter.admin}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // The admin card's pencil navigates to the edit page (deferred route:
      // poll). HeroIcons is the app's custom enum, not IconData: find the
      // HeroIcon widget by its icon field.
      await tester.tap(
        find
            .byWidgetPredicate(
              (w) => w is HeroIcon && w.icon == HeroIcons.pencil,
            )
            .first,
        warnIfMissed: false,
      );
      for (
        var i = 0;
        i < 20 && find.text('Edit the session').evaluate().isEmpty;
        i++
      ) {
        await settle(tester, frames: 4);
      }
      expect(find.text('Edit the session'), findsOneWidget);
      // Edit mode: the form is prefilled from the tapped session.
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Name').first)
            .controller!
            .text,
        'Blade Runner',
      );
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Duration').first)
            .controller!
            .text,
        '02:00',
      );

      // Rename, then pick a NEW poster through the Poster URL field: that is
      // what fills `logo.value`, and a successful edit only uploads the bytes
      // when it is non-null (`logo.value != null` → autoLoad the update). The
      // seeded map poster alone satisfies the gate but uploads nothing.
      await tester.enterText(
        find.widgetWithText(TextField, 'Name').first,
        'Blade Runner 2049',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Poster URL (Optional)').first,
        'https://image.tmdb.org/p/dune.png',
      );
      await settle(tester, frames: 4);
      await tester.dragUntilVisible(
        find.text('Edit'),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await settle(tester, frames: 2);
      await tester.tap(find.text('Edit'));
      await settle(tester, frames: 12);

      // The real PATCH fired for the right session with the new name.
      expect(capturedEdit, isNotNull);
      expect(capturedEdit!.name, 'Blade Runner 2049');
      expect(capturedSessionId, 'c-1');
      // The new poster went up under the edited session's id.
      verify(
        () => scaffold.repository.cinemaSessionsSessionIdPosterPost(
          sessionId: 'c-1',
          image: any(named: 'image'),
        ),
      ).called(1);
      // Back on the admin page with the success toast; drain it.
      expect(find.text('Session edited'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
