import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/path_forwarding_provider.dart';

import '../../shared/app_scaffold.dart';

/// The booking page (`/tickets/book`, 285 executable lines): event render,
/// category/session selection, question forms, and the checkout round-trip.
///
/// The payment readiness chain (tosProvider, myWalletProvider,
/// canPayProvider's device lookup) fires on mount and is stubbed against
/// the mock repository below.
EventPublic bookableEvent() => EventPublic.empty().copyWith(
  id: 'evt-1',
  name: 'Gala 2026',
  categories: [
    CategoryPublic.empty().copyWith(id: 'cat-1', name: 'Normal', price: 1000),
    CategoryPublic.empty().copyWith(id: 'cat-2', name: 'Premium', price: 2500),
  ],
  sessions: [
    SessionPublic.empty().copyWith(
      id: 'ses-1',
      name: 'Saturday',
      startDatetime: DateTime(2026, 1, 11, 20),
    ),
  ],
  questions: [
    QuestionPublic.empty().copyWith(id: 'q-1', question: 'Allergies?'),
    QuestionPublic.empty().copyWith(
      id: 'q-2',
      question: 'Brings a guest?',
      answerType: enums.AnswerType.boolean,
    ),
    QuestionPublic.empty().copyWith(
      id: 'q-3',
      question: 'Table number',
      answerType: enums.AnswerType.number,
    ),
  ],
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  void stubWalletChain() {
    when(
      () => scaffold.repository.mypaymentUsersMeTosGet(),
    ).thenAnswer((_) async => chopperResponse(TOSSignatureResponse.empty()));
    when(
      () => scaffold.repository.mypaymentUsersMeWalletGet(),
    ).thenAnswer((_) async => chopperResponse(Wallet.empty()));
    when(
      () => scaffold.repository.mypaymentUsersMeWalletDevicesWalletDeviceIdGet(
        walletDeviceId: any(named: 'walletDeviceId'),
      ),
    ).thenAnswer((_) async => chopperResponse(WalletDevice.empty()));
    when(() => scaffold.repository.ticketsUserMeTicketsGet()).thenAnswer(
      (_) async =>
          chopperListResponse<AppCoreTicketsSchemasTicketsTicketComplete>([]),
    );
  }

  /// [withId] forwards the ticketEventId the page reads from the
  /// path-forwarding state; without it the page renders its not-found branch.
  Future<void> pumpBook(WidgetTester tester, {bool withId = true}) async {
    scaffold.setWideSurface(tester);
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    if (withId) {
      // Forwarding before mount is deterministic (a pre-seed could be
      // swallowed by the session bootstrap's redirects).
      container
          .read(pathForwardingProvider.notifier)
          .forward(
            '/tickets/book',
            queryParameters: {'ticketEventId': 'evt-1'},
          );
    }
    if (withId) {
      when(
        () => scaffold.repository.ticketsEventsEventIdGet(eventId: 'evt-1'),
      ).thenAnswer((_) async => chopperResponse(bookableEvent()));
    }
    stubWalletChain();

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets/book',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets(
    'deep link to /tickets/book without an event id shows not found',
    (tester) async {
      await pumpBook(tester, withId: false);

      expect(find.text('Ticketing not found'), findsOneWidget);
    },
  );

  testWidgets('the booking form renders categories, sessions and questions', (
    tester,
  ) async {
    await pumpBook(tester);

    expect(find.text('Book a ticket'), findsOneWidget);
    expect(find.text('Gala 2026'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Session (time)'), findsOneWidget);
    expect(find.text('Questions'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    // priceInEuros is a double, so the label is "10.0€".
    expect(find.text('10.0€'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
    expect(find.textContaining('Saturday - '), findsOneWidget);
    expect(find.textContaining('Allergies?'), findsOneWidget);
    // The single session is auto-selected: its radio shows the checked icon.
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
  });

  testWidgets('selecting a category reveals the total and payment methods', (
    tester,
  ) async {
    await pumpBook(tester);

    expect(find.text('Total'), findsNothing);
    await tester.tap(find.text('Premium'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(find.text('Total'), findsOneWidget);
    // The category row AND the total row both show the price.
    expect(find.text('25.0€'), findsNWidgets(2));
    expect(find.text('Payment method'), findsOneWidget);
    expect(find.text('HelloAsso'), findsOneWidget);
    // myempay renders disabled (the fake key service has no registered
    // device) with its reason underneath.
    expect(find.text('myempay'), findsOneWidget);
    expect(find.text('Device not registered'), findsOneWidget);
    expect(find.textContaining('payment link is personal'), findsOneWidget);
  });

  testWidgets('the question fields accept answers of every type', (
    tester,
  ) async {
    await pumpBook(tester);

    // Text question.
    await tester.enterText(find.byType(TextFormField).first, 'Vegan');
    // Boolean question: tap the "Yes" option.
    await tester.tap(find.text('Yes'));
    // Number question.
    await tester.enterText(find.byType(TextFormField).last, '12');
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(find.text('Vegan'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    // The auto-selected session radio plus the boolean "Yes" radio.
    expect(find.byIcon(Icons.radio_button_checked), findsNWidgets(2));
  });

  testWidgets('the Book button creates a checkout through the repository', (
    tester,
  ) async {
    await pumpBook(tester);

    when(
      () => scaffold.repository.ticketsEventsEventIdCheckoutPost(
        eventId: 'evt-1',
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopperResponse(CheckoutResponse.empty().copyWith(price: 0)),
    );

    await tester.tap(find.text('Normal'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tester.scrollUntilVisible(
      find.text('Book'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Book'));
    await tester.tap(find.text('Book'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    verify(
      () => scaffold.repository.ticketsEventsEventIdCheckoutPost(
        eventId: 'evt-1',
        body: any(named: 'body'),
      ),
    ).called(1);
    // A free checkout (price 0) shows the success toast.
    expect(find.text('Ticket booked successfully!'), findsOneWidget);
    // Drain the toast timer (autoClose 2500ms + 400ms animation).
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('a sold-out event blocks the Book button and shows the badge', (
    tester,
  ) async {
    scaffold.setWideSurface(tester);
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    container
        .read(pathForwardingProvider.notifier)
        .forward('/tickets/book', queryParameters: {'ticketEventId': 'evt-1'});
    when(
      () => scaffold.repository.ticketsEventsEventIdGet(eventId: 'evt-1'),
    ).thenAnswer(
      (_) async => chopperResponse(
        EventPublic.empty().copyWith(
          id: 'evt-1',
          name: 'Gala 2026',
          soldOut: true,
          categories: [
            CategoryPublic.empty().copyWith(
              id: 'cat-1',
              name: 'Normal',
              price: 1000,
            ),
          ],
        ),
      ),
    );
    stubWalletChain();

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets/book',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    // The badge shows on the event header and the (auto-selected) category.
    expect(find.text('Sold out'), findsWidgets);
    expect(find.text('This event is sold out'), findsOneWidget);
    // The Book button renders disabled: tapping it must not reach the
    // repository.
    await tester.tap(find.text('Book'), warnIfMissed: false);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    verifyNever(
      () => scaffold.repository.ticketsEventsEventIdCheckoutPost(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    );
  });
}
