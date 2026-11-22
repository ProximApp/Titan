import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../../shared/app_scaffold.dart';

/// The event-handling page's remaining arms: the location row and the reject
/// button of [AdminEventCard], the two filter arms the first journey file does
/// not visit (All and Approved, including their empty states), and the
/// shell's pull-to-refresh callback.
///
/// The reject button is the mirror of the already-covered approve: it copies
/// the news with `status: rejected`, posts, then reloads the public list. The
/// card stays in `adminNewsListProvider` — only the filter hides it — which is
/// why the assertion is "gone from the pending list", not "deleted".
///
/// Refresh is exercised through the real `Refresher` (a
/// CupertinoSliverRefreshControl on this platform) rather than by calling the
/// callback: the gesture is what proves the wiring, and the counter is what
/// proves the body ran.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  News news({
    required String id,
    required String title,
    required enums.NewsStatus status,
    String? location,
  }) => News.empty().copyWith(
    id: id,
    title: title,
    entity: 'BDE',
    module: 'event',
    location: location,
    start: DateTime(2026, 10, 10, 20),
    status: status,
  );

  ProviderContainer adminContainer() => scaffold.makeContainer(
    user: CoreUser.empty().copyWith(
      groups: [
        CoreGroupSimple.empty().copyWith(
          id: '59e3c4c2-e60f-44b6-b0d2-fa1b248423bb', // admin_feed
          name: 'admin_feed',
        ),
      ],
    ),
  );

  testWidgets('a pending card shows its location and can be rejected', (
    tester,
  ) async {
    final container = adminContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);

    when(() => scaffold.repository.feedAdminNewsGet()).thenAnswer(
      (_) async => chopperListResponse([
        news(
          id: 'n-1',
          title: 'Soirée phosphorescente',
          status: enums.NewsStatus.waitingApproval,
          location: 'Salle B2, bâtiment A',
        ),
      ]),
    );
    when(() => scaffold.repository.feedNewsGet())
        .thenAnswer((_) async => chopperListResponse(<News>[]));
    when(
      () => scaffold.repository.feedAdminNewsNewsIdRejectPost(
        newsId: any(named: 'newsId'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/feed/event_handling',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);

    // The location row only renders for a location that is set and not empty.
    expect(find.text('Salle B2, bâtiment A'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);

    await tester.tap(find.text('Reject'));
    await settle(tester, frames: 10);
    verify(
      () => scaffold.repository.feedAdminNewsNewsIdRejectPost(newsId: 'n-1'),
    ).called(1);
    // Rejected news drops out of the default (pending) filter.
    expect(find.text('Soirée phosphorescente'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await scaffold.unmountApp(tester);
  });

  testWidgets('an empty admin list explains itself on the All and Approved '
      'filters', (tester) async {
    final container = adminContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);

    when(() => scaffold.repository.feedAdminNewsGet())
        .thenAnswer((_) async => chopperListResponse(<News>[]));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/feed/event_handling',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);

    // Pending is the default filter (covered elsewhere); All and Approved
    // each answer with their own empty message, not a blank page.
    expect(find.text('No events pending approval'), findsOneWidget);

    await tester.tap(find.text('All'));
    await settle(tester, frames: 6);
    expect(find.text('No events available'), findsOneWidget);

    await tester.tap(find.text('Approved'));
    await settle(tester, frames: 6);
    expect(find.text('No approved events'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the top bar back arrow reloads the feed and returns to it', (
    tester,
  ) async {
    // `FeedTemplate`'s TopBar has an `onBack` that reloads the news list when
    // the page it is covering is the handling page, then pops: the feed shows
    // the just-approved items instead of the pre-moderation list.
    final container = adminContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);

    var newsCalls = 0;
    when(() => scaffold.repository.feedAdminNewsGet())
        .thenAnswer((_) async => chopperListResponse(<News>[]));
    when(() => scaffold.repository.feedNewsGet()).thenAnswer((_) async {
      newsCalls++;
      return chopperListResponse(<News>[]);
    });

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/feed/event_handling',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);
    expect(QR.currentPath, '/feed/event_handling');
    final before = newsCalls;

    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is HeroIcon && widget.icon == HeroIcons.chevronLeft,
      ),
    );
    await settle(tester, frames: 10);

    expect(newsCalls, greaterThan(before));
    expect(QR.currentPath, '/feed');
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('pulling the handling page reloads the admin list', (
    tester,
  ) async {
    final container = adminContainer();
    addTearDown(container.dispose);

    var calls = 0;
    when(() => scaffold.repository.feedAdminNewsGet()).thenAnswer((_) async {
      calls++;
      return chopperListResponse(<News>[]);
    });

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/feed/event_handling',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);
    expect(calls, 1);

    await tester.drag(find.byType(Refresher), const Offset(0, 400));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.fling(find.byType(Refresher), const Offset(0, 300), 1000);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);

    expect(calls, greaterThan(1));
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
