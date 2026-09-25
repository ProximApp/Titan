import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/providers/checkout_provider.dart';
import 'package:titan/tools/repository/repository.dart';

class MockCheckoutRepository extends Mock implements Openapi {}

void main() {
  group('CheckoutNotifier', () {
    late MockCheckoutRepository mockRepository;
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
      mockRepository = MockCheckoutRepository();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
    });

    tearDown(() => container.dispose());

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
