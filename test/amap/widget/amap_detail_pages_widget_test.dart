import 'dart:async';
import 'dart:ui' as ui;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/amap/providers/cash_list_provider.dart';
import 'package:titan/amap/providers/delivery_id_provider.dart';
import 'package:titan/amap/providers/user_order_list_provider.dart';
import 'package:titan/amap/providers/delivery_order_list_provider.dart';
import 'package:titan/amap/providers/delivery_product_list_provider.dart';
import 'package:titan/amap/providers/order_provider.dart';
import 'package:titan/amap/ui/components/order_ui.dart';
import 'package:titan/amap/ui/components/product_ui.dart';
import 'package:titan/amap/ui/pages/detail_delivery_page/detail_page.dart'
    as delivery_detail;
import 'package:titan/amap/ui/pages/detail_delivery_page/order_detail_ui.dart';
import 'package:titan/amap/ui/pages/detail_page/detail_page.dart'
    as order_detail;
import 'package:titan/amap/ui/pages/presentation_page/text.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/widgets/loader.dart';

import '../../shared/app_scaffold.dart';

/// The three amap pages the integration sweep never deep-links (they sat at
/// 0 % coverage), mounted routerless through pumpWidgetApp.
///
/// They only read `QR.currentPath` inside TopBar — where `'/'` vs the amap
/// root merely swaps the back button for the info icon, and no test taps
/// either — so the widget shell is honest here and every test is independent
/// of the one-deep-link-per-file rule (README conventions 1 and 11).
///
/// - the presentation page: the contact paragraph, its tappable association
///   link (real browser launch) and the three `information.when` branches,
/// - the delivery detail page: the delivery date, the per-category quantity
///   rollup, the three order-slot states (null / empty / loaded) and the
///   delete-your-own-order flow (refund + toast),
/// - the order detail page: full product cards + the order card, with and
///   without product details.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// AutoSizeText renders as a RichText the `find.text` family never matches
  /// (README convention 5), so its content is asserted through the widget.
  Finder autoText(String contains) => find.byWidgetPredicate(
    (w) => w is AutoSizeText && (w.data?.contains(contains) ?? false),
  );

  const linkUrl = 'https://amap.example.org/contact';

  final honey = AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
    id: 'p-1',
    name: 'Honey jar',
    category: 'Fruits',
    price: 350,
  );
  final jam = AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
    id: 'p-2',
    name: 'Jam jar',
    category: 'Fruits',
    price: 150,
  );
  final delivery = DeliveryReturn.empty().copyWith(
    id: 'd-1',
    deliveryDate: DateTime(2100, 12, 31),
    products: [honey, jam],
  );
  final user = CoreUserSimple.empty().copyWith(
    id: 'u-1',
    name: 'Doe',
    firstname: 'Jane',
  );
  final order = OrderReturn.empty().copyWith(
    orderId: 'o-1',
    deliveryId: 'd-1',
    amount: 750,
    deliveryDate: DateTime(2100, 12, 31),
    user: user,
    productsdetail: [
      ProductQuantity(quantity: 2, product: honey),
      ProductQuantity(quantity: 1, product: jam),
    ],
  );
  final cash = AppModulesAmapSchemasAmapCashComplete.empty().copyWith(
    balance: 42,
    userId: 'u-1',
    user: user,
  );

  /// Taps exactly on the association link's glyphs: the span's
  /// TapGestureRecognizer only fires when the tap maps onto ITS span, so
  /// tapping the paragraph's center would land on presentation1 instead.
  Future<void> tapLinkSpan(WidgetTester tester) async {
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains(linkUrl),
      ),
    );
    final text = paragraph.text.toPlainText();
    final caret = paragraph.getOffsetForCaret(
      TextPosition(offset: text.indexOf(linkUrl) + linkUrl.length ~/ 2),
      Rect.zero,
    );
    await tester.tapAt(paragraph.localToGlobal(caret + const Offset(2, 8)));
    await tester.pump();
  }

  group('PresentationPage', () {
    void stubInformation(Information info) {
      when(() => scaffold.repository.amapInformationGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('[]', 200), info),
      );
    }

    testWidgets(
      'renders the contact and opens the association link in a browser',
      (tester) async {
        final fake = FakeUrlLauncher();
        stubUrlLauncher(fake);
        stubInformation(
          Information(
            manager: 'Jane Doe',
            link: linkUrl,
            description: 'Who we are',
          ),
        );

        final container = scaffold.makeContainer();
        addTearDown(container.dispose);
        await scaffold.pumpWidgetApp(
          tester,
          const PresentationPage(),
          container,
          surface: const ui.Size(1920, 1080),
          appFonts: true,
        );

        expect(
          find.textContaining('Association contacts : Jane Doe'),
          findsOneWidget,
        );
        expect(
          find.textContaining(linkUrl, findRichText: true),
          findsOneWidget,
        );

        await tapLinkSpan(tester);

        expect(fake.launched, [linkUrl]);
      },
    );

    testWidgets('a failing browser launch shows the link error toast', (
      tester,
    ) async {
      final fake = FakeUrlLauncher(
        launchError: const FormatException('no browser'),
      );
      stubUrlLauncher(fake);
      stubInformation(
        Information(
          manager: 'Jane Doe',
          link: linkUrl,
          description: 'Who we are',
        ),
      );

      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      await scaffold.pumpWidgetApp(
        tester,
        const PresentationPage(),
        container,
        surface: const ui.Size(1920, 1080),
        appFonts: true,
      );

      await tapLinkSpan(tester);
      // The toast's pop-in animation needs a beat before it is rendered.
      await tester.pump(const Duration(milliseconds: 600));

      // The toast sits inside the wrapper's overlay theater mid-entrance,
      // which the default offstage-pruning finder skips at this exact frame.
      expect(
        find.text('Error opening link', skipOffstage: false),
        findsOneWidget,
      );

      // Drain the toast's auto-close timer before the test ends.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    });

    testWidgets('shows the red loading placeholder until information arrives', (
      tester,
    ) async {
      when(() => scaffold.repository.amapInformationGet())
          .thenAnswer((_) => Completer<chopper.Response<Information>>().future);

      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      await scaffold.pumpWidgetApp(
        tester,
        const PresentationPage(),
        container,
        surface: const ui.Size(1920, 1080),
        appFonts: true,
      );

      expect(
        find.textContaining('Loading...', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets(
      'a failed information load reddens the paragraph and errors the child',
      (tester) async {
        // Async, not `thenThrow`: a sync throw would fire INSIDE the
        // provider's own build, where SingleNotifierAPI's `ref.mounted`
        // guard skips the error state write (production repositories always
        // reject through a future, never synchronously).
        when(() => scaffold.repository.amapInformationGet())
            .thenAnswer((_) async => throw Exception('boom'));

        final container = scaffold.makeContainer();
        addTearDown(container.dispose);
        await scaffold.pumpWidgetApp(
          tester,
          const PresentationPage(),
          container,
          surface: const ui.Size(1920, 1080),
          appFonts: true,
        );

        expect(
          find.textContaining('Loading error', findRichText: true),
          findsOneWidget,
        );
        expect(find.textContaining('An error occured'), findsOneWidget);
      },
    );
  });

  group('DetailDeliveryPage', () {
    /// Everything the delivery detail page loads on mount: the delivery list
    /// (for the delivery id), the cash list (per-card balance) and the
    /// signed-in user's own orders (the delete flow's index lookup).
    void stubAmapLoads() {
      when(() => scaffold.repository.amapDeliveriesGet())
          .thenAnswer((_) async => chopperListResponse([delivery]));
      when(() => scaffold.repository.amapUsersCashGet())
          .thenAnswer((_) async => chopperListResponse([cash]));
      when(
        () => scaffold.repository.amapUsersUserIdOrdersGet(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => chopperListResponse([order]));
      when(
        () => scaffold.repository.amapUsersUserIdCashGet(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => chopperResponse(cash));
    }

    Future<ProviderContainer> pumpDeliveryPage(WidgetTester tester) async {
      final container = scaffold.makeContainer(userId: 'user-1');
      addTearDown(container.dispose);
      // Seed the delivery id and the product list BEFORE mount so the page's
      // derived providers resolve on the first frame.
      container.read(deliveryIdProvider.notifier).setId('d-1');
      await container
          .read(deliveryProductListProvider.notifier)
          .loadProductList([honey, jam]);
      await scaffold.pumpWidgetApp(
        tester,
        const delivery_detail.DetailDeliveryPage(),
        container,
        surface: const ui.Size(1920, 1080),
        appFonts: true,
      );
      // DetailOrderUI snapshots the user's order list when it builds (the
      // dialog's delete-index lookup reads that snapshot): wait for the load
      // BEFORE any card exists, or the card captures a loading state, the
      // index comes back -1 and the slot map never drops the order.
      for (
        var i = 0;
        i < 20 && !container.read(userOrderListProvider).hasValue;
        i++
      ) {
        await tester.pump();
      }
      expect(
        container.read(userOrderListProvider).hasValue,
        isTrue,
        reason: 'the user order list must resolve before any card mounts',
      );
      return container;
    }

    testWidgets(
      'renders the date, quantity rollup and the three order-slot states',
      (tester) async {
        stubAmapLoads();
        final container = await pumpDeliveryPage(tester);

        expect(find.text('Delivery date : 12/31/2100'), findsOneWidget);
        expect(find.text('Products :'), findsOneWidget);
        expect(find.text('Fruits'), findsOneWidget);
        expect(autoText('Honey jar'), findsOneWidget);
        expect(autoText('Jam jar'), findsOneWidget);
        // The quantity rollup only counts LOADED orders; with the slot still
        // on its loader both cards read zero.
        expect(autoText('Quantity : 0'), findsNWidgets(2));
        expect(autoText('0.00 €'), findsNWidgets(2));
        expect(find.text('Orders :'), findsOneWidget);

        // No order list loaded yet: the page keeps the orders slot on its
        // loader (the `orders == null` branch).
        expect(find.byType(Loader), findsOneWidget);

        container
            .read(adminDeliveryOrderListProvider.notifier)
            .setTData('d-1', const AsyncValue.data(<OrderReturn>[]));
        await tester.pump();
        expect(find.text('No order'), findsOneWidget);

        container
            .read(adminDeliveryOrderListProvider.notifier)
            .setTData('d-1', AsyncValue.data([order]));
        await tester.pump();

        // With the order loaded, the SAME cards now roll its quantities up
        // (2 honey + 1 jam) into their prices.
        expect(autoText('Quantity : 2'), findsOneWidget);
        expect(autoText('700.00 €'), findsOneWidget);
        expect(autoText('Quantity : 1'), findsOneWidget);
        expect(autoText('150.00 €'), findsOneWidget);

        expect(find.byType(DetailOrderUI), findsOneWidget);
        expect(autoText('Jane Doe'), findsOneWidget);
        // The card counts QUANTITIES (2 honey + 1 jam), not lines.
        expect(find.text('3 products'), findsOneWidget);
        expect(find.text('750.00€'), findsOneWidget);
        expect(find.text('2 (700.00€)'), findsOneWidget);
        expect(find.text('1 (150.00€)'), findsOneWidget);
        expect(find.text('Balance : 42.00€'), findsOneWidget);
      },
    );

    testWidgets(
      'deleting your own order refunds the balance, empties the slot, toasts',
      (tester) async {
        stubAmapLoads();
        when(
          () => scaffold.repository.amapOrdersOrderIdDelete(
            orderId: any(named: 'orderId'),
          ),
        ).thenAnswer((_) async => chopperResponseVoid());
        final container = await pumpDeliveryPage(tester);
        container
            .read(adminDeliveryOrderListProvider.notifier)
            .setTData('d-1', AsyncValue.data([order]));
        await tester.pump();
        expect(find.byType(DetailOrderUI), findsOneWidget);

        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is HeroIcon && w.icon == HeroIcons.trash,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Delete order?'), findsOneWidget);
        expect(find.text('Confirm'), findsOneWidget);

        await tester.tap(find.text('Confirm'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        verify(
          () => scaffold.repository.amapOrdersOrderIdDelete(orderId: 'o-1'),
        ).called(1);
        // The slot map entry lost its only order back to an empty list.
        expect(find.text('No order'), findsOneWidget);
        // The 750 order amount went back on the 42 balance. The refunded card
        // itself is gone with the order, so the refund is asserted on the
        // cash list the card read its balance from.
        final balances = container
            .read(cashListProvider)
            .maybeWhen(
              data: (l) => l.map((c) => c.balance).toList(),
              orElse: () => const <int>[],
            );
        expect(balances, [792]);
        // Same overlay-theater staging as the presentation page's toast: the
        // default offstage-pruning finder still skips it at this frame.
        expect(find.text('Order deleted', skipOffstage: false), findsOneWidget);

        // Drain the toast's auto-close timer before the test ends.
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
      },
    );
  });

  group('DetailOrderPage DetailPage', () {
    void stubOrderLoads() {
      when(
        () => scaffold.repository.amapUsersUserIdOrdersGet(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => chopperListResponse([order]));
      when(
        () => scaffold.repository.amapUsersUserIdCashGet(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => chopperResponse(cash));
    }

    Future<void> pumpOrderPage(
      WidgetTester tester, {
      required OrderReturn seeded,
    }) async {
      final container = scaffold.makeContainer(userId: 'user-1');
      addTearDown(container.dispose);
      // Edit-mode mounts read straight from the seeded provider (no deep
      // link needed for routerless mounting anyway).
      container.read(orderProvider.notifier).setOrder(seeded);
      await scaffold.pumpWidgetApp(
        tester,
        const order_detail.DetailPage(),
        container,
        surface: const ui.Size(1920, 1080),
        appFonts: true,
      );
    }

    testWidgets(
      'renders the product cards and the order card for a full order',
      (tester) async {
        stubOrderLoads();
        await pumpOrderPage(tester, seeded: order);

        expect(find.byType(ProductCard), findsNWidgets(2));
        expect(autoText('Honey jar'), findsOneWidget);
        expect(autoText('Quantity : 2'), findsOneWidget);
        expect(find.byType(OrderUI), findsOneWidget);
        expect(find.textContaining('12/31/2100'), findsWidgets);
        expect(find.textContaining('products'), findsWidgets);
      },
    );

    testWidgets('an order without product details renders no product card', (
      tester,
    ) async {
      stubOrderLoads();
      await pumpOrderPage(
        tester,
        seeded: OrderReturn.empty().copyWith(
          orderId: 'o-2',
          deliveryId: 'd-1',
          deliveryDate: DateTime(2100, 12, 31),
        ),
      );

      expect(find.byType(ProductCard), findsNothing);
      expect(find.byType(OrderUI), findsOneWidget);
    });
  });
}
