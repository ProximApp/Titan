import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The tickets main page's untested behaviour: the admin modal's MANAGE
/// action and the list's ordering/refresh.
///
/// The existing page test covers the header, the cards, the empty state, a
/// gated admin button and the payment-return toast. What it never does is
/// press anything inside the admin modal (both buttons only popped the
/// previous screen's test), sort a MIXED list — its two tickets are both
/// upcoming, so only the same-side branch of the comparator runs — or pull
/// the list down, which is the only thing that calls `onRefresh`.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// A user who owns a store and may manage its events: the admin button
  /// renders and the `/manage` route's AdminMiddleware lets the navigation
  /// through (a plain user would be bounced by it).
  IntegrationContainerOwner seller() => IntegrationContainerOwner(scaffold);

  AppCoreTicketsSchemasTicketsTicketComplete ticket(
    String id,
    String sessionName,
    DateTime start,
  ) => AppCoreTicketsSchemasTicketsTicketComplete.empty().copyWith(
    id: id,
    price: 1500,
    event: EventSimple.empty().copyWith(id: 'event-$id', name: 'Gala $id'),
    category: Category.empty().copyWith(id: 'cat-$id', name: 'Normal'),
    session: Session.empty().copyWith(
      id: 'session-$id',
      name: sessionName,
      startDatetime: start,
    ),
  );

  testWidgets('the admin modal opens the manage route', (tester) async {
    final container = seller().container(
      myTickets: <AppCoreTicketsSchemasTicketsTicketComplete>[],
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    expect(find.text('Admin'), findsOneWidget);
    await tester.tap(find.text('Admin'));
    await settle(tester, frames: 10);
    expect(find.text('Manage association ticketings'), findsOneWidget);

    await tester.tap(find.text('Manage association ticketings'));
    await settle(tester, frames: 20);

    // The modal's button pops itself and routes to the manage screen, which
    // the admin gate admits because this user can manage the store's events.
    expect(QR.currentPath, '/tickets/manage');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mixed tickets sort upcoming-first, past-recent-first, and a pull reloads',
    (tester) async {
      final container = seller().container(
        myTickets: [
          ticket('1', 'Old past', DateTime(2020)),
          ticket('2', 'Soon', DateTime(2100)),
          ticket('3', 'Recent past', DateTime(2025)),
        ],
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/tickets',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 30);

      expect(find.text('Soon'), findsOneWidget);
      expect(find.text('Recent past'), findsOneWidget);
      expect(find.text('Old past'), findsOneWidget);

      // Upcoming first (its own ascending arm), then the past ones newest
      // first — the two branches the both-upcoming fixtures never reach.
      final soonY = tester.getTopLeft(find.text('Soon')).dy;
      final recentY = tester.getTopLeft(find.text('Recent past')).dy;
      final oldY = tester.getTopLeft(find.text('Old past')).dy;
      expect(soonY, lessThan(recentY));
      expect(recentY, lessThan(oldY));

      // Pull the list down: on iOS/macOS the refresher is a
      // CupertinoSliverRefreshControl, which calls onRefresh once the pull
      // passes its trigger distance and is released.
      clearInteractions(scaffold.repository);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 320));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await settle(tester, frames: 12);

      expect(
        verify(() => scaffold.repository.ticketsUserMeTicketsGet()).callCount,
        greaterThanOrEqualTo(1),
        reason: 'the pull-to-refresh callback must reload the tickets',
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}

/// Builds the seller container the page needs, with the ticket list stubbed.
class IntegrationContainerOwner {
  IntegrationContainerOwner(this.scaffold);

  final IntegrationScaffold scaffold;

  dynamic container({
    required List<AppCoreTicketsSchemasTicketsTicketComplete> myTickets,
  }) {
    when(() => scaffold.repository.ticketsUserMeTicketsGet())
        .thenAnswer((_) async => chopperListResponse(myTickets));
    return scaffold.makeContainer(
      user: models.CoreUser.empty().copyWith(id: 'me'),
      myStores: [
        models.UserStore.empty().copyWith(
          id: 'store-1',
          name: 'BDE',
          associationId: 'a-1',
        ),
      ],
      storeSellers: {
        'store-1': [
          Seller.empty().copyWith(userId: 'me', canManageEvents: true),
        ],
      },
    );
  }
}
