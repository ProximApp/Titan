import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/purchases/providers/product_id_provider.dart';
import 'package:titan/purchases/providers/tag_list_provider.dart';
import 'package:titan/purchases/providers/ticket_id_provider.dart';
import 'package:titan/purchases/ui/pages/user_list_page/user_list_page.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../../shared/app_scaffold.dart';

CoreUserSimple scannedUser(String id, String firstname, String name) =>
    CoreUserSimple.empty().copyWith(id: id, firstname: firstname, name: name);

/// The scanned-users page reached from the scan page's list bullet: the
/// ticket/product ids are pre-seeded the way the bullet sets them, the
/// pull-to-refresh loads the tags, and a chip tap loads the tag's users.
/// One router-pushing test per file (convention 19) — the remaining tests
/// only assert on branches that need no navigation.
/// Coverage note: the refresher's two id guards are `productId.maybeWhen`
/// (walked by the no-ids drag below) and the INNER `ticketId.maybeWhen`, which
/// needs a product id with no ticket id behind it. A drag cannot arm the
/// Cupertino control in this harness (it springs back), so the test awaits the
/// `onRefresh` closure the control is handed — the page's own public wiring —
/// and asserts it asks for no tags.
/// The two chip onTap fallbacks ARE reachable, and the last two tests walk
/// them: tags are kept in a module provider while the ids live in their own,
/// so a page entered after the ids were dropped still shows the chips.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  void stubTags(List<String> tags) {
    when(
      () => scaffold.repository
          .cdrSellersSellerIdProductsProductIdTagsGeneratorIdGet(
            sellerId: any(named: 'sellerId'),
            productId: any(named: 'productId'),
            generatorId: any(named: 'generatorId'),
          ),
    ).thenAnswer((_) async => chopperListResponse(tags));
  }

  void stubUsers(String tag, List<CoreUserSimple> users) {
    when(
      () => scaffold.repository
          .cdrSellersSellerIdProductsProductIdTicketsGeneratorIdListsTagGet(
            sellerId: any(named: 'sellerId'),
            productId: any(named: 'productId'),
            generatorId: any(named: 'generatorId'),
            tag: tag,
          ),
    ).thenAnswer((_) async => chopperListResponse(users));
  }

  testWidgets('refresh loads the tags and a chip tap lists the scanned users', (
    tester,
  ) async {
    stubTags(['VIP', 'BDE']);
    stubUsers('VIP', [scannedUser('u-1', 'Alice', 'Martin')]);
    stubUsers('BDE', <CoreUserSimple>[]);

    final container = scaffold.makeContainer();
    // The scan page's list bullet sets both ids before pushing this page.
    container.read(ticketIdProvider.notifier).setTicketId('gen-1');
    container.read(productIdProvider.notifier).setProductId('prod-1');

    // The page parks on the tag loader until a refresh arrives, and an
    // indeterminate Loader never lets pumpAndSettle finish (convention 12).
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/purchases/user_list',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);

    // Pull to refresh: the page only loads tags from the refresh closure.
    await tester.drag(find.byType(Refresher), const Offset(0, 1500));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.fling(find.byType(Refresher), const Offset(0, 300), 1000);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);

    expect(find.text('VIP'), findsOneWidget);
    expect(find.text('BDE'), findsOneWidget);

    await tester.tap(find.text('VIP'));
    await settle(tester, frames: 8);
    expect(find.text('Alice Martin'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The other tag has no scans yet.
    await tester.tap(find.text('BDE'));
    await settle(tester, frames: 8);
    expect(find.text('Aucun utilisateur scanné'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a refresh with no tags says so', (tester) async {
    stubTags(<String>[]);

    final container = scaffold.makeContainer();
    container.read(ticketIdProvider.notifier).setTicketId('gen-1');
    container.read(productIdProvider.notifier).setProductId('prod-1');

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/purchases/user_list',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);

    await tester.drag(find.byType(Refresher), const Offset(0, 1500));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.fling(find.byType(Refresher), const Offset(0, 300), 1000);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);

    expect(find.text('Aucun tag disponible'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a refresh without the ticket ids loads nothing', (tester) async {
    stubTags(['VIP']);

    // The page is reachable without the scan page having set its ids: both
    // maybeWhen arms fall through (orElse) instead of calling loadTags.
    final container = scaffold.makeContainer();
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/purchases/user_list',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);

    await tester.drag(find.byType(Refresher), const Offset(0, 1500));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.fling(find.byType(Refresher), const Offset(0, 300), 1000);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);

    // No tags were requested, so the loader state stands and nothing throws.
    verifyNever(
      () => scaffold.repository
          .cdrSellersSellerIdProductsProductIdTagsGeneratorIdGet(
            sellerId: any(named: 'sellerId'),
            productId: any(named: 'productId'),
            generatorId: any(named: 'generatorId'),
          ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a chip tapped without the ticket ids loads no users', (
    tester,
  ) async {
    // Tags are loaded ONCE and kept in a module-level provider, while the two
    // ids live in their own providers and are only set when the scan page
    // hands them over. A user who scanned earlier and comes back to this page
    // by its own route therefore sees the chips with no ids behind them: both
    // nested `maybeWhen` fall through instead of asking for a tag's users.
    stubTags(['VIP']);
    final container = scaffold.makeContainer();
    await container
        .read(tagListProvider.notifier)
        .loadTags('seller-1', 'prod-1', 'gen-1');
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/purchases/user_list',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);

    expect(find.text('VIP'), findsOneWidget);

    await tester.tap(find.text('VIP'));
    await settle(tester, frames: 10);

    verifyNever(
      () => scaffold.repository
          .cdrSellersSellerIdProductsProductIdTicketsGeneratorIdListsTagGet(
            sellerId: any(named: 'sellerId'),
            productId: any(named: 'productId'),
            generatorId: any(named: 'generatorId'),
            tag: any(named: 'tag'),
          ),
    );
    // The chip still turns selected: the fallback guards the request only.
    expect(find.text('VIP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a chip tapped with a product but no ticket loads no users', (
    tester,
  ) async {
    stubTags(['VIP']);
    final container = scaffold.makeContainer();
    await container
        .read(tagListProvider.notifier)
        .loadTags('seller-1', 'prod-1', 'gen-1');
    // Only half the hand-over happened: the scan page sets the product id
    // first, so the inner fallback (the ticket id) is the one that answers.
    container.read(productIdProvider.notifier).setProductId('prod-1');
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/purchases/user_list',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);

    await tester.tap(find.text('VIP'));
    await settle(tester, frames: 10);

    verifyNever(
      () => scaffold.repository
          .cdrSellersSellerIdProductsProductIdTicketsGeneratorIdListsTagGet(
            sellerId: any(named: 'sellerId'),
            productId: any(named: 'productId'),
            generatorId: any(named: 'generatorId'),
            tag: any(named: 'tag'),
          ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pull with a product but no ticket id reloads nothing', (
    tester,
  ) async {
    stubTags(['VIP']);
    final container = scaffold.makeContainer();

    // Both ids are set by the scan page's list bullet, but nothing keeps them
    // in step: a page rebuilt after only the product was chosen reaches the
    // inner guard with no ticket id, and must not ask for tags without it.
    container.read(productIdProvider.notifier).setProductId('prod-1');
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/purchases/user_list',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);

    final refresher = tester.widget<Refresher>(
      find.descendant(
        of: find.byType(UserListPage),
        matching: find.byType(Refresher),
      ),
    );
    await tester.runAsync(() async {
      await refresher.onRefresh();
    });
    await settle(tester, frames: 8);

    // The pull fell through both id guards instead of asking for the tags.
    verifyNever(
      () => scaffold.repository
          .cdrSellersSellerIdProductsProductIdTagsGeneratorIdGet(
            sellerId: any(named: 'sellerId'),
            productId: any(named: 'productId'),
            generatorId: any(named: 'generatorId'),
          ),
    );
    expect(tester.takeException(), isNull);
  });
}
