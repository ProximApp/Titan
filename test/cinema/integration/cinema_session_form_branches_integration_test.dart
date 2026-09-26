import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/cinema/providers/session_provider.dart';
import 'package:titan/cinema/router.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/builders/waiting_button.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// AddEditSessionPage's uncovered halves, deep-linked directly (one path
/// for the whole file, README convention 1):
///
///  - the TMDB import button: empty-URL toast, invalid-host FormatException
///    toast, the data arm that fills every field AND fetches the poster
///    through `getFromUrl` (stubNetworkImages serves a decodable pixel PNG
///    so `Image.memory(logo.value)` paints instead of crashing the codec),
///    and the movie-load error toast,
///  - the save handler's two gates (failed validate → "Incorrect or missing
///    fields", no poster at all → "No poster") and both error arms
///    ("Error while adding" / "Error while editing").
///
/// The happy POST/PATCH paths and the seeded-poster-map branch live in
/// cinema_add_session / cinema_edit_session; this file drives the poster
/// through the Poster URL field's onChanged instead, which also covers the
/// fetch line those files avoid (a bare test binding answers HTTP with an
/// empty 400 body — stubNetworkImages replaces that).
const adminCinemaGroupId = 'ce5f36e6-5377-489f-9696-de70e2477300';

CineSessionComplete session(String id, String name) =>
    CineSessionComplete.empty().copyWith(
      id: id,
      name: name,
      overview: 'A heart-warming tale of $name',
      start: DateTime(2026, 12, 18, 20),
      // Minutes: parseDurationBack renders 120 as "02:00".
      duration: 120,
    );

TheMovieDB movie() => TheMovieDB(
  genres: const ['Science fiction', 'Thriller'],
  overview: 'A desert planet epic',
  posterPath: 'https://image.tmdb.org/p/dune.png',
  title: 'Dune',
  // Minutes: parseDurationBack renders 136 as "02:16".
  runtime: 136,
  tagline: 'The power to fear',
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    // The form's poster fetches (TMDB data arm, Poster URL onChanged) go
    // through package:http; without this the binding answers 400 with an
    // empty body and Image.memory dies on the undecodable bytes.
    stubNetworkImages();
  });

  ProviderContainer makeAdminContainer() {
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
    return container;
  }

  /// The form's own GET plus the card posters the admin parent fetches.
  void stubSessions({List<CineSessionComplete> sessions = const []}) {
    when(() => scaffold.repository.cinemaSessionsGet())
        .thenAnswer((_) async => chopperListResponse(sessions));
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
  }

  Future<void> pumpForm(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${CinemaRouter.root}${CinemaRouter.admin}${CinemaRouter.addEdit}',
      pumpAndSettle: false,
    );
    await settle(tester);
  }

  Future<void> expectToast(WidgetTester tester, String text) async {
    expect(find.text(text, skipOffstage: false), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  }

  String nameValue(WidgetTester tester) => tester
      .widget<TextField>(find.widgetWithText(TextField, 'Name').first)
      .controller!
      .text;

  /// The Poster URL field's onChanged fetches bytes into logo.value; the
  /// save handler's no-poster gate needs it non-null. TextEntry renders
  /// canBeEmpty labels through globalOptionnal → "… (Optional)".
  Future<void> fetchPoster(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextField, 'Poster URL (Optional)').first,
      'https://image.tmdb.org/p/dune.png',
    );
    await settle(tester, frames: 4);
  }

  Future<void> fillRequired(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextField, 'Name').first,
      'Dune',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Session day').first,
      '12/18/2026 20:00',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Duration').first,
      '02:00',
    );
  }

  testWidgets(
    'the TMDB button toasts both bad-URL arms and fills the form on a good one',
    (tester) async {
      stubSessions();
      when(
        () => scaffold.repository.cinemaThemoviedbThemoviedbIdGet(
          themoviedbId: any(named: 'themoviedbId'),
        ),
      ).thenAnswer((_) async => chopperResponse(movie()));
      final container = makeAdminContainer();

      await pumpForm(tester, container);

      final arrow = find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.arrowRight,
      );
      final tmdbField = find.widgetWithText(TextField, 'Import from TMDB');

      // Empty URL → the guard toast, no movie call.
      await tester.ensureVisible(arrow);
      await tester.tap(arrow);
      await settle(tester, frames: 4);
      await expectToast(tester, 'Please enter a URL');
      verifyNever(
        () => scaffold.repository.cinemaThemoviedbThemoviedbIdGet(
          themoviedbId: any(named: 'themoviedbId'),
        ),
      );

      // A host outside the switch → FormatException → invalid toast.
      await tester.enterText(tmdbField, 'https://example.com/movie/1');
      await tester.ensureVisible(arrow);
      await tester.tap(arrow);
      await settle(tester, frames: 4);
      await expectToast(tester, 'Invalid URL');

      // A real TMDB URL: every field fills and the poster paints.
      await tester.enterText(
        tmdbField,
        'https://www.themoviedb.org/movie/603-dune',
      );
      await tester.ensureVisible(arrow);
      await tester.tap(arrow);
      await settle(tester, frames: 8);

      verify(
        () => scaffold.repository.cinemaThemoviedbThemoviedbIdGet(
          themoviedbId: '603-dune',
        ),
      ).called(1);
      expect(nameValue(tester), 'Dune');
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Duration').first)
            .controller!
            .text,
        '02:16',
      );
      expect(
        tester
            .widget<TextField>(
              find.widgetWithText(TextField, 'Poster URL (Optional)').first,
            )
            .controller!
            .text,
        'https://image.tmdb.org/p/dune.png',
      );
      // logo.value holds fetched bytes → the Image.memory branch paints.
      expect(find.byType(Image), findsOneWidget);

      // The movie-load error arm toasts the exception text.
      when(
        () => scaffold.repository.cinemaThemoviedbThemoviedbIdGet(
          themoviedbId: any(named: 'themoviedbId'),
        ),
      ).thenThrow(Exception('tmdb down'));
      await tester.enterText(
        tmdbField,
        'https://www.themoviedb.org/movie/604-dune2',
      );
      await tester.ensureVisible(arrow);
      await tester.tap(arrow);
      await settle(tester, frames: 8);
      await expectToast(tester, 'Exception: tmdb down');

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the save handler toasts the validation and no-poster gates', (
    tester,
  ) async {
    stubSessions();
    final container = makeAdminContainer();

    await pumpForm(tester, container);

    final save = find.widgetWithText(WaitingButton, 'Add');

    // Empty required fields → validate() fails.
    await tester.ensureVisible(save);
    await tester.tap(save);
    await settle(tester, frames: 4);
    await expectToast(tester, 'Incorrect or missing fields');

    // Everything filled but the poster → the second gate.
    await fillRequired(tester);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await settle(tester, frames: 4);
    await expectToast(tester, 'No poster');

    verifyNever(
      () => scaffold.repository.cinemaSessionsPost(body: any(named: 'body')),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a successful create uploads the poster onto the list tail and toasts',
    (tester) async {
      stubSessions(sessions: [session('c-1', 'Blade Runner')]);
      when(
        () => scaffold.repository.cinemaSessionsPost(body: any(named: 'body')),
      ).thenAnswer((_) async => chopperResponse(session('c-new', 'Dune')));
      when(
        () => scaffold.repository.cinemaSessionsSessionIdPosterPost(
          sessionId: any(named: 'sessionId'),
          image: any(named: 'image'),
        ),
      ).thenAnswer(
        (_) async => chopperResponse(AppTypesStandardResponsesResult.empty()),
      );
      final container = makeAdminContainer();

      await pumpForm(tester, container);

      await fetchPoster(tester);
      await fillRequired(tester);
      final save = find.widgetWithText(WaitingButton, 'Add');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await settle(tester, frames: 8);

      verify(
        () => scaffold.repository.cinemaSessionsPost(body: any(named: 'body')),
      ).called(1);
      // The maybeWhen closes over the list AS IT WAS AT BUILD TIME, so the
      // logo upload targets the pre-existing tail (c-1), not the POSTed
      // c-new — pinning the actual behaviour, not the intent.
      verify(
        () => scaffold.repository.cinemaSessionsSessionIdPosterPost(
          sessionId: 'c-1',
          image: any(named: 'image'),
        ),
      ).called(1);
      await expectToast(tester, 'Session added');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a failed create toasts the adding error', (tester) async {
    stubSessions(sessions: [session('c-1', 'Blade Runner')]);
    when(() => scaffold.repository.cinemaSessionsPost(body: any(named: 'body')))
        .thenThrow(Exception('post failed'));
    final container = makeAdminContainer();

    await pumpForm(tester, container);

    await fetchPoster(tester);
    await fillRequired(tester);
    final save = find.widgetWithText(WaitingButton, 'Add');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await settle(tester, frames: 8);

    await expectToast(tester, 'Error while adding');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed edit toasts the editing error', (tester) async {
    stubSessions(sessions: [session('c-1', 'Blade Runner')]);
    when(
      () => scaffold.repository.cinemaSessionsSessionIdPatch(
        sessionId: any(named: 'sessionId'),
        body: any(named: 'body'),
      ),
    ).thenThrow(Exception('patch failed'));
    final container = makeAdminContainer();
    // Edit mode: the form reads the session the admin card would have
    // seeded before navigating.
    container
        .read(sessionProvider.notifier)
        .setSession(session('c-1', 'Blade Runner'));

    await pumpForm(tester, container);

    expect(find.text('Edit the session'), findsOneWidget);
    // Edit mode prefills every required field; only the poster gate needs
    // feeding before the save reaches the PATCH.
    await fetchPoster(tester);
    final save = find.widgetWithText(WaitingButton, 'Edit');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await settle(tester, frames: 8);

    await expectToast(tester, 'Error while editing');
    expect(tester.takeException(), isNull);
  });
}
