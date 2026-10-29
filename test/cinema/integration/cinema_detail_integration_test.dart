import 'dart:convert';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Message;
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncValue;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/cinema/providers/session_poster_map_provider.dart';
import 'package:titan/cinema/providers/session_provider.dart';
import 'package:titan/cinema/router.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The detail page's own branches: genre chips, the empty-synopsis
/// fallback, the poster's two load outcomes and — the biggest untouched
/// block in `cinema` — the reminder bell's two arms (schedule / cancel),
/// which nothing had ever tapped.
///
/// Every test in this file deep-links the SAME path (convention 10).
CineSessionComplete session({required String overview, String? genre}) =>
    CineSessionComplete.empty().copyWith(
      id: 'c-1',
      name: 'Blade Runner',
      overview: overview,
      genre: genre,
      start: DateTime.now().add(const Duration(days: 3)),
      duration: 7200,
    );

/// A valid 1x1 PNG: the codec crashes on invalid image bytes.
final posterPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    // No test environment registers the plugin's platform implementation, so
    // the bell tap would die in `resolvePlatformSpecificImplementation` before
    // reaching the mocked channel (same registration as the service tests).
    AndroidFlutterLocalNotificationsPlugin.registerWith();
  });

  /// The session list endpoint is stubbed for the route table even though
  /// only the detail page renders, and both topic-subscription posts are
  /// stubbed because `toggleSubscription` picks one of them by list
  /// membership — a field-for-field match on the whole `TopicUser`.
  void stubCommon({required List<TopicUser> topics}) {
    when(() => scaffold.repository.cinemaSessionsGet()).thenAnswer(
      (_) async => chopperListResponse(const <CineSessionComplete>[]),
    );
    when(() => scaffold.repository.notificationTopicsGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('[]', 200), topics),
    );
    when(
      () => scaffold.repository.notificationTopicsTopicIdSubscribePost(
        topicId: any(named: 'topicId'),
      ),
    ).thenAnswer((_) async => scaffold.repository.okVoid());
    when(
      () => scaffold.repository.notificationTopicsTopicIdUnsubscribePost(
        topicId: any(named: 'topicId'),
      ),
    ).thenAnswer((_) async => scaffold.repository.okVoid());
  }

  testWidgets('deep link to /cinema/detail renders the pre-selected session', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    when(() => scaffold.repository.cinemaSessionsGet()).thenAnswer(
      (_) async => chopperListResponse(const <CineSessionComplete>[]),
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

    // The detail page renders from client-side state set by the list.
    container
        .read(sessionProvider.notifier)
        .setSession(
          CineSessionComplete.empty().copyWith(
            id: 'c-1',
            name: 'Blade Runner',
            overview: 'A heart-warming tale of replicants',
            start: DateTime(2026, 11, 5, 20, 30),
            duration: 8400,
          ),
        );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${CinemaRouter.root}${CinemaRouter.detail}',
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.text('Blade Runner'), findsOneWidget);
    expect(find.textContaining('A heart-warming tale'), findsOneWidget);
  });

  testWidgets(
    'a subscribed session shows its genres, no synopsis and the armed reminder',
    (tester) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      final notificationCalls = stubLocalNotificationsChannel();
      stubCommon(
        topics: [
          TopicUser.empty().copyWith(
            id: 'c-1',
            name: 'Blade Runner',
            moduleRoot: 'cinema',
            topicIdentifier: 'c-1',
            isUserSubscribed: true,
          ),
        ],
      );
      // A failed poster fetch is the AutoLoaderChild error arm.
      container
          .read(sessionPosterMapProvider.notifier)
          .setTData(
            'c-1',
            AsyncValue.error('poster unavailable', StackTrace.empty),
          );
      container
          .read(sessionProvider.notifier)
          .setSession(session(overview: '', genre: 'Drama, Sci-Fi'));

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '${CinemaRouter.root}${CinemaRouter.detail}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // genre != null → the split runs and the chips render.
      expect(find.text('Drama'), findsOneWidget);
      expect(find.text('Sci-Fi'), findsOneWidget);
      // Empty overview → the localized fallback.
      expect(find.text('No synopsis'), findsOneWidget);
      // The topics list holds this session, so the bell is armed.
      expect(find.textContaining('Supprimer le rappel'), findsOneWidget);

      await tester.tap(find.textContaining('Supprimer le rappel'));
      await settle(tester, frames: 12);

      // `selected` is true → the cancel arm ran.
      expect(notificationCalls.map((call) => call.method), contains('cancel'));
      expect(tester.takeException(), isNull);

      await scaffold.unmountApp(tester);
      await scaffold.drainToast(tester);
    },
  );

  testWidgets(
    'an unsubscribed session schedules the reminder and keeps its poster bytes',
    (tester) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      final notificationCalls = stubLocalNotificationsChannel();
      stubCommon(topics: const []);
      // Non-empty bytes → `getLogo` takes the Image.memory arm.
      when(
        () => scaffold.repository.cinemaSessionsSessionIdPosterGet(
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response<List<int>>(
          http.Response.bytes(posterPng, 200),
          posterPng,
        ),
      );
      container
          .read(sessionProvider.notifier)
          .setSession(session(overview: 'Chase the androids.'));

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '${CinemaRouter.root}${CinemaRouter.detail}',
        pumpAndSettle: false,
      );
      await settle(tester);

      expect(find.textContaining('Chase the androids'), findsOneWidget);
      expect(find.textContaining('Ajouter un rappel'), findsOneWidget);

      await tester.tap(find.textContaining('Ajouter un rappel'));
      await settle(tester, frames: 12);

      // `selected` is false → the schedule arm ran.
      expect(notificationCalls.map((call) => call.method), contains('show'));
      expect(tester.takeException(), isNull);

      await scaffold.unmountApp(tester);
      await scaffold.drainToast(tester);
    },
  );
}
