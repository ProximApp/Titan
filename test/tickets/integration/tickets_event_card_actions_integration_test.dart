import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/ui/components/ticket_event_card.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';

import '../../shared/app_scaffold.dart';
import '../tickets_fixtures.dart';

/// `TicketEventCard`'s actions sheet (ticket_event_card.dart:44-61): the
/// View results and Edit entries only ever ran their onPressed in no test —
/// `tickets_manage_integration_test` opens the sheet but stops before the
/// buttons, because the entries route away from the page it renders.
///
/// Both tests boot the SAME deep link (convention 10): qlevar 1.12.4 only
/// renders the boot page of the first test in an isolate, and the target
/// pages are covered by their own files — so the assertions are on the
/// sheet (both entries present for a seller who can manage events) and on
/// the path each button set. Bounded frames throughout: the manage page's
/// refresher never settles.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  models.EventSimple event(String id, String name) =>
      models.EventSimple.empty().copyWith(
        id: id,
        name: name,
        storeId: 'store-1',
        openDatetime: DateTime(2100, 3, 15, 20),
      );

  /// Boots `/tickets/manage` for a seller who can manage events (the
  /// scaffold's myStores/storeSellers fakes open AdminMiddleware on the
  /// results/edit routes the buttons target).
  Future<void> pumpManage(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    when(() => scaffold.repository.mypaymentUsersMeStoresGet()).thenAnswer(
      (_) async => chopperListResponse(<models.UserStore>[
        models.UserStore.empty().copyWith(id: 'store-1', name: 'BDE'),
      ]),
    );
    when(
      () => scaffold.repository.ticketsAdminStoreStoreIdEventsGet(
        storeId: 'store-1',
      ),
    ).thenAnswer((_) async => chopperListResponse([event('e-1', 'Gala')]));
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets/manage',
      pumpAndSettle: false,
    );
    await settle(tester);
  }

  testWidgets(
    "the event card's View results entry routes to the results page",
    (tester) async {
      final container = sellerContainer(scaffold);
      addTearDown(container.dispose);
      // The results page mounts on the route the button targets; stub its
      // reads in case the swap runs.
      when(
        () => scaffold.repository.ticketsAdminEventsEventIdGet(eventId: 'e-1'),
      ).thenAnswer(
        (_) async => chopperResponse(
          models.EventAdmin.empty().copyWith(id: 'e-1', name: 'Gala'),
        ),
      );
      when(
        () => scaffold.repository.ticketsAdminEventsEventIdTicketsGet(
          eventId: 'e-1',
        ),
      ).thenAnswer(
        (_) async =>
            chopperListResponse(<models.AppCoreTicketsSchemasTicketsTicket>[]),
      );
      await pumpManage(tester, container);

      expect(QR.currentPath, '/tickets/manage');
      expect(find.byType(TicketEventCard), findsOneWidget);

      await tester.tap(find.byType(TicketEventCard));
      await settle(tester, frames: 10);

      // canManage is true for this seller, so the modal carries both entries.
      expect(find.byType(BottomModalTemplate), findsOneWidget);
      expect(find.text('View results'), findsOneWidget);
      expect(find.text('Edit ticketing'), findsOneWidget);

      await tester.tap(find.text('View results'));
      await settle(tester, frames: 20);

      expect(QR.currentPath, '/tickets/results');
    },
  );

  testWidgets("the event card's Edit entry routes to the edit form", (
    tester,
  ) async {
    final container = sellerContainer(scaffold);
    addTearDown(container.dispose);
    when(() => scaffold.repository.ticketsAdminEventsEventIdGet(eventId: 'e-1'))
        .thenAnswer((_) async => chopperResponse(models.EventAdmin.empty()));
    await pumpManage(tester, container);

    expect(find.byType(TicketEventCard), findsOneWidget);
    await tester.tap(find.byType(TicketEventCard));
    await settle(tester, frames: 10);
    expect(find.text('Edit ticketing'), findsOneWidget);

    await tester.tap(find.text('Edit ticketing'));
    await settle(tester, frames: 20);

    expect(QR.currentPath, '/tickets/edit');
  });
}
