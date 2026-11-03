import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/ui/pages/book_ticket_page.dart';
import 'package:titan/tools/providers/path_forwarding_provider.dart';

import '../../shared/app_scaffold.dart';

/// The three callbacks the booking page hands to the HelloAsso popup.
///
/// The existing web test opens the popup and reports a SUCCESSFUL payment.
/// Nothing ever closed the window, hit the blocked-popup case, or came back
/// with a code other than `succeeded` — so the page's "clear the checkout and
/// go back to /tickets" cleanup, its popup-blocked warning, and its refused
/// payment message had never run.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  EventPublic bookableEvent() => EventPublic.empty().copyWith(
    id: 'evt-1',
    name: 'Gala 2026',
    categories: [
      CategoryPublic.empty().copyWith(id: 'cat-1', name: 'Normal', price: 1000),
    ],
    sessions: [
      SessionPublic.empty().copyWith(
        id: 'ses-1',
        name: 'Saturday',
        startDatetime: DateTime(2026, 1, 11, 20),
      ),
    ],
  );

  /// Books the default category so the page runs its checkout and asks the
  /// opener for a HelloAsso window.
  Future<void> book(WidgetTester tester) async {
    await tester.tap(find.text('Normal'));
    await settle(tester, frames: 6);
    await tester.scrollUntilVisible(
      find.text('Book'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Book'));
    await tester.tap(find.text('Book'));
    await settle(tester, frames: 16);
  }

  /// Boots the booking page on the web path with a captured popup.
  Future<List<_Popup>> pumpWithPopup(WidgetTester tester) async {
    final popups = <_Popup>[];
    void opener(
      String windowUrl,
      String windowName, {
      required void Function() completerFutureCallback,
      required Future<void> Function(String) loginCallback,
      void Function()? popupBlockedCallback,
    }) {
      popups.add(
        _Popup(
          windowUrl,
          windowName,
          loginCallback,
          completerFutureCallback,
          popupBlockedCallback,
        ),
      );
    }

    scaffold.setWideSurface(tester);
    final container = scaffold.makeContainer(
      providerOverrides: [
        bookingIsWebProvider.overrideWith((ref) => true),
        bookingWebWindowOpenerProvider.overrideWith((ref) => opener),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(pathForwardingProvider.notifier)
        .forward('/tickets/book', queryParameters: {'ticketEventId': 'evt-1'});

    when(() => scaffold.repository.ticketsEventsEventIdGet(eventId: 'evt-1'))
        .thenAnswer((_) async => chopperResponse(bookableEvent()));
    when(() => scaffold.repository.mypaymentUsersMeTosGet())
        .thenAnswer((_) async => chopperResponse(TOSSignatureResponse.empty()));
    when(() => scaffold.repository.mypaymentUsersMeWalletGet())
        .thenAnswer((_) async => chopperResponse(Wallet.empty()));
    when(
      () => scaffold.repository.mypaymentUsersMeWalletDevicesWalletDeviceIdGet(
        walletDeviceId: any(named: 'walletDeviceId'),
      ),
    ).thenAnswer((_) async => chopperResponse(WalletDevice.empty()));
    when(() => scaffold.repository.ticketsUserMeTicketsGet()).thenAnswer(
      (_) async =>
          chopperListResponse<AppCoreTicketsSchemasTicketsTicketComplete>([]),
    );
    when(
      () => scaffold.repository.ticketsEventsEventIdCheckoutPost(
        eventId: 'evt-1',
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopperResponse(
        CheckoutResponse.empty().copyWith(
          price: 1000,
          paymentUrl: 'https://helloasso.example/pay',
        ),
      ),
    );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets/book',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);
    await book(tester);
    expect(popups, hasLength(1));
    return popups;
  }

  testWidgets(
    'a blocked popup warns, and closing the window returns to the ticket list',
    (tester) async {
      final popups = await pumpWithPopup(tester);

      // Blocked: the browser refused to open the window at all.
      popups.single.popupBlockedCallback!();
      await settle(tester, frames: 10);
      expect(find.text('Please allow popups'), findsOneWidget);
      await scaffold.drainToast(tester);

      // Closed afterwards without completing: the page drops the pending
      // checkout and sends the user back to their tickets instead of leaving
      // them on a form whose checkout state is already spent.
      popups.single.completerFutureCallback();
      await settle(tester, frames: 16);
      expect(QR.currentPath, '/tickets');
      expect(find.text('Book'), findsNothing);
      await scaffold.unmountApp(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a payment answered with any other code is reported as refused', (
    tester,
  ) async {
    final popups = await pumpWithPopup(tester);

    // Only `code=succeeded` means paid; a cancelled or refused payment comes
    // back with a different value and must not read as a booking.
    await popups.single.loginCallback(
      'https://myemapp.com/static.html?code=refused',
    );
    await settle(tester, frames: 10);

    expect(find.text('Payment refused'), findsOneWidget);
    expect(find.text('Ticket booked successfully!'), findsNothing);
    await scaffold.drainToast(tester);
    await scaffold.unmountApp(tester);
    expect(tester.takeException(), isNull);
  });
}

/// A popup the booking page asked to open, kept instead of opened.
class _Popup {
  _Popup(
    this.windowUrl,
    this.windowName,
    this.loginCallback,
    this.completerFutureCallback,
    this.popupBlockedCallback,
  );

  final String windowUrl;
  final String windowName;
  final Future<void> Function(String data) loginCallback;
  final void Function() completerFutureCallback;
  final void Function()? popupBlockedCallback;
}
