import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import 'amap_integration_test.dart';
import '../amap_fixtures.dart';
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
    stubAdminLoads(scaffold, withDeliveryOrders: true);

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
      scaffold,
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
      withDeliveryOrders: true,
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
    stubAdminLoads(
      scaffold,
      deliveries: [delivery('d-1', DeliveryStatusType.creation)],
      withDeliveryOrders: true,
    );

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
    stubAdminLoads(
      scaffold,
      deliveries: [delivery('d-1', DeliveryStatusType.creation)],
      withDeliveryOrders: true,
    );

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

  /// Drives the status-advance button for [status]: the dialog's title and
  /// description are per-status ternaries only that status's confirm can
  /// build, and each arm toasts a different pair. The first confirm fails
  /// (the card keeps its status, so the button is still tappable), the
  /// second succeeds.
  Future<void> driveAdvance(
    WidgetTester tester,
    DeliveryStatusType status, {
    required String button,
    required String dialogDescription,
    required String failureToast,
    required String successToast,
  }) async {
    stubAdminLoads(
      scaffold,
      deliveries: [delivery('d-1', status, products: 1)],
      withDeliveryOrders: true,
    );
    var calls = 0;
    when(
      () => scaffold.repository.amapDeliveriesDeliveryIdLockPost(
        deliveryId: any(named: 'deliveryId'),
      ),
    ).thenAnswer((_) async {
      calls++;
      if (calls == 1) throw Exception('advance failed');
      return chopperResponseVoid();
    });
    when(
      () => scaffold.repository.amapDeliveriesDeliveryIdDeliveredPost(
        deliveryId: any(named: 'deliveryId'),
      ),
    ).thenAnswer((_) async {
      calls++;
      if (calls == 1) throw Exception('advance failed');
      return chopperResponseVoid();
    });
    when(
      () => scaffold.repository.amapDeliveriesDeliveryIdArchivePost(
        deliveryId: any(named: 'deliveryId'),
      ),
    ).thenAnswer((_) async {
      calls++;
      if (calls == 1) throw Exception('advance failed');
      return chopperResponseVoid();
    });

    final container = scaffold.makeContainer(
      user: amapAdminUser,
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await pumpAdmin(tester, container);

    expect(find.text(button), findsOneWidget);
    await tester.tap(find.text(button));
    await tester.pump();
    await settle(tester, frames: 8);
    // The per-status description branch of the dialog's ternary.
    expect(find.text(dialogDescription), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 12);
    expect(calls, 1);
    expect(find.text(failureToast), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // Failed arm left the status untouched: the same button advances for
    // real on the second confirm.
    await tester.tap(find.text(button));
    await tester.pump();
    await settle(tester, frames: 8);
    expect(find.text(dialogDescription), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 12);
    expect(calls, 2);
    expect(find.text(successToast), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  }

  testWidgets('the Lock button locks an orderable delivery in both outcomes', (
    tester,
  ) async {
    await driveAdvance(
      tester,
      DeliveryStatusType.orderable,
      button: 'Lock',
      dialogDescription: 'Lock delivery?',
      failureToast: 'Delivery not locked',
      successToast: 'Delivery locked',
    );
  });

  testWidgets('the End button completes a locked delivery in both outcomes', (
    tester,
  ) async {
    await driveAdvance(
      tester,
      DeliveryStatusType.locked,
      button: 'End of delivery',
      dialogDescription: 'Are all orders delivered?',
      failureToast: 'Delivery not completed',
      successToast: 'Delivery completed',
    );
  });

  testWidgets('the Archive button archives a delivered delivery in both '
      'outcomes', (tester) async {
    await driveAdvance(
      tester,
      DeliveryStatusType.delivered,
      button: 'Archive',
      dialogDescription: 'Archiving delivery',
      failureToast: 'Delivery not archived',
      successToast: 'Delivery archived',
    );
  });

  testWidgets('the trash dialog reports a failed delete', (tester) async {
    stubAdminLoads(
      scaffold,
      deliveries: [delivery('d-1', DeliveryStatusType.creation)],
      withDeliveryOrders: true,
    );
    when(
      () => scaffold.repository.amapDeliveriesDeliveryIdDelete(
        deliveryId: any(named: 'deliveryId'),
      ),
    ).thenThrow(Exception('delete failed'));

    final container = scaffold.makeContainer(
      user: amapAdminUser,
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await pumpAdmin(tester, container);

    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.trash),
    );
    await tester.pump();
    await settle(tester, frames: 8);
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 12);

    // The error arm toasts and keeps the card on screen.
    expect(find.text('Error while deleting'), findsOneWidget);
    expect(find.text('The 12/31/2100'), findsOneWidget);
    // Drain the toast timer.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
