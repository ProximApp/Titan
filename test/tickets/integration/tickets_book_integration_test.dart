import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/ui/components/sold_out_badge.dart';
import 'package:titan/tickets/ui/pages/book_ticket_page.dart';
import 'package:titan/tools/functions.dart';
import 'package:titan/tools/providers/path_forwarding_provider.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';

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
      when(() => scaffold.repository.ticketsEventsEventIdGet(eventId: 'evt-1'))
          .thenAnswer((_) async => chopperResponse(bookableEvent()));
    }
    stubWalletChain();

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets/book',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);
  }

  /// Pumps the booking page for [event] through the same deep link the other
  /// tests use, so the real route tree is in place — the page navigates with
  /// QR on a completed booking.
  Future<void> pumpEvent(WidgetTester tester, EventPublic event) async {
    scaffold.setWideSurface(tester);
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    container
        .read(pathForwardingProvider.notifier)
        .forward('/tickets/book', queryParameters: {'ticketEventId': 'evt-1'});
    when(() => scaffold.repository.ticketsEventsEventIdGet(eventId: 'evt-1'))
        .thenAnswer((_) async => chopperResponse(event));
    stubWalletChain();
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets/book',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);
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
    await settle(tester, frames: 8);

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
    await settle(tester, frames: 4);

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
    await settle(tester, frames: 6);
    await tester.scrollUntilVisible(
      find.text('Book'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Book'));
    await tester.tap(find.text('Book'));
    await settle(tester, frames: 12);

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

  testWidgets('a non-numeric answer to a number question is rejected', (
    tester,
  ) async {
    await pumpBook(tester);

    // The number question is the page's LAST text field (text, boolean radio,
    // then number), and its validator runs on user interaction.
    await tester.enterText(find.byType(TextFormField).last, 'twelve');
    await settle(tester, frames: 6);

    // The field says why (wording checked loosely so a copy change names
    // itself instead of failing on a literal).
    expect(
      anyVisibleTextContains(tester, 'number'),
      isTrue,
      reason: 'validation messages on screen: ${visibleTexts(tester)}',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a refused payment-URL launch is reported, not swallowed', (
    tester,
  ) async {
    await pumpBook(tester);
    // No browser to hand the HelloAsso URL to: `tryLaunchUrl` throws, and the
    // page's catch must surface it — a silent return would look like a
    // completed booking to the user.
    stubUrlLauncher(FakeUrlLauncher(launchSucceeds: false));
    when(
      () => scaffold.repository.ticketsEventsEventIdCheckoutPost(
        eventId: any(named: 'eventId'),
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

    await tapText(tester, 'Normal', frames: 6);
    await tapText(tester, 'Book', frames: 14);

    expect(
      anyVisibleTextContains(tester, 'open link'),
      isTrue,
      reason:
          'the launch failure must be reported; on screen: '
          '${visibleTexts(tester)}',
    );
    expect(find.text('Ticket booked successfully!'), findsNothing);
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
    when(() => scaffold.repository.ticketsEventsEventIdGet(eventId: 'evt-1'))
        .thenAnswer(
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
    await settle(tester, frames: 12);

    // The badge shows on the event header and the (auto-selected) category.
    expect(find.text('Sold out'), findsWidgets);
    expect(find.text('This event is sold out'), findsOneWidget);
    // The Book button renders disabled: tapping it must not reach the
    // repository.
    await tester.tap(find.text('Book'), warnIfMissed: false);
    await settle(tester, frames: 6);
    verifyNever(
      () => scaffold.repository.ticketsEventsEventIdCheckoutPost(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    );
  });

  /// Selects the category and confirms the checkout through the Book button.
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
    await settle(tester, frames: 12);
  }

  testWidgets('a checkout with a payment URL launches it and returns to '
      '/tickets', (tester) async {
    final launcher = FakeUrlLauncher();
    stubUrlLauncher(launcher);
    await pumpBook(tester);

    when(
      () => scaffold.repository.ticketsEventsEventIdCheckoutPost(
        eventId: 'evt-1',
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopperResponse(
        CheckoutResponse.empty().copyWith(
          paymentUrl: 'https://pay.example/checkout',
          price: 500,
        ),
      ),
    );
    await book(tester);

    // The success effect resets, navigates back to the module root and
    // opens the external payment URL on a non-web target.
    expect(QR.currentPath, '/tickets');
    expect(launcher.launched, ['https://pay.example/checkout']);
  });

  testWidgets('a paid checkout without URL forwards to /mypayment', (
    tester,
  ) async {
    await pumpBook(tester);

    when(
      () => scaffold.repository.ticketsEventsEventIdCheckoutPost(
        eventId: 'evt-1',
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async =>
          chopperResponse(CheckoutResponse.empty().copyWith(price: 500)),
    );
    await book(tester);

    // The myempay branch forwards the path and navigates there.
    expect(QR.currentPath, '/mypayment');
  });

  testWidgets('a failing checkout toasts the error and the sold-out '
      'mapping', (tester) async {
    await pumpBook(tester);

    when(
      () => scaffold.repository.ticketsEventsEventIdCheckoutPost(
        eventId: 'evt-1',
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperError(400, error: 'payment declined'));
    await book(tester);
    expect(find.textContaining('payment declined'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // The sold-out exception maps to its own localized message.
    when(
      () => scaffold.repository.ticketsEventsEventIdCheckoutPost(
        eventId: 'evt-1',
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperError(409, error: 'Session is sold out'));
    await book(tester);
    expect(find.text('This session is sold out'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a required question gates the checkout and reaches its body', (
    tester,
  ) async {
    // The purchase-side counterpart of the sold-out gate: a user must not be
    // able to pay for a ticket whose mandatory question is blank, and the
    // answer they type must be the one the backend receives.
    scaffold.setWideSurface(tester);
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    container
        .read(pathForwardingProvider.notifier)
        .forward('/tickets/book', queryParameters: {'ticketEventId': 'evt-1'});
    when(() => scaffold.repository.ticketsEventsEventIdGet(eventId: 'evt-1'))
        .thenAnswer(
          (_) async => chopperResponse(
            EventPublic.empty().copyWith(
              id: 'evt-1',
              name: 'Gala 2026',
              categories: [
                CategoryPublic.empty().copyWith(
                  id: 'cat-1',
                  name: 'Normal',
                  price: 1000,
                ),
              ],
              sessions: [
                SessionPublic.empty().copyWith(
                  id: 'ses-1',
                  name: 'Saturday',
                  startDatetime: DateTime(2026, 1, 11, 20),
                ),
              ],
              questions: [
                QuestionPublic.empty().copyWith(
                  id: 'q-1',
                  question: 'Allergies?',
                  required: true,
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
    await settle(tester, frames: 12);

    // The label carries the required marker.
    expect(find.text('Allergies? *'), findsOneWidget);
    await tester.tap(find.text('Normal'));
    await settle(tester, frames: 12);

    final bookButton = find.widgetWithText(ElevatedButton, 'Book');
    await tester.ensureVisible(bookButton);
    expect(
      tester.widget<ElevatedButton>(bookButton).onPressed,
      isNull,
      reason: 'a blank required answer must block the checkout',
    );

    await tester.enterText(find.byType(TextFormField).first, 'Vegan');
    await settle(tester, frames: 12);
    expect(tester.widget<ElevatedButton>(bookButton).onPressed, isNotNull);

    when(
      () => scaffold.repository.ticketsEventsEventIdCheckoutPost(
        eventId: 'evt-1',
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopperResponse(CheckoutResponse.empty().copyWith(price: 0)),
    );

    await tester.ensureVisible(bookButton);
    await tester.tap(bookButton);
    await settle(tester, frames: 12);

    final checkout =
        verify(
              () => scaffold.repository.ticketsEventsEventIdCheckoutPost(
                eventId: 'evt-1',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as Checkout;
    expect(checkout.answers.single.questionId, 'q-1');
    expect(checkout.answers.single.answer, 'Vegan');
    expect(checkout.categoryId, 'cat-1');
    expect(checkout.sessionId, 'ses-1');
    expect(checkout.mypaymentRequestMethod, RequestType.transferRequest);

    // A free checkout lands back on the module root.
    expect(QR.currentPath, '/tickets');
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a paid checkout without a payment URL routes to myempay', (
    tester,
  ) async {
    await pumpBook(tester);

    // A non-zero price with NO paymentUrl is the myempay case: the backend
    // wants the wallet to pay, so there is nothing to open in a browser. The
    // three checkout outcomes are free (back to /tickets), HelloAsso (open
    // the URL) and this one — only the first two had a test, so a pricing
    // change that silently dropped the wallet hop would have looked green.
    when(
      () => scaffold.repository.ticketsEventsEventIdCheckoutPost(
        eventId: 'evt-1',
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async =>
          chopperResponse(CheckoutResponse.empty().copyWith(price: 1000)),
    );

    await book(tester);

    expect(QR.currentPath, '/mypayment');
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a session selects it and empties the other radio', (
    tester,
  ) async {
    await pumpEvent(
      tester,
      eventWith(
        sessions: [
          SessionPublic.empty().copyWith(
            id: 'ses-1',
            name: 'Saturday',
            startDatetime: DateTime(2026, 1, 11, 20),
          ),
          SessionPublic.empty().copyWith(
            id: 'ses-2',
            name: 'Sunday',
            startDatetime: DateTime(2026, 1, 12, 14),
          ),
        ],
      ),
    );

    // Two sessions means no auto-selection: only the single category shows a
    // checked radio, and the sessions each show an empty one.
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));

    await tester.tap(find.textContaining('Sunday - '));
    await settle(tester, frames: 8);

    // The tapped session is checked and the untouched one is not, which is
    // also the unselected styling branch of the row.
    expect(find.byIcon(Icons.radio_button_checked), findsNWidgets(2));
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a sold-out session shows the badge and cannot be selected', (
    tester,
  ) async {
    await pumpEvent(
      tester,
      eventWith(
        sessions: [
          SessionPublic.empty().copyWith(
            id: 'ses-1',
            name: 'Saturday',
            startDatetime: DateTime(2026, 1, 11, 20),
          ),
          SessionPublic.empty().copyWith(
            id: 'ses-2',
            name: 'Sunday',
            startDatetime: DateTime(2026, 1, 12, 14),
            soldOut: true,
          ),
        ],
      ),
    );

    // The event and the category are still on sale; only that session is not.
    expect(find.byType(SoldOutBadge), findsOneWidget);
    await tester.tap(find.textContaining('Sunday - '), warnIfMissed: false);
    await settle(tester, frames: 6);

    // Its row has no onTap, so the selection stayed on the category alone.
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the HelloAsso tile can be tapped again without changing the '
      'method', (tester) async {
    await pumpEvent(tester, eventWith());
    await tester.tap(find.text('Normal'));
    await settle(tester, frames: 8);

    expect(find.textContaining('payment link is personal'), findsOneWidget);
    await tester.tap(find.text('HelloAsso'));
    await settle(tester, frames: 6);

    // Re-selecting HelloAsso is a no-op that must not clear the selection.
    expect(find.textContaining('payment link is personal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('answering No to a boolean question records that answer', (
    tester,
  ) async {
    // "No" is an ANSWER, not an absence: the field is satisfied by it, which
    // is why the gate must open rather than stay shut on a null value.
    await pumpEvent(
      tester,
      eventWith(
        questions: [
          QuestionPublic.empty().copyWith(
            id: 'q-2',
            question: 'Brings a guest?',
            answerType: enums.AnswerType.boolean,
            required: true,
          ),
        ],
      ),
    );

    await tester.tap(find.text('No'));
    await settle(tester, frames: 6);

    // Three checked radios: the auto-selected category, the auto-selected
    // single session, and the "No" the user just picked.
    expect(find.byIcon(Icons.radio_button_checked), findsNWidgets(3));
    // Unmounted while the container is still alive: the page's cleanup calls
    // back into the navbar provider, which cannot be used once the container
    // is disposed (the harness unmounts after that otherwise).
    await scaffold.unmountApp(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clearing a required number answer names the field as required', (
    tester,
  ) async {
    await pumpEvent(
      tester,
      eventWith(
        questions: [
          QuestionPublic.empty().copyWith(
            id: 'q-3',
            question: 'Table number',
            answerType: enums.AnswerType.number,
            required: true,
          ),
        ],
      ),
    );

    await tester.enterText(find.byType(TextFormField), '12');
    await settle(tester, frames: 4);
    await tester.enterText(find.byType(TextFormField), '');
    await settle(tester, frames: 6);

    // Emptied again by the user: the number field reports the missing answer,
    // not a bad number.
    expect(find.text('Required'), findsOneWidget);
    await scaffold.unmountApp(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clearing a required text answer names the field as required', (
    tester,
  ) async {
    await pumpEvent(
      tester,
      eventWith(
        questions: [
          QuestionPublic.empty().copyWith(
            id: 'q-1',
            question: 'Allergies?',
            answerType: enums.AnswerType.text,
            required: true,
          ),
        ],
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'Vegan');
    await settle(tester, frames: 4);
    await tester.enterText(find.byType(TextFormField), '');
    await settle(tester, frames: 6);

    expect(find.text('Required'), findsOneWidget);
    await scaffold.unmountApp(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a question with an unknown answer type renders no input', (
    tester,
  ) async {
    // The backend can add an answer type this build does not know; the enum
    // carries it as swaggerGeneratedUnknown. The page must still list the
    // question (the label is the description) and must not mount a field for
    // it — an unhandled switch here would crash the whole booking form.
    await pumpEvent(
      tester,
      eventWith(
        questions: [
          QuestionPublic.empty().copyWith(
            id: 'q-9',
            question: 'Odd one',
            answerType: enums.AnswerType.swaggerGeneratedUnknown,
          ),
        ],
      ),
    );

    expect(find.textContaining('Odd one'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await scaffold.unmountApp(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('on the web the payment URL goes to the HelloAsso popup with a '
      'site redirect', (tester) async {
    final popups = <_Popup>[];
    void opener(
      String windowUrl,
      String windowName, {
      required void Function() completerFutureCallback,
      required Future<void> Function(String) loginCallback,
      void Function()? popupBlockedCallback,
    }) {
      popups.add(
        _Popup(windowUrl, windowName, loginCallback, completerFutureCallback),
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
    stubWalletChain();
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

    // The redirect is a page on the site, not the app deep link: HelloAsso
    // navigates the browser there, and only the site can hand control back.
    final checkout =
        verify(
              () => scaffold.repository.ticketsEventsEventIdCheckoutPost(
                eventId: 'evt-1',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as Checkout;
    expect(checkout.mypaymentTransferRedirectUrl, '${getTitanURL()}tickets');
    expect(popups, hasLength(1));
    expect(popups.single.windowName, 'HelloAsso');
    expect(popups.single.windowUrl, 'https://helloasso.example/pay');

    // What the browser posts back when the payment completes.
    await popups.single.loginCallback(
      'https://myemapp.com/static.html?code=succeeded',
    );
    await settle(tester, frames: 10);

    expect(find.text('Ticket booked successfully!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
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
  );

  final String windowUrl;
  final String windowName;
  final Future<void> Function(String data) loginCallback;
  final void Function() completerFutureCallback;
}

/// An event whose question and session lists the test controls.
EventPublic eventWith({
  List<SessionPublic>? sessions,
  List<QuestionPublic>? questions,
}) => EventPublic.empty().copyWith(
  id: 'evt-1',
  name: 'Gala 2026',
  categories: [
    CategoryPublic.empty().copyWith(id: 'cat-1', name: 'Normal', price: 1000),
  ],
  sessions:
      sessions ??
      [
        SessionPublic.empty().copyWith(
          id: 'ses-1',
          name: 'Saturday',
          startDatetime: DateTime(2026, 1, 11, 20),
        ),
      ],
  questions: questions ?? const [],
);
