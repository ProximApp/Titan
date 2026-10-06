import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/purchases/providers/scanner_provider.dart';
import 'package:titan/tools/repository/repository.dart';

class MockRepository extends Mock implements Openapi {}

void main() {
  group('ScannerNotifier', () {
    late MockRepository mockRepository;
    late ProviderContainer container;
    late ScannerNotifier notifier;

    setUp(() {
      mockRepository = MockRepository();
      when(
        () => mockRepository
            .cdrSellersSellerIdProductsProductIdTicketsGeneratorIdSecretGet(
              sellerId: any(named: 'sellerId'),
              productId: any(named: 'productId'),
              generatorId: any(named: 'generatorId'),
              secret: any(named: 'secret'),
            ),
      ).thenAnswer(
        (_) async => chopper.Response(
          http.Response('{}', 200),
          AppModulesCdrSchemasCdrTicket.empty(),
        ),
      );
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
      notifier = container.read(scannerProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('scanTicket sends the stored secret and loads the ticket', () async {
      final ticket = AppModulesCdrSchemasCdrTicket.empty().copyWith(
        id: 'ticket-1',
      );
      when(
        () => mockRepository
            .cdrSellersSellerIdProductsProductIdTicketsGeneratorIdSecretGet(
              sellerId: any(named: 'sellerId'),
              productId: any(named: 'productId'),
              generatorId: any(named: 'generatorId'),
              secret: any(named: 'secret'),
            ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), ticket),
      );

      notifier.setSecret('my-secret');
      final result = await notifier.scanTicket('s', 'p', 'g');

      expect(result.value!.id, 'ticket-1');
      verify(
        () => mockRepository
            .cdrSellersSellerIdProductsProductIdTicketsGeneratorIdSecretGet(
              sellerId: 's',
              productId: 'p',
              generatorId: 'g',
              secret: 'my-secret',
            ),
      ).called(1);
    });

    test('scanTicket handles error', () async {
      when(
        () => mockRepository
            .cdrSellersSellerIdProductsProductIdTicketsGeneratorIdSecretGet(
              sellerId: any(named: 'sellerId'),
              productId: any(named: 'productId'),
              generatorId: any(named: 'generatorId'),
              secret: any(named: 'secret'),
            ),
      ).thenThrow(Exception('scan failed'));

      final result = await notifier.scanTicket('s', 'p', 'g');

      expect(result, isA<AsyncError<AppModulesCdrSchemasCdrTicket>>());
    });

    test('setScanner stores the ticket', () {
      final ticket = AppModulesCdrSchemasCdrTicket.empty().copyWith(
        id: 'ticket-2',
      );

      notifier.setScanner(ticket);

      expect(container.read(scannerProvider).value!.id, 'ticket-2');
    });

    test('reset clears the state and the secret', () async {
      final ticket = AppModulesCdrSchemasCdrTicket.empty();
      notifier.setScanner(ticket);
      notifier.setSecret('abc');

      notifier.reset();

      expect(container.read(scannerProvider).isLoading, true);
    });
  });
}
