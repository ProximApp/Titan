import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../amap_fixtures.dart';
import '../../shared/app_scaffold.dart';

/// The amap pages ship ONE debug-mode-only exception that release builds
/// never surface: the cash and order-list notifiers `return state` from
/// build(), which always throws once on the first build under Riverpod 3
/// before the load they scheduled heals the state. It is filtered; anything
/// else — including every `A RenderFlex overflowed` — stays fatal, which is
/// what makes the card layout pass (ledger #4) a real guard: the order,
/// delivery, cash and "see more" cards all render inside fixed-width
/// containers at their natural text sizes.

void stubEmptyAmap(IntegrationScaffold scaffold) {
  when(
    () => scaffold.repository.amapUsersUserIdCashGet(
      userId: any(named: 'userId'),
    ),
  ).thenAnswer((_) async => chopperResponse(cash(0)));
  when(() => scaffold.repository.amapDeliveriesGet())
      .thenAnswer((_) async => chopperListResponse(const <DeliveryReturn>[]));
  when(
    () => scaffold.repository.amapUsersUserIdOrdersGet(
      userId: any(named: 'userId'),
    ),
  ).thenAnswer((_) async => chopperListResponse(const <OrderReturn>[]));
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  group('Amap main page', () {
    // NOTE on ordering: qlevar_router 1.12.4 silently drops the first
    // mid-test QR.to() to a route that is not yet mounted when an earlier
    // test already ran in the same isolate. The navigation test is kept
    // first; the remaining tests only assert on already-mounted routes.
    testWidgets('admin button opens the amap admin page', (tester) async {
      stubEmptyAmap(scaffold);
      when(() => scaffold.repository.amapUsersCashGet()).thenAnswer(
        (_) async =>
            chopperListResponse(<AppModulesAmapSchemasAmapCashComplete>[]),
      );
      when(() => scaffold.repository.amapProductsGet()).thenAnswer(
        (_) async =>
            chopperListResponse(<AppModulesAmapSchemasAmapProductComplete>[]),
      );

      final container = scaffold.makeContainer(
        user: amapAdminUser,
        userId: 'user-1',
      );
      await scaffold.pumpApp(tester, container, initialPath: '/amap');
      await settle(tester);

      await tester.tap(find.text('Admin'));
      await settle(tester, frames: 16);

      expect(QR.currentPath, '/amap/admin');
      // The admin page renders its three handler sections.
      expect(find.text('Products'), findsOneWidget);
    });

    testWidgets('renders balance, deliveries and orders', (tester) async {
      when(
        () => scaffold.repository.amapUsersUserIdCashGet(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => chopperResponse(cash(2510)));
      when(() => scaffold.repository.amapDeliveriesGet()).thenAnswer(
        (_) async => chopperListResponse([
          orderableDelivery('d-1', 2),
          // A locked delivery is filtered out of the available list.
          DeliveryReturn.empty().copyWith(
            id: 'd-2',
            deliveryDate: DateTime(2101),
            status: DeliveryStatusType.locked,
          ),
        ]),
      );
      when(
        () => scaffold.repository.amapUsersUserIdOrdersGet(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer(
        (_) async => chopperListResponse([order('o-1', 'd-1', 500)]),
      );

      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(id: 'user-1'),
        userId: 'user-1',
      );
      await scaffold.pumpApp(tester, container, initialPath: '/amap');
      await settle(tester);

      // Hyperion stores amap balances in CENTS (ledger #5/#13): 2510
      // renders as "25.10".
      expect(find.textContaining('Balance : 25.10'), findsOneWidget);
      // The orderable delivery shows its date and its product count; the
      // locked one does not.
      expect(find.textContaining('12/31/2100'), findsWidgets);
      expect(find.textContaining('2 products'), findsWidgets);
      expect(find.textContaining('Delivery d-2'), findsNothing);
      // The order card shows its amount and collection slot, and because
      // its delivery is still orderable the edit/delete buttons are shown
      // instead of the Locked label.
      // 500 CENTS → 5.00€, like every other amap money field.
      expect(find.textContaining('5.00€'), findsOneWidget);
      // "Midi" appears in the order card and again in the (off-screen)
      // order panel's collection-slot selector.
      expect(find.text('Midi'), findsWidgets);
      expect(find.text('Locked'), findsNothing);
    });

    testWidgets('shows the empty state without deliveries', (tester) async {
      stubEmptyAmap(scaffold);

      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(id: 'user-1'),
        userId: 'user-1',
      );
      await scaffold.pumpApp(tester, container, initialPath: '/amap');
      await settle(tester);

      expect(find.textContaining('Balance : 0.00'), findsOneWidget);
      // Rendered once in the main delivery section and once in the
      // (off-screen) order panel's delivery section.
      expect(find.text('No scheduled delivery'), findsNWidgets(2));
    });
  });
}
