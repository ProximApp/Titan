import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/my_stores_provider.dart';
import 'package:titan/tickets/ui/pages/manage_ticket_event_page.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../../shared/app_scaffold.dart';

/// The manage page mounted as a WIDGET, with its store list controlled
/// directly — the two states the route can never hand it.
///
/// `/tickets/manage` sits behind `AdminMiddleware(canManageTicketEventsProvider)`,
/// and that gate answers `false` while `myStores` is loading or empty, so the
/// router never builds this page without a non-empty list. That is what makes
/// the store-adoption effect and the refresher's no-store guard dead THERE.
/// Mounted directly, both states are selectable, so this file settles what the
/// guards actually do instead of asserting they cannot run:
///
///  * the effect adopts the first store the moment the list arrives late
///    (production's real notifier also starts on `AsyncLoading` and resolves
///    after the first build — the route just bounces before that happens),
///  * and a pull with no store selected resolves to `Future.value()`, asking
///    the backend for nothing.
class _LateStoresNotifier extends MyStoresNotifier {
  /// What the first build sees: empty, the state the route gate refuses, so
  /// the page's own `useState` has no store to adopt.
  @override
  AsyncValue<List<UserStore>> build() => AsyncValue.data(const []);

  /// Publishes the list the way the real notifier does when its load lands.
  void reveal(List<UserStore> stores) => state = AsyncValue.data(stores);
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  UserStore store(String id, String name) =>
      UserStore.empty().copyWith(id: id, name: name);

  void stubStoreEvents() {
    when(
      () => scaffold.repository.ticketsAdminStoreStoreIdEventsGet(
        storeId: any(named: 'storeId'),
      ),
    ).thenAnswer((_) async => chopperListResponse(<EventSimple>[]));
  }

  testWidgets('a store list that arrives after the first build is adopted', (
    tester,
  ) async {
    stubStoreEvents();
    final notifier = _LateStoresNotifier();
    final container = scaffold.makeContainer(
      providerOverrides: [myStoresProvider.overrideWith(() => notifier)],
    );
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      const ManageTicketEventPage(),
      container,
    );

    // Empty list: no chip to pick and nothing asked of the backend.
    expect(find.text('BDE'), findsNothing);
    verifyNever(
      () => scaffold.repository.ticketsAdminStoreStoreIdEventsGet(
        storeId: any(named: 'storeId'),
      ),
    );

    // The load lands after the build — the effect sees `selectedStore` null,
    // a value in `myStores`, and adopts it.
    notifier.reveal([store('store-1', 'BDE')]);
    await settle(tester, frames: 12);

    expect(find.text('BDE'), findsOneWidget);
    verify(
      () => scaffold.repository.ticketsAdminStoreStoreIdEventsGet(
        storeId: 'store-1',
      ),
    ).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pull with no store selected resolves without asking', (
    tester,
  ) async {
    stubStoreEvents();
    final container = scaffold.makeContainer(
      providerOverrides: [
        myStoresProvider.overrideWith(() => _LateStoresNotifier()),
      ],
    );
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      const ManageTicketEventPage(),
      container,
    );

    final refresher = tester.widget<Refresher>(find.byType(Refresher));
    await tester.runAsync(() async {
      await refresher.onRefresh();
    });
    await settle(tester, frames: 12);

    // The guard returned a completed future instead of a request.
    verifyNever(
      () => scaffold.repository.ticketsAdminStoreStoreIdEventsGet(
        storeId: any(named: 'storeId'),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
