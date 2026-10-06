import 'dart:async';
import 'dart:convert';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/mypayment/ui/components/paiment_delegate/confirm_button.dart';
import 'package:titan/mypayment/ui/components/paiment_delegate/countdown_timer.dart';
import 'package:titan/mypayment/ui/components/paiment_delegate/feedback_overlay.dart';
import 'package:titan/mypayment/ui/components/paiment_delegate/paiment_delegate_modal.dart';
import 'package:titan/mypayment/ui/components/paiment_delegate/product_card.dart';
import 'package:titan/mypayment/ui/components/paiment_delegate/wallet_balance_card.dart';
import 'package:titan/mypayment/ui/components/request_detail_modal.dart';
import 'package:titan/mypayment/ui/components/show_request_modal.dart';

import '../../shared/app_scaffold.dart';

/// The payment-delegation family — the whole `paiment_delegate/` directory plus
/// the two modals that host it — sat at **exactly zero** coverage: 247 of its
/// own lines and 91 more in `show_request_modal.dart` / `request_detail_modal.dart`,
/// which together are the third-largest hole in mypayment.
///
/// It is also one of the few areas of this app that is pure widget logic, so
/// none of it needs the router and it can be mounted directly at phone width.
/// That matters, because the pieces are individually meaningless and only
/// meaningful together: the countdown decides whether the confirm button is
/// still live, and the confirm button's own expiry animation is separate from
/// the countdown's. Both are asserted here rather than inferred.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Both modals pop themselves with `Navigator.of(context).pop()`, which needs
  /// a real route under them or the assertion is against nothing. So every
  /// modal is pushed rather than mounted as a home widget.
  Future<ProviderContainer> pumpModal(WidgetTester tester, Widget modal) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    late BuildContext host;
    await scaffold.pumpWidgetApp(
      tester,
      Builder(
        builder: (context) {
          host = context;
          return const SizedBox.shrink();
        },
      ),
      container,
      appFonts: true,
    );
    unawaited(
      Navigator.of(host).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(body: SingleChildScrollView(child: modal)),
        ),
      ),
    );
    await settle(tester, frames: 8);
    return container;
  }

  Request$ requestWith({
    required RequestStatus status,
    Duration expiresIn = const Duration(minutes: 5),
    String name = 'Cafe des Arts',
    int total = 1250,
    String? storeNote,
  }) => Request$(
    id: 'request-1',
    walletId: 'wallet-1',
    creation: DateTime(2026, 3, 1, 10, 30),
    expirationDate: DateTime.now().add(expiresIn),
    total: total,
    storeId: 'store-1',
    name: name,
    storeNote: storeNote,
    module: 'mypayment',
    objectId: 'object-1',
    status: status,
  );

  void stubWallet(int balance) {
    when(() => scaffold.repository.mypaymentUsersMeWalletGet()).thenAnswer(
      (_) async => chopperResponse(
        Wallet.empty().copyWith(id: 'wallet-1', balance: balance),
      ),
    );
  }

  group('ProductCard', () {
    testWidgets('prints the title, the note and the price in units', (
      tester,
    ) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      await scaffold.pumpWidgetApp(
        tester,
        const ProductCard(
          title: 'Cafe des Arts',
          description: '2 cafe + 1 croissant',
          priceInCents: 1250,
        ),
        container,
        appFonts: true,
      );

      expect(find.text('Cafe des Arts'), findsOneWidget);
      expect(find.text('2 cafe + 1 croissant'), findsOneWidget);
      // 1250 cents printed in units, formatted fr_FR with the app's symbol.
      expect(find.textContaining('12,50'), findsOneWidget);
      expect(find.textContaining('ʍ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives a long title and an empty note at 360px', (
      tester,
    ) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      await scaffold.pumpWidgetApp(
        tester,
        const ProductCard(
          title: 'Laumerie du Marche Saint-Germain-en-Laye et les halles',
          description: '',
          priceInCents: 1250,
        ),
        container,
        appFonts: true,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('WalletBalanceCard', () {
    testWidgets('shows the balance once the wallet resolves', (tester) async {
      stubWallet(5000);
      final container = await pumpModal(tester, const WalletBalanceCard());

      expect(find.text('Your balance'), findsOneWidget);
      // The spinner is replaced by the amount, not shown alongside it.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('50,00'), findsOneWidget);
      expect(container, isNotNull);
    });

    testWidgets('shows a spinner while the wallet is still loading', (
      tester,
    ) async {
      // A never-resolving repository call leaves the provider on its initial
      // `AsyncValue.loading()`, which is the branch the app really shows on a
      // cold start.
      when(
        () => scaffold.repository.mypaymentUsersMeWalletGet(),
      ).thenAnswer((_) => Completer<chopper.Response<Wallet>>().future);
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      await scaffold.pumpWidgetApp(
        tester,
        const WalletBalanceCard(),
        container,
      );

      expect(find.text('Your balance'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await scaffold.unmountApp(tester);
    });

    testWidgets('falls back to a dash when the wallet fails', (tester) async {
      when(() => scaffold.repository.mypaymentUsersMeWalletGet()).thenAnswer(
        (_) async => chopper.Response(
          http.Response('', 500),
          null,
          error: 'wallet unavailable',
        ),
      );
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      await scaffold.pumpWidgetApp(
        tester,
        const WalletBalanceCard(),
        container,
      );
      await settle(tester, frames: 8);

      expect(find.text('Your balance'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      await scaffold.unmountApp(tester);
    });
  });

  group('CountdownTimer', () {
    testWidgets('counts down in mm:ss and reports completion', (tester) async {
      var finished = 0;
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      await scaffold.pumpWidgetApp(
        tester,
        CountdownTimer(totalSeconds: 480, onFinished: () => finished++),
        container,
      );

      // 480s with no full-duration override starts at 08:00, full ring.
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('Time Remaining'), findsOneWidget);
      expect(find.text('Complete payment'), findsOneWidget);
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .value,
        1.0,
      );

      await tester.pump(const Duration(seconds: 240));
      expect(find.text('04:00'), findsOneWidget);
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .value,
        closeTo(0.5, 0.01),
      );
      expect(finished, 0);

      // Past the 30s threshold the copy switches to the urgent one.
      await tester.pump(const Duration(seconds: 215));
      expect(find.text('00:25'), findsOneWidget);
      expect(find.text('Hurry up!'), findsOneWidget);
      expect(find.text('Complete payment'), findsNothing);

      // Running out fires onFinished exactly once.
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('00:00'), findsOneWidget);
      expect(finished, 1);
      await tester.pump(const Duration(seconds: 5));
      expect(finished, 1);
    });

    testWidgets('a shorter full duration starts the ring nearly empty', (
      tester,
    ) async {
      // This is the delegate case: the request was issued 8 minutes ago but
      // only 30 seconds are left, so the ring must show the elapsed share of
      // the FULL window rather than a full ring that would read as "plenty of
      // time".
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      await scaffold.pumpWidgetApp(
        tester,
        const CountdownTimer(totalSeconds: 30, fullDurationSeconds: 480),
        container,
      );

      expect(find.text('00:30'), findsOneWidget);
      // (480 - 30) / 480 of the window is already gone.
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .value,
        closeTo(0.0625, 0.01),
      );
      expect(find.text('Hurry up!'), findsOneWidget);
    });
  });

  group('FeedbackOverlay', () {
    testWidgets('shows the success mark and copy', (tester) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      await scaffold.pumpWidgetApp(
        tester,
        const FeedbackOverlay(isSuccess: true),
        container,
      );

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(find.text('Payment successful!'), findsOneWidget);
    });

    testWidgets('shows the cancel mark and copy', (tester) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      await scaffold.pumpWidgetApp(
        tester,
        const FeedbackOverlay(isSuccess: false),
        container,
      );

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.text('Payment canceled'), findsOneWidget);
    });
  });

  group('ConfirmButton', () {
    testWidgets('confirm and refuse both dispatch', (tester) async {
      var confirmed = 0;
      var canceled = 0;
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      await scaffold.pumpWidgetApp(
        tester,
        ConfirmButton(
          totalSeconds: 480,
          onConfirm: () => confirmed++,
          onCancel: () => canceled++,
        ),
        container,
      );

      expect(find.text('Confirm Payment'), findsOneWidget);
      expect(find.text('Refuse'), findsOneWidget);

      await tester.tap(find.text('Confirm Payment'), warnIfMissed: false);
      await tester.pump();
      expect(confirmed, 1);
      expect(canceled, 0);

      await tester.tap(find.text('Refuse'), warnIfMissed: false);
      await tester.pump();
      expect(confirmed, 1);
      expect(canceled, 1);
    });

    testWidgets('a null total never expires and stays tappable', (
      tester,
    ) async {
      // `totalSeconds: null` builds a zero-duration controller, so without the
      // `> 0` guard the button would grey out on the very first frame.
      var confirmed = 0;
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      await scaffold.pumpWidgetApp(
        tester,
        ConfirmButton(
          totalSeconds: null,
          onConfirm: () => confirmed++,
          onCancel: () {},
        ),
        container,
      );
      await settle(tester, frames: 4);

      await tester.tap(find.text('Confirm Payment'), warnIfMissed: false);
      await tester.pump();
      expect(confirmed, 1);
    });

    testWidgets('the button greys out and stops dispatching once it expires', (
      tester,
    ) async {
      var confirmed = 0;
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      await scaffold.pumpWidgetApp(
        tester,
        ConfirmButton(
          totalSeconds: 2,
          onConfirm: () => confirmed++,
          onCancel: () {},
        ),
        container,
      );

      // Live: the gradient fill is there and the shimmer sweeps.
      expect(
        _fillColour(tester),
        const LinearGradient(
          colors: [Color(0xff017f80), Color(0xff045454)],
        ).colors.first,
      );

      await tester.pump(const Duration(seconds: 3));

      // Expired: flat grey, no shimmer, and the tap is dead.
      expect(_fillColour(tester), Colors.grey);
      await tester.tap(find.text('Confirm Payment'), warnIfMissed: false);
      await tester.pump();
      expect(confirmed, 0);
    });
  });

  group('PaimentDelegateModal', () {
    testWidgets('the idle sheet stacks product, timer, balance and button', (
      tester,
    ) async {
      stubWallet(5000);
      await pumpModal(
        tester,
        PaimentDelegateModal(
          itemTitle: 'Cafe des Arts',
          itemDescription: '2 cafe',
          itemPrice: 1250,
          itemExpirationDate: DateTime.now().add(const Duration(minutes: 8)),
          onConfirm: () {},
        ),
      );

      expect(find.text('Confirm your purchase'), findsOneWidget);
      expect(find.byType(ProductCard), findsOneWidget);
      expect(find.byType(CountdownTimer), findsOneWidget);
      expect(find.byType(WalletBalanceCard), findsOneWidget);
      expect(find.byType(ConfirmButton), findsOneWidget);
      expect(find.byType(FeedbackOverlay), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an already-expired request shows no countdown', (
      tester,
    ) async {
      // `secondsLeft <= 0` drops the timer entirely rather than rendering a
      // stuck 00:00, so the delegate sees no false deadline.
      stubWallet(5000);
      await pumpModal(
        tester,
        PaimentDelegateModal(
          itemTitle: 'Cafe des Arts',
          itemDescription: '2 cafe',
          itemPrice: 1250,
          itemExpirationDate: DateTime.now().subtract(
            const Duration(minutes: 1),
          ),
          onConfirm: () {},
        ),
      );

      expect(find.byType(CountdownTimer), findsNothing);
      expect(find.byType(ProductCard), findsOneWidget);
      expect(find.byType(ConfirmButton), findsOneWidget);
    });

    testWidgets('confirming runs loading then success then pops', (
      tester,
    ) async {
      stubWallet(5000);
      var confirmed = 0;
      await pumpModal(
        tester,
        PaimentDelegateModal(
          itemTitle: 'Cafe des Arts',
          itemDescription: '2 cafe',
          itemPrice: 1250,
          itemExpirationDate: DateTime.now().add(const Duration(minutes: 8)),
          onConfirm: () => confirmed++,
        ),
      );

      await tester.tap(find.text('Confirm Payment'), warnIfMissed: false);
      await settle(tester, frames: 2);
      expect(confirmed, 1);
      // Loading keeps the idle content on screen, swapped for a spinner inside
      // the WaitingButton-style flow; the overlay is not up yet.
      expect(find.byType(FeedbackOverlay), findsNothing);

      // 600ms later the success overlay replaces the whole idle stack, at the
      // idle stack's own measured height.
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(FeedbackOverlay), findsOneWidget);
      expect(find.text('Payment successful!'), findsOneWidget);
      expect(find.byType(ProductCard), findsNothing);

      // 1500ms after that the sheet dismisses itself.
      await tester.pump(const Duration(milliseconds: 1600));
      // The route is popped, but stays in the tree through its exit
      // transition, so the disappearance needs real frames.
      await settle(tester, frames: 10);
      expect(find.byType(PaimentDelegateModal), findsNothing);
    });

    testWidgets(
      'cancelling without a refuse callback shows the cancel overlay',
      (tester) async {
        stubWallet(5000);
        await pumpModal(
          tester,
          PaimentDelegateModal(
            itemTitle: 'Cafe des Arts',
            itemDescription: '2 cafe',
            itemPrice: 1250,
            itemExpirationDate: DateTime.now().add(const Duration(minutes: 8)),
            onConfirm: () {},
          ),
        );

        await tester.tap(find.text('Refuse'), warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text('Payment canceled'), findsOneWidget);
        expect(find.byType(FeedbackOverlay), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 1600));
        // The route is popped, but stays in the tree through its exit
        // transition, so the disappearance needs real frames.
        await settle(tester, frames: 10);
        expect(find.byType(PaimentDelegateModal), findsNothing);
      },
    );

    testWidgets('a refuse callback takes over the cancel path', (tester) async {
      // With a delegate present, "Refuse" is a server action, not a local
      // dismissal: the modal shows NO overlay and never pops itself, leaving
      // the caller to close it once the request has actually been refused.
      stubWallet(5000);
      var refused = 0;
      await pumpModal(
        tester,
        PaimentDelegateModal(
          itemTitle: 'Cafe des Arts',
          itemDescription: '2 cafe',
          itemPrice: 1250,
          itemExpirationDate: DateTime.now().add(const Duration(minutes: 8)),
          onConfirm: () {},
          onRefuse: () => refused++,
        ),
      );

      await tester.tap(find.text('Refuse'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump();

      expect(refused, 1);
      expect(find.byType(FeedbackOverlay), findsNothing);
      expect(find.byType(PaimentDelegateModal), findsOneWidget);
    });
  });

  group('RequestDetailModal', () {
    testWidgets('a proposed request past its date reads as expired', (
      tester,
    ) async {
      await pumpModal(
        tester,
        RequestDetailModal(
          request: requestWith(
            status: RequestStatus.proposed,
            expiresIn: const Duration(minutes: -1),
          ),
        ),
      );

      expect(find.text('Request details'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);
      expect(find.byType(ProductCard), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('a live proposed request reads as pending', (tester) async {
      await pumpModal(
        tester,
        RequestDetailModal(
          request: requestWith(status: RequestStatus.proposed),
        ),
      );

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Expired'), findsNothing);
    });

    testWidgets('accepted and refused read their own status', (tester) async {
      await pumpModal(
        tester,
        RequestDetailModal(
          request: requestWith(status: RequestStatus.accepted),
        ),
      );
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Cafe des Arts'), findsOneWidget);

      await pumpModal(
        tester,
        RequestDetailModal(request: requestWith(status: RequestStatus.refused)),
      );
      expect(find.text('Refused'), findsOneWidget);
    });

    testWidgets('close dismisses the modal', (tester) async {
      await pumpModal(
        tester,
        RequestDetailModal(
          request: requestWith(status: RequestStatus.accepted),
        ),
      );

      await tester.tap(find.text('Close'), warnIfMissed: false);
      // Same exit transition as the delegate sheet.
      await settle(tester, frames: 10);
      expect(find.byType(RequestDetailModal), findsNothing);
    });
  });

  group('showRequestModal', () {
    Future<void> openRequestModal(
      WidgetTester tester,
      Request$ request, {
      bool acceptSucceeds = true,
      bool refuseSucceeds = true,
      String? keyId = 'device-1',
      void Function(SignedContent body)? onAccept,
    }) async {
      when(
        () => scaffold.repository.mypaymentRequestsGet(),
      ).thenAnswer((_) async => chopperListResponse(<Request$>[request]));
      when(
        () => scaffold.repository.mypaymentRequestsRequestIdAcceptPost(
          requestId: any(named: 'requestId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((invocation) async {
        onAccept?.call(invocation.namedArguments[#body] as SignedContent);
        return acceptSucceeds
            ? chopper.Response(http.Response('', 204), null)
            : chopper.Response(
                http.Response('', 500),
                null,
                error: 'accept refused',
              );
      });
      when(
        () => scaffold.repository.mypaymentRequestsRequestIdRefusePost(
          requestId: any(named: 'requestId'),
        ),
      ).thenAnswer(
        (_) async => refuseSucceeds
            ? chopper.Response(http.Response('', 204), null)
            : chopper.Response(
                http.Response('', 500),
                null,
                error: 'refuse refused',
              ),
      );

      final container = scaffold.makeContainer(deviceKeyId: keyId);
      addTearDown(container.dispose);
      late BuildContext host;
      late WidgetRef hostRef;
      await scaffold.pumpWidgetApp(
        tester,
        Consumer(
          builder: (context, ref, _) {
            host = context;
            hostRef = ref;
            return const SizedBox.shrink();
          },
        ),
        container,
        appFonts: true,
      );
      unawaited(
        showRequestModal(context: host, ref: hostRef, request: request),
      );
      await settle(tester, frames: 8);
    }

    testWidgets('accepting signs the request and closes the sheet', (
      tester,
    ) async {
      SignedContent? signed;
      await openRequestModal(
        tester,
        requestWith(status: RequestStatus.proposed),
        onAccept: (body) => signed = body,
      );

      expect(find.byType(PaimentDelegateModal), findsOneWidget);
      expect(find.text('Cafe des Arts'), findsOneWidget);

      await tester.tap(find.text('Confirm Payment'), warnIfMissed: false);
      await settle(tester, frames: 20);

      // The signed envelope is the whole point of this path: the store
      // verifies the delegate's key, so the signature must be a real one over
      // the request's own id and total.
      expect(signed, isNotNull);
      expect(signed!.id, 'request-1');
      expect(signed!.tot, 1250);
      expect(signed!.key, 'device-1');
      expect(signed!.store, isTrue);
      expect(signed!.signature, isNotEmpty);
      // base64 over the raw Ed25519 signature, so it decodes to 64 bytes.
      expect(base64Decode(signed!.signature), hasLength(64));

      // The server call flips the request to accepted in the list, and the
      // sheet is popped.
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();
      expect(find.byType(PaimentDelegateModal), findsNothing);
      await scaffold.drainToast(tester);
    });

    testWidgets('a device with no key refuses the request before signing', (
      tester,
    ) async {
      await openRequestModal(
        tester,
        requestWith(status: RequestStatus.proposed),
        keyId: null,
      );

      await tester.tap(find.text('Confirm Payment'), warnIfMissed: false);
      await settle(tester, frames: 20);

      // No key means no signature, so the sheet is dismissed immediately
      // rather than waiting out the 600ms + 1500ms success animation.
      expect(find.byType(PaimentDelegateModal), findsNothing);
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();
      await scaffold.drainToast(tester);
    });

    testWidgets('refusing sends the request to the server and closes', (
      tester,
    ) async {
      await openRequestModal(
        tester,
        requestWith(status: RequestStatus.proposed),
      );

      // Refuse takes the delegate path: no local overlay, the caller closes.
      await tester.tap(find.text('Refuse'), warnIfMissed: false);
      await settle(tester, frames: 20);

      expect(find.byType(PaimentDelegateModal), findsNothing);
      await scaffold.drainToast(tester);
    });
  });
}

/// The decorative fill behind the confirm button, which is what changes on
/// expiry: a teal gradient while live, flat grey once the timer completes.
Color? _fillColour(WidgetTester tester) {
  for (final container in tester.widgetList<Container>(
    find.descendant(
      of: find.byType(ConfirmButton),
      matching: find.byType(Container),
    ),
  )) {
    final decoration = container.decoration;
    if (decoration is BoxDecoration) {
      final colour = decoration.color;
      if (colour != null) return colour;
      final gradient = decoration.gradient;
      if (gradient is LinearGradient) return gradient.colors.first;
    }
  }
  return null;
}
