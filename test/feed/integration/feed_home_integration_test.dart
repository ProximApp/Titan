import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';
import 'package:qlevar_router/qlevar_router.dart';

import '../../shared/app_scaffold.dart';
import '../../event/event_test_doubles.dart';

/// The feed timeline hosts EventAction countdowns that schedule a repeating
/// 1-second timer, so pumpAndSettle would time out; pumps are bounded
/// instead.
///
/// Hero icons are enum values drawn as SVG, so a button carrying one is
/// found through the [HeroIcon] child rather than `find.byIcon`.
Finder heroButton(HeroIcons icon, {required Type wrapper}) => find
    .ancestor(
      of: find.byWidgetPredicate((w) => w is HeroIcon && w.icon == icon),
      matching: find.byType(wrapper),
    )
    .first;
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  group('Feed main page', () {
    testWidgets(
      'a signed-in user sees the news timeline with titles and status badges',
      (tester) async {
        final now = DateTime.now();
        when(() => scaffold.repository.feedNewsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), [
            News.empty().copyWith(
              id: 'n-1',
              title: 'Soirée des clubs',
              module: 'event',
              entity: 'BDE',
              start: now.add(const Duration(days: 3)),
            ),
            News.empty().copyWith(
              id: 'n-2',
              title: 'Week-end intégration',
              module: 'advert',
              entity: 'BDE',
              start: now.subtract(const Duration(days: 1)),
              end: now.add(const Duration(days: 1)),
            ),
          ]),
        );

        await scaffold.pumpApp(
          tester,
          scaffold.makeContainer(),
          initialPath: '/feed',
        );
        await settle(tester, frames: 8);

        // Both cards render (the timeline sorts them by start date).
        expect(find.text('Soirée des clubs'), findsOneWidget);
        expect(find.text('Week-end intégration'), findsOneWidget);
        // The still-running news shows the "Until …" subtitle; MaterialApp
        // resolves en_US (first supported locale), not the fr_FR default of
        // the locale notifier.
        expect(find.textContaining('Until'), findsOneWidget);
        expect(find.text('Ended'), findsNothing);
      },
    );

    testWidgets('an empty feed shows the empty state', (tester) async {
      when(() => scaffold.repository.feedNewsGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), <News>[]),
      );

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(),
        initialPath: '/feed',
      );
      await settle(tester);

      expect(find.text('No news available'), findsOneWidget);
    });

    testWidgets('a terminated news is flagged "Ended"', (tester) async {
      final now = DateTime.now();
      when(() => scaffold.repository.feedNewsGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), [
          News.empty().copyWith(
            id: 'n-1',
            title: 'Ancienne soirée',
            module: 'event',
            entity: 'BDE',
            start: now.subtract(const Duration(days: 3)),
            end: now.subtract(const Duration(days: 2)),
          ),
        ]),
      );

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(),
        initialPath: '/feed',
      );
      await settle(tester, frames: 6);

      expect(find.text('Ended'), findsOneWidget);
      expect(find.text('Ongoing'), findsNothing);
    });

    testWidgets(
      'a regular user without associations gets no admin entry point',
      (tester) async {
        when(() => scaffold.repository.feedNewsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), <News>[]),
        );
        when(() => scaffold.repository.associationsMeGet()).thenAnswer(
          (_) async =>
              chopper.Response(http.Response('body', 200), <Association>[]),
        );

        await scaffold.pumpApp(
          tester,
          scaffold.makeContainer(),
          initialPath: '/feed',
        );
        await settle(tester);

        // The admin button only appears for feed admins or association
        // members; CoreUser.empty() has no groups and no associations.
        expect(find.text('Administration'), findsNothing);
      },
    );

    // A tall timeline whose sort hits every same-start tiebreak (both ends
    // null, one null in each comparison order, both set) and which carries
    // one running countdown, so the auto-scroll loop computes per-item
    // heights of both kinds.
    List<News> scrollingNews() {
      final now = DateTime.now();
      News item(
        String id, {
        required DateTime start,
        DateTime? end,
        DateTime? actionStart,
      }) => News.empty().copyWith(
        id: id,
        title: 'News $id',
        module: 'event',
        entity: 'BDE',
        start: start,
        end: end,
        actionStart: actionStart,
      );

      final past4 = now.subtract(const Duration(days: 4));
      final past3 = now.subtract(const Duration(days: 3));
      final past2 = now.subtract(const Duration(days: 2));
      final past1 = now.subtract(const Duration(days: 1));
      return [
        // Both ends null: the tie keeps the input order; w1's countdown
        // makes its card the tall (200px) kind for the scroll accumulator.
        item('w1', start: past4, actionStart: past4),
        item('w2', start: past4),
        // [end, null] input order: the null end sorts first.
        item('q1', start: past3, end: now.add(const Duration(days: 2))),
        item('q2', start: past3),
        // [null, end] input order: the reversed comparison branch.
        item('y2', start: past2),
        item('y1', start: past2, end: now.add(const Duration(days: 1))),
        // Both ends set: compareTo.
        item('z1', start: past1, end: now.add(const Duration(days: 3))),
        item('z2', start: past1, end: now.add(const Duration(days: 4))),
      ];
    }

    testWidgets(
      'the feed auto-scrolls past finished news and taps land on items',
      (tester) async {
        when(() => scaffold.repository.feedNewsGet()).thenAnswer(
          (_) async =>
              chopper.Response(http.Response('body', 200), scrollingNews()),
        );

        await scaffold.pumpApp(
          tester,
          scaffold.makeContainer(),
          initialPath: '/feed',
        );
        await settle(tester, frames: 10);

        // The post-frame effect finds the first still-relevant item (q1,
        // the third after sorting) and accumulates the three cards before
        // it: 200 (countdown card) + 160 + 160 = 520.
        final scroller = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView).first,
        );
        expect(scroller.controller!.position.pixels, 520);
        // The scrolled-past card sits above the viewport; a mid-list card
        // is on screen and its tap reaches FeedTimeline's onItemTap.
        expect(tester.getTopLeft(find.text('News w1')).dy, lessThan(0));
        await tester.tap(find.text('News y1'));
        await settle(tester, frames: 2);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('the refresh pill reloads the news list', (tester) async {
      var fetches = 0;
      when(() => scaffold.repository.feedNewsGet()).thenAnswer((_) async {
        fetches++;
        return chopper.Response(http.Response('body', 200), scrollingNews());
      });

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(),
        initialPath: '/feed',
      );
      await settle(tester, frames: 10);

      // The pill gates the upward-scroll count on DateTime.now(), which runs
      // on the REAL clock — the >50ms gaps need runAsync, not pump.
      Future<void> realDelay([int ms = 60]) => tester.runAsync(
        () => Future<void>.delayed(Duration(milliseconds: ms)),
      );

      // Two consecutive upward flings reveal the pill (the auto-scroll
      // already armed the 200px floor).
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 120),
      );
      await realDelay();
      await settle(tester, frames: 2);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 120),
      );
      await realDelay();
      await settle(tester, frames: 10);
      expect(find.text('Refresh'), findsOneWidget);

      final beforeTap = fetches;
      await tester.tap(find.text('Refresh'));
      await settle(tester, frames: 10);
      // handleRefresh reloads the list (the pill itself may re-arm while
      // the reloaded content re-clamps the scroll position, so only the
      // reload is asserted).
      expect(fetches, greaterThan(beforeTap));
    });

    testWidgets('the filter button opens the news filter modal', (
      tester,
    ) async {
      when(() => scaffold.repository.feedNewsGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), [
          News.empty().copyWith(
            id: 'n-1',
            title: 'Soirée des clubs',
            module: 'event',
            entity: 'BDE',
            start: DateTime.now().add(const Duration(days: 3)),
          ),
        ]),
      );

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(),
        initialPath: '/feed',
      );
      await settle(tester, frames: 8);

      // The onPressed derives the entity/module sets from the loaded news.
      await tester.tap(
        heroButton(HeroIcons.adjustmentsHorizontal, wrapper: IconButton),
      );
      await settle(tester, frames: 8);
      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);

      await tester.tap(find.text('Apply'));
      await settle(tester, frames: 8);
      expect(find.text('Filter'), findsNothing);
    });

    testWidgets('a feed admin without associations jumps to event management', (
      tester,
    ) async {
      when(() => scaffold.repository.feedNewsGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), <News>[]),
      );
      when(() => scaffold.repository.feedAdminNewsGet())
          .thenAnswer((_) async => chopperListResponse(<News>[]));

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(
          user: CoreUser.empty().copyWith(
            groups: [
              CoreGroupSimple.empty().copyWith(
                id: '59e3c4c2-e60f-44b6-b0d2-fa1b248423bb', // admin_feed
              ),
            ],
          ),
        ),
        initialPath: '/feed',
      );
      await settle(tester, frames: 8);

      // Admin-only: the user-group icon routes straight to the handling
      // page, no modal in between.
      final navigation = RecordingRouteMock();
      QR.settings.mockRoute = navigation;
      addTearDown(() => QR.settings.mockRoute = null);
      await tester.tap(
        heroButton(HeroIcons.userGroup, wrapper: CustomIconButton),
      );
      await settle(tester, frames: 12);
      // Admin-only: the user-group icon routes straight to the handling
      // page, no modal in between. The destination page is covered by its
      // own integration test; qlevar cannot mount a second page from a
      // later test of this file, so the route is recorded instead.
      expect(navigation.navigated, contains('/feed/event_handling'));
    });

    testWidgets(
      'an association member opens the admin modal and creates an event',
      (tester) async {
        when(() => scaffold.repository.feedNewsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), <News>[]),
        );

        await scaffold.pumpApp(
          tester,
          scaffold.makeContainer(
            myAssociations: [
              Association(name: 'BDE', groupId: 'g-1', id: 'a-1'),
            ],
          ),
          initialPath: '/feed',
        );
        await settle(tester, frames: 8);

        await tester.tap(
          heroButton(HeroIcons.pencil, wrapper: CustomIconButton),
        );
        await settle(tester, frames: 8);
        expect(find.text('Administration'), findsOneWidget);
        expect(find.text('Create an event'), findsOneWidget);
        expect(find.text('Manage association events'), findsOneWidget);
        // The requests entry is admin-only.
        expect(find.text('Manage requests'), findsNothing);

        final navigation = RecordingRouteMock();
        QR.settings.mockRoute = navigation;
        addTearDown(() => QR.settings.mockRoute = null);
        await tester.tap(find.text('Create an event'));
        await settle(tester, frames: 8);
        // The modal popped and the router was asked for the add/edit page
        // (whose own test file covers the mounted form).
        expect(navigation.navigated, contains('/feed/add_edit_event'));
        expect(find.text('Administration'), findsNothing);
      },
    );

    testWidgets(
      'manage association events loads the first association and navigates',
      (tester) async {
        when(() => scaffold.repository.feedNewsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), <News>[]),
        );
        await scaffold.pumpApp(
          tester,
          scaffold.makeContainer(
            myAssociations: [
              Association(name: 'BDE', groupId: 'g-1', id: 'a-1'),
              Association(name: 'PACES', groupId: 'g-2', id: 'a-2'),
            ],
          ),
          initialPath: '/feed',
        );
        await settle(tester, frames: 8);

        await tester.tap(
          heroButton(HeroIcons.pencil, wrapper: CustomIconButton),
        );
        await settle(tester, frames: 8);
        final navigation = RecordingRouteMock();
        QR.settings.mockRoute = navigation;
        addTearDown(() => QR.settings.mockRoute = null);
        await tester.tap(find.text('Manage association events'));
        await settle(tester, frames: 8);

        // The FIRST association's events are requested (the load is not
        // awaited, so the call is the observable part) and the router was
        // asked for the management page.
        verify(
          () => scaffold.repository.calendarEventsAssociationsAssociationIdGet(
            associationId: 'a-1',
          ),
        ).called(1);
        expect(navigation.navigated, contains('/feed/association_events'));
      },
    );

    testWidgets('an admin who is also a member gets the third modal entry', (
      tester,
    ) async {
      when(() => scaffold.repository.feedNewsGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), <News>[]),
      );

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(
          user: CoreUser.empty().copyWith(
            groups: [
              CoreGroupSimple.empty().copyWith(
                id: '59e3c4c2-e60f-44b6-b0d2-fa1b248423bb', // admin_feed
              ),
            ],
          ),
          myAssociations: [Association(name: 'BDE', groupId: 'g-1', id: 'a-1')],
        ),
        initialPath: '/feed',
      );
      await settle(tester, frames: 8);

      // The icon ternary gives admins the user-group icon even when they
      // are members, and the modal carries the admin-only requests entry.
      await tester.tap(
        heroButton(HeroIcons.userGroup, wrapper: CustomIconButton),
      );
      await settle(tester, frames: 8);
      expect(find.text('Manage requests'), findsOneWidget);

      final navigation = RecordingRouteMock();
      QR.settings.mockRoute = navigation;
      addTearDown(() => QR.settings.mockRoute = null);
      await tester.tap(find.text('Manage requests'));
      await settle(tester, frames: 8);
      expect(navigation.navigated, contains('/feed/event_handling'));
    });
  });
}
