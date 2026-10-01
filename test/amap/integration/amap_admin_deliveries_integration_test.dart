import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import 'amap_integration_test.dart';
import '../../shared/app_scaffold.dart';

/// The admin page's middle handler (DeliveryHandler): delivery cards with
/// their order/product counts, the create-delivery navigation, the trash
/// dialog and the status-advance dialog (Open).
///
/// The FIRST test is the only mid-test navigator: qlevar 1.12.4 silently
/// drops later mid-test QR.to() calls to not-yet-mounted routes once an
/// earlier test ran in the isolate (see amap_integration_test.dart).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  DeliveryReturn delivery(
    String id,
    DeliveryStatusType status, {
    DateTime? date,
    int products = 0,
  }) => DeliveryReturn.empty().copyWith(
    id: id,
    name: 'Delivery $id',
    deliveryDate: date ?? DateTime(2100, 12, 31),
    status: status,
    products: List.generate(
      products,
      (i) => AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
        id: 'p-$i',
        name: 'Product $i',
      ),
    ),
  );

  /// Stubs everything the admin page loads on mount. Nullable params so the
  /// defaults can be const: DeliveryHandler sorts a copy of the provider's
  /// list (ledger #12), so an unmodifiable fixture is now the honest one and
  /// guards the fix.
  void stubAdminLoads({
    List<DeliveryReturn>? deliveries,
    Map<String, List<OrderReturn>>? ordersByDelivery,
  }) {
    when(() => scaffold.repository.amapUsersCashGet()).thenAnswer(
      (_) async =>
          chopperListResponse(<AppModulesAmapSchemasAmapCashComplete>[]),
    );
    when(() => scaffold.repository.amapDeliveriesGet()).thenAnswer(
      (_) async => chopperListResponse(deliveries ?? const <DeliveryReturn>[]),
    );
    when(() => scaffold.repository.amapProductsGet()).thenAnswer(
      (_) async =>
          chopperListResponse(<AppModulesAmapSchemasAmapProductComplete>[]),
    );
    when(
      () => scaffold.repository.amapDeliveriesDeliveryIdOrdersGet(
        deliveryId: any(named: 'deliveryId'),
      ),
    ).thenAnswer(
      (inv) async => chopperListResponse(
        ordersByDelivery?[inv.namedArguments[#deliveryId] as String] ?? [],
      ),
    );
  }

  Future<void> pumpAdmin(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    ignoreAmapKnownQuirks();
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/amap/admin',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);
  }

  testWidgets('the + card opens the add-delivery form', (tester) async {
    stubAdminLoads();

    final container = scaffold.makeContainer(
      user: amapAdminUser,
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await pumpAdmin(tester, container);

    // The + card is the second plus on the page: the AccountHandler's
    // cash-mode toggle comes first in the column, the DeliveryHandler's
    // create card second, the ProductHandler's third.
    await tester.tap(
      find
          .byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus)
          .at(1),
    );
    for (var i = 0; i < 20 && find.text('Order date').evaluate().isEmpty; i++) {
      await settle(tester, frames: 4);
    }

    // The deferred form route mounts. The page title always reads "Add
    // delivery" (even in edit mode — only the submit button changes).
    expect(find.text('Add delivery'), findsWidgets);
    expect(find.text('Order date'), findsOneWidget);
    expect(find.text('Order products'), findsOneWidget);
    expect(find.text('No product'), findsOneWidget);
  });

  testWidgets('renders delivery cards with date, order and product counts', (
    tester,
  ) async {
    stubAdminLoads(
      deliveries: [
        // creation sorts before orderable (earlier date).
        delivery(
          'd-1',
          DeliveryStatusType.creation,
          date: DateTime(2100),
          products: 1,
        ),
        delivery('d-2', DeliveryStatusType.orderable, products: 2),
      ],
      ordersByDelivery: {
        'd-1': [],
        'd-2': [order('o-1', 'd-2', 500), order('o-2', 'd-2', 1200)],
      },
    );

    final container = scaffold.makeContainer(
      user: amapAdminUser,
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await pumpAdmin(tester, container);

    // Both cards show their formatted date: d-1 sorts first with
    // DateTime(2100) = 1/1/2100, d-2 sits on 12/31/2100.
    expect(find.text('The 1/1/2100'), findsOneWidget);
    expect(find.text('The 12/31/2100'), findsOneWidget);
    // Per-card order counts from the per-delivery orders endpoint.
    expect(find.text('No current order'), findsOneWidget);
    expect(find.text('2 orders'), findsOneWidget);
    // Per-card product counts.
    expect(find.text('1 product'), findsOneWidget);
    expect(find.text('2 products'), findsOneWidget);
    // Creation cards get Open + edit/delete; orderable cards get Lock.
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Lock'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.trash),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.pencil,
      ),
      findsOneWidget,
    );
  });

  testWidgets('the trash dialog deletes a creation delivery', (tester) async {
    stubAdminLoads(deliveries: [delivery('d-1', DeliveryStatusType.creation)]);

    String? deletedDeliveryId;
    when(
      () => scaffold.repository.amapDeliveriesDeliveryIdDelete(
        deliveryId: any(named: 'deliveryId'),
      ),
    ).thenAnswer((inv) async {
      deletedDeliveryId = inv.namedArguments[#deliveryId] as String;
      return chopperResponseVoid();
    });

    final container = scaffold.makeContainer(
      user: amapAdminUser,
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await pumpAdmin(tester, container);

    // Trash opens the confirmation dialog (frame pumps — a loader may
    // still be spinning behind the dialog).
    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.trash),
    );
    await tester.pump();
    await settle(tester, frames: 8);
    expect(find.text('Delete delivery?'), findsOneWidget);
    expect(
      find.text('Are you sure you want to delete this delivery?'),
      findsOneWidget,
    );

    // Confirm runs the real DELETE and toasts.
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 12);

    expect(deletedDeliveryId, 'd-1');
    expect(find.text('Delivery deleted'), findsOneWidget);
    // The card leaves the row.
    expect(find.text('The 12/31/2100'), findsNothing);
    // Drain the toast timer.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('the Open button opens a creation delivery for ordering', (
    tester,
  ) async {
    stubAdminLoads(deliveries: [delivery('d-1', DeliveryStatusType.creation)]);

    String? openedDeliveryId;
    when(
      () => scaffold.repository.amapDeliveriesDeliveryIdOpenorderingPost(
        deliveryId: any(named: 'deliveryId'),
      ),
    ).thenAnswer((inv) async {
      openedDeliveryId = inv.namedArguments[#deliveryId] as String;
      return chopperResponseVoid();
    });

    final container = scaffold.makeContainer(
      user: amapAdminUser,
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await pumpAdmin(tester, container);

    // The advance button opens the confirmation dialog: the Open step's
    // title and description are the same l10n string (amapOpenningDelivery)
    // but only the dialog body carries it — the button label is 'Open'.
    await tester.tap(find.text('Open'));
    await tester.pump();
    await settle(tester, frames: 8);
    expect(find.text('Open delivery?'), findsOneWidget);

    // Confirm runs the real openordering POST.
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 12);

    expect(openedDeliveryId, 'd-1');
    expect(find.text('Delivery opened'), findsOneWidget);
    // Drain the toast timer.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
