import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/providers/checkout_provider.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

void main() {
  group('CheckoutNotifier', () {
    late MockOpenapi mockRepository;
    late ProviderContainer container;

    final checkout = Checkout(
      categoryId: 'cat-1',
      sessionId: 'session-1',
      answers: const [],
      mypaymentRequestMethod: RequestType.transferRequest,
      mypaymentTransferRedirectUrl: '',
    );

    final checkoutResponse = CheckoutResponse(
      price: 1000,
      expiration: DateTime(2100),
      paymentUrl: 'https://pay.example/checkout',
    );

    setUp(() {
      mockRepository = MockOpenapi();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
    });

    tearDown(() => container.dispose());

    test('copyWith keeps what it is not given and replaces what it is', () {
      // Every field of the creation state has to be reachable through
      // copyWith: the page flips isCreating around the request and isSuccess
      // once it lands, and both must survive an error being cleared.
      //
      // Coverage note: `copyWith`'s `isCreating: isCreating ?? this.isCreating`
      // line was reported as 0 hits while `busy.isCreating` below proves it
      // ran, which made it look like a reporter artifact. A probe says the
      // opposite. On an `x ?? this.x` argument line the reporter credits the
      // line with the RIGHT operand's evaluations, so a 0 means the fallback
      // never ran. Same trivial class, two runs, same assertions:
      // `copyWith(a: true, b: 7, c: 'x')` reported `DA:19,1 DA:20,0 DA:21,0`,
      // and a second call that left `a` and `b` unset flipped those two lines
      // to `DA:20,1 DA:21,1`. The fallback in this file really was untested —
      // every call below names `isCreating` — so `untouched` is the call that
      // leaves it to run. Production code is unchanged.
      const original = CheckoutCreationState(
        isCreating: false,
        isSuccess: false,
        error: 'boom',
      );

      final busy = original.copyWith(isCreating: true);
      expect(busy.isCreating, isTrue);
      expect(busy.isSuccess, isFalse);
      // `error:` is dropped unless named, which is how the page clears it.
      expect(busy.error, isNull);

      final done = busy.copyWith(isCreating: false, isSuccess: true);
      expect(done.isCreating, isFalse);
      expect(done.isSuccess, isTrue);
      expect(done.error, isNull);

      // Naming nothing is the state the page is in between two requests: the
      // `?? this.<field>` fallbacks are the only thing that keeps it.
      final untouched = done.copyWith();
      expect(untouched.isCreating, isFalse);
      expect(untouched.isSuccess, isTrue);
      expect(untouched.checkout, isNull);
      expect(untouched.error, isNull);
    });

    test('starts in an idle state', () {
      final state = container.read(checkoutProvider);

      expect(state.isCreating, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.checkout, isNull);
      expect(state.error, isNull);
    });

    test('createCheckout exposes the response on success', () async {
      when(
        () => mockRepository.ticketsEventsEventIdCheckoutPost(
          eventId: any(named: 'eventId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            chopper.Response(http.Response('body', 200), checkoutResponse),
      );

      await container
          .read(checkoutProvider.notifier)
          .createCheckout(checkout, 'event-1');

      final state = container.read(checkoutProvider);
      expect(state.isCreating, isFalse);
      expect(state.isSuccess, isTrue);
      expect(state.checkout?.price, 1000);
      expect(state.checkout?.paymentUrl, 'https://pay.example/checkout');
      expect(state.error, isNull);
    });

    test(
      'createCheckout maps a sold-out backend answer to the i18n key',
      () async {
        when(
          () => mockRepository.ticketsEventsEventIdCheckoutPost(
            eventId: any(named: 'eventId'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response<CheckoutResponse>(
            http.Response('Session is sold out', 400),
            null,
            error: 'Session is sold out',
          ),
        );

        await container
            .read(checkoutProvider.notifier)
            .createCheckout(checkout, 'event-1');

        final state = container.read(checkoutProvider);
        expect(state.isSuccess, isFalse);
        expect(state.checkout, isNull);
        // The raw backend message is swallowed so the UI can translate it.
        expect(state.error, 'ticketsSessionSoldOut');
      },
    );

    test('createCheckout keeps other failures as raw errors', () async {
      when(
        () => mockRepository.ticketsEventsEventIdCheckoutPost(
          eventId: any(named: 'eventId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response<CheckoutResponse>(
          http.Response('payment refused', 402),
          null,
          error: 'payment refused',
        ),
      );

      await container
          .read(checkoutProvider.notifier)
          .createCheckout(checkout, 'event-1');

      final state = container.read(checkoutProvider);
      expect(state.isSuccess, isFalse);
      expect(state.isCreating, isFalse);
      expect(state.error, contains('payment refused'));
    });

    test('createCheckout surfaces thrown exceptions', () async {
      when(
        () => mockRepository.ticketsEventsEventIdCheckoutPost(
          eventId: any(named: 'eventId'),
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('network down'));

      await container
          .read(checkoutProvider.notifier)
          .createCheckout(checkout, 'event-1');

      final state = container.read(checkoutProvider);
      expect(state.isSuccess, isFalse);
      expect(state.isCreating, isFalse);
      expect(state.error, isNotNull);
    });

    test('reset returns to the idle state', () async {
      when(
        () => mockRepository.ticketsEventsEventIdCheckoutPost(
          eventId: any(named: 'eventId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            chopper.Response(http.Response('body', 200), checkoutResponse),
      );

      final notifier = container.read(checkoutProvider.notifier);
      await notifier.createCheckout(checkout, 'event-1');
      expect(container.read(checkoutProvider).isSuccess, isTrue);

      notifier.reset();

      final state = container.read(checkoutProvider);
      expect(state.isCreating, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.checkout, isNull);
      expect(state.error, isNull);
    });
  });
}
