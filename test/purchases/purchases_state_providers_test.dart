import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/purchases/providers/product_id_provider.dart';
import 'package:titan/purchases/providers/purchase_provider.dart';
import 'package:titan/purchases/providers/seller_provider.dart';
import 'package:titan/purchases/providers/ticket_id_provider.dart';
import 'package:titan/purchases/providers/ticket_provider.dart';
import 'package:titan/tools/repository/repository.dart';

class MockPurchasesRepository extends Mock implements Openapi {}

void main() {
  group('Purchases state providers', () {
    late MockPurchasesRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockPurchasesRepository();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
    });

    tearDown(() => container.dispose());

    test('purchaseProvider exposes the selected purchase', () {
      final selected = PurchaseReturn.empty();
      container.read(purchaseProvider.notifier).setPurchase(selected);

      expect(container.read(purchaseProvider).value, same(selected));
    });

    test('sellerProvider exposes the selected seller', () {
      final selected = SellerComplete.empty();
      container.read(sellerProvider.notifier).setSeller(selected);

      expect(container.read(sellerProvider), same(selected));
    });

    test('productIdProvider exposes the selected product id', () {
      container.read(productIdProvider.notifier).setProductId('p-1');

      expect(container.read(productIdProvider).value, 'p-1');
    });

    test('ticketIdProvider exposes the selected ticket id', () {
      container.read(ticketIdProvider.notifier).setTicketId('t-1');

      expect(container.read(ticketIdProvider).value, 't-1');
    });

    group('TicketNotifier.loadTicketSecret', () {
      test('errors when no ticket is loaded', () async {
        final result = await container
            .read(ticketProvider.notifier)
            .loadTicketSecret();

        expect(result, isA<AsyncError<TicketSecret>>());
        expect(
          result.error.toString(),
          contains('AppModulesCdrSchemasCdrTicket is not loaded'),
        );
      });

      test('exposes the secret of the loaded ticket', () async {
        final myTicket = AppModulesCdrSchemasCdrTicket.empty().copyWith(
          id: 't-1',
        );
        final secret = TicketSecret.empty().copyWith(qrCodeSecret: 'hush');
        container.read(ticketProvider.notifier).setTicket(myTicket);
        when(
          () => mockRepository.cdrUsersMeTicketsTicketIdSecretGet(
            ticketId: any(named: 'ticketId'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), secret),
        );

        final result = await container
            .read(ticketProvider.notifier)
            .loadTicketSecret();

        expect(result.value, secret);
      });

      test('flags the error when the endpoint fails', () async {
        final myTicket = AppModulesCdrSchemasCdrTicket.empty().copyWith(
          id: 't-1',
        );
        container.read(ticketProvider.notifier).setTicket(myTicket);
        when(
          () => mockRepository.cdrUsersMeTicketsTicketIdSecretGet(
            ticketId: any(named: 'ticketId'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response<TicketSecret>(
            http.Response('invalid', 400),
            null,
            error: 'invalid',
          ),
        );

        final result = await container
            .read(ticketProvider.notifier)
            .loadTicketSecret();

        expect(result, isA<AsyncError<TicketSecret>>());
      });
    });
  });
}
