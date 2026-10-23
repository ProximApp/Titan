import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../../shared/app_scaffold.dart';
import '../tickets_fixtures.dart';

/// The manage page (`/tickets/manage`, 60 executable lines) with its store
/// chips, its event-card list and its empty state — plus `TicketEventCard`
/// (22 uncovered lines), which only this page mounts in a list.
///
/// The route sits behind AdminMiddleware(canManageTicketEventsProvider):
/// the seller row must carry canManageEvents, so the scaffold's
/// myStores/storeSellers fakes pin the gate (same as the create file).
/// Every test deep-links the SAME path (convention 10).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  final _twoStores = [
    UserStore.empty().copyWith(id: 'store-1', name: 'BDE'),
    UserStore.empty().copyWith(id: 'store-2', name: 'Kfet'),
  ];

  EventSimple event(String id, String name, {DateTime? openDatetime}) =>
      EventSimple.empty().copyWith(
        id: id,
        name: name,
        storeId: 'store-1',
        openDatetime: openDatetime ?? DateTime(2100, 3, 15, 20),
      );

  Future<void> pumpManage(
    WidgetTester tester,
    ProviderContainer container, {
    List<EventSimple> storeOneEvents = const [],
  }) async {
    when(
      () => scaffold.repository.ticketsAdminStoreStoreIdEventsGet(
        storeId: 'store-1',
      ),
    ).thenAnswer((_) async => chopperListResponse(storeOneEvents));
    when(
      () => scaffold.repository.ticketsAdminStoreStoreIdEventsGet(
        storeId: 'store-2',
      ),
    ).thenAnswer((_) async => chopperListResponse(<EventSimple>[]));
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets/manage',
      pumpAndSettle: false,
    );
    await settle(tester);
  }

  testWidgets('the manage page lists the stores as chips and their events', (
    tester,
  ) async {
    final container = sellerContainer(scaffold, stores: _twoStores);
    addTearDown(container.dispose);

    await pumpManage(
      tester,
      container,
      storeOneEvents: [
        event('e-1', 'Gala'),
        event('e-2', 'Soiree', openDatetime: DateTime(2100, 6, 1, 10)),
      ],
    );

    // Both stores render as select chips, the first one pre-selected by
    // the useState initial value.
    expect(find.text('BDE'), findsOneWidget);
    expect(find.text('Kfet'), findsOneWidget);

    // One TicketEventCard per event: title, opening subtitle from the
    // card's date formatter, and the derived status chip.
    expect(find.text('Gala'), findsOneWidget);
    expect(find.text('Soiree'), findsOneWidget);
    expect(find.text('Opening: 15/03/2100 20:00'), findsOneWidget);
    expect(find.text('Opening: 01/06/2100 10:00'), findsOneWidget);

    // The new-ticketing button routes to /tickets/create (the tap itself
    // is never fired: a different path would be a second journey).
    expect(find.byTooltip('New ticketing'), findsOneWidget);
  });

  testWidgets('selecting the other store reloads its events and shows the '
      'empty state', (tester) async {
    final container = sellerContainer(scaffold, stores: _twoStores);
    addTearDown(container.dispose);

    await pumpManage(tester, container, storeOneEvents: [event('e-1', 'Gala')]);
    expect(find.text('Gala'), findsOneWidget);

    // The second store has no events: selecting it fires the load twice
    // (onItemSelected directly AND the [selectedStore.value] effect), the
    // list resolves empty and the empty state renders.
    await tester.tap(find.text('Kfet'));
    await settle(tester);

    verify(
      () => scaffold.repository.ticketsAdminStoreStoreIdEventsGet(
        storeId: 'store-2',
      ),
    ).called(2);
    expect(find.text('No ticketing exists for this store'), findsOneWidget);
    expect(find.text('Gala'), findsNothing);
    expect(find.text('BDE'), findsOneWidget);
  });

  testWidgets('pulling the list down reloads the selected store', (
    tester,
  ) async {
    final container = sellerContainer(scaffold, stores: _twoStores);
    addTearDown(container.dispose);

    await pumpManage(tester, container, storeOneEvents: [event('e-1', 'Gala')]);

    // Refresher runs on the Cupertino path under the test binding (the
    // host is neither Android nor web): the canonical pull sequence is a
    // long drag to stretch the control, then a fling release (purchases /
    // settings convention).
    await tester.drag(find.byType(Refresher), const Offset(0, 1500));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.fling(find.byType(Refresher), const Offset(0, 300), 1000);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);

    // mocktail's verify consumes matched calls, so this single verify
    // counts BOTH the mount load and the refresh load.
    verify(
      () => scaffold.repository.ticketsAdminStoreStoreIdEventsGet(
        storeId: 'store-1',
      ),
    ).called(2);
  });

  testWidgets('tapping an event card opens its actions sheet', (tester) async {
    final container = sellerContainer(scaffold, stores: _twoStores);
    addTearDown(container.dispose);

    await pumpManage(tester, container, storeOneEvents: [event('e-1', 'Gala')]);

    // The card's onTap sheet: title, status chip, and — the admin gate
    // being passed — the results and edit actions. The buttons themselves
    // are never fired: each routes to a different path, which would be a
    // second journey for this file (convention 10).
    await scaffold.openModal(tester, find.text('Gala'));
    expect(scaffold.isModalOpen(tester), isTrue);
    // The sheet title duplicates the card title while it is open.
    expect(find.text('Gala'), findsNWidgets(2));
    expect(find.text('View results'), findsOneWidget);
    expect(find.text('Edit ticketing'), findsOneWidget);

    await scaffold.closeModal(tester);
    expect(scaffold.isModalOpen(tester), isFalse);
    expect(find.text('Gala'), findsOneWidget);
  });
}
