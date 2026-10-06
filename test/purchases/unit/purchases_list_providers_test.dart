import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/purchases/providers/product_list_provider.dart';
import 'package:titan/purchases/providers/purchase_list_provider.dart';
import 'package:titan/purchases/providers/seller_list_provider.dart';
import 'package:titan/purchases/providers/tag_list_provider.dart';
import 'package:titan/purchases/providers/ticket_list_provider.dart';
import 'package:titan/tools/exception.dart';
import 'package:titan/tools/repository/repository.dart';

class MockPurchasesRepository extends Mock implements Openapi {}

PurchaseReturn purchase(DateTime purchasedOn) =>
    PurchaseReturn.empty().copyWith(purchasedOn: purchasedOn);

AppModulesCdrSchemasCdrTicket ticket(String id, {int scanLeft = 1}) =>
    AppModulesCdrSchemasCdrTicket.empty().copyWith(id: id, scanLeft: scanLeft);

void main() {
  group('Purchases list providers (ListNotifierAPI)', () {
    late MockPurchasesRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockPurchasesRepository();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
    });

    tearDown(() => container.dispose());

    group('PurchaseListNotifier', () {
      test('build fetches my purchases right away', () async {
        final all = [
          purchase(DateTime(2025, 3, 1)),
          purchase(DateTime(2026, 1, 15)),
          // Same year as the first one: only distinct years are collected.
          purchase(DateTime(2025, 6, 2)),
        ];
        when(() => mockRepository.cdrMePurchasesGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), all),
        );

        container.read(purchaseListProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(purchaseListProvider).value, all);
      });

      test(
        'getPurchasesYears collects distinct years in encounter order',
        () async {
          final all = [
            purchase(DateTime(2025, 3, 1)),
            purchase(DateTime(2026, 1, 15)),
            purchase(DateTime(2025, 6, 2)),
          ];
          when(() => mockRepository.cdrMePurchasesGet()).thenAnswer(
            (_) async => chopper.Response(http.Response('body', 200), all),
          );
          final notifier = container.read(purchaseListProvider.notifier);
          await notifier.loadPurchases();

          expect(notifier.getPurchasesYears(), [2025, 2026]);
        },
      );

      test('getPurchasesYears returns nothing before the load', () {
        final notifier = container.read(purchaseListProvider.notifier);

        expect(notifier.getPurchasesYears(), isEmpty);
      });

      test('build flags the error when the fetch fails', () async {
        when(
          () => mockRepository.cdrMePurchasesGet(),
        ).thenThrow(Exception('network down'));

        container.read(purchaseListProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(purchaseListProvider),
          isA<AsyncError<List<PurchaseReturn>>>(),
        );
      });

      test('rethrows AppException.tokenExpire', () async {
        final error = AppException(ErrorType.tokenExpire, 'expired');
        when(() => mockRepository.cdrMePurchasesGet()).thenAnswer(
          (_) async =>
              chopper.Response(http.Response('body', 200), <PurchaseReturn>[]),
        );
        final notifier = container.read(purchaseListProvider.notifier);
        await notifier.loadPurchases();

        when(() => mockRepository.cdrMePurchasesGet()).thenThrow(error);

        await expectLater(notifier.loadPurchases(), throwsA(same(error)));
      });
    });

    group('ProductListNotifier', () {
      test('loadProducts exposes the seller products', () async {
        final products = <AppModulesCdrSchemasCdrProductComplete>[
          AppModulesCdrSchemasCdrProductComplete.empty().copyWith(id: '1'),
        ];
        when(
          () => mockRepository.cdrSellersSellerIdProductsGet(
            sellerId: any(named: 'sellerId'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), products),
        );

        final result = await container
            .read(productListProvider.notifier)
            .loadProducts('seller-1');

        expect(result.value, products);
      });

      test('loadProducts flags the error when the call fails', () async {
        when(
          () => mockRepository.cdrSellersSellerIdProductsGet(
            sellerId: any(named: 'sellerId'),
          ),
        ).thenThrow(Exception('network down'));

        final result = await container
            .read(productListProvider.notifier)
            .loadProducts('seller-1');

        expect(result, isA<AsyncError>());
      });
    });

    group('TagListNotifier', () {
      test('loadTags exposes the tag list', () async {
        when(
          () => mockRepository
              .cdrSellersSellerIdProductsProductIdTagsGeneratorIdGet(
                sellerId: any(named: 'sellerId'),
                productId: any(named: 'productId'),
                generatorId: any(named: 'generatorId'),
              ),
        ).thenAnswer(
          (_) async =>
              chopper.Response(http.Response('body', 200), <String>['a', 'b']),
        );

        final result = await container
            .read(tagListProvider.notifier)
            .loadTags('seller-1', 'product-1', 'generator-1');

        expect(result.value, ['a', 'b']);
      });
    });

    group('SellerListNotifier', () {
      test('build fetches the sellers right away', () async {
        final sellers = [SellerComplete.empty().copyWith(id: '1')];
        when(() => mockRepository.cdrSellersGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), sellers),
        );

        container.read(sellerListProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(sellerListProvider).value, sellers);
      });
    });

    group('TicketListNotifier', () {
      test('build fetches my tickets right away', () async {
        final tickets = [ticket('1'), ticket('2')];
        when(() => mockRepository.cdrUsersMeTicketsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), tickets),
        );

        container.read(ticketListProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(ticketListProvider).value, tickets);
      });

      test(
        'consumeTicket appends the tag and decrements the scan count',
        () async {
          final mine = ticket('1', scanLeft: 2);
          when(() => mockRepository.cdrUsersMeTicketsGet()).thenAnswer(
            (_) async => chopper.Response(http.Response('body', 200), [mine]),
          );
          when(
            () => mockRepository
                .cdrSellersSellerIdProductsProductIdTicketsGeneratorIdSecretPatch(
                  sellerId: any(named: 'sellerId'),
                  productId: any(named: 'productId'),
                  generatorId: any(named: 'generatorId'),
                  secret: any(named: 'secret'),
                  body: any(named: 'body'),
                ),
          ).thenAnswer(
            (_) async =>
                chopper.Response<void>(http.Response('body', 200), null),
          );
          final notifier = container.read(ticketListProvider.notifier);
          await notifier.loadTickets();

          final result = await notifier.consumeTicket(
            'seller-1',
            'product-1',
            mine,
            'generator-1',
            'tag-A',
            'secret',
          );

          expect(result, isTrue);
          final updated = container.read(ticketListProvider).value!.first;
          expect(updated.tags, ', tag-A');
          expect(updated.scanLeft, 1);
        },
      );

      test(
        'consumeTicket keeps the previous ticket when the scan fails',
        () async {
          final mine = ticket('1', scanLeft: 2);
          when(() => mockRepository.cdrUsersMeTicketsGet()).thenAnswer(
            (_) async => chopper.Response(http.Response('body', 200), [mine]),
          );
          when(
            () => mockRepository
                .cdrSellersSellerIdProductsProductIdTicketsGeneratorIdSecretPatch(
                  sellerId: any(named: 'sellerId'),
                  productId: any(named: 'productId'),
                  generatorId: any(named: 'generatorId'),
                  secret: any(named: 'secret'),
                  body: any(named: 'body'),
                ),
          ).thenAnswer(
            (_) async => chopper.Response<void>(
              http.Response('invalid', 400),
              null,
              error: 'invalid',
            ),
          );
          final notifier = container.read(ticketListProvider.notifier);
          await notifier.loadTickets();

          final result = await notifier.consumeTicket(
            'seller-1',
            'product-1',
            mine,
            'generator-1',
            'tag-A',
            'secret',
          );

          expect(result, isFalse);
          expect(container.read(ticketListProvider).value, [mine]);
        },
      );

      test('rethrows AppException.tokenExpire', () async {
        final error = AppException(ErrorType.tokenExpire, 'expired');
        when(() => mockRepository.cdrUsersMeTicketsGet()).thenAnswer(
          (_) async => chopper.Response(
            http.Response('body', 200),
            <AppModulesCdrSchemasCdrTicket>[],
          ),
        );
        final notifier = container.read(ticketListProvider.notifier);
        await notifier.loadTickets();

        when(() => mockRepository.cdrUsersMeTicketsGet()).thenThrow(error);

        await expectLater(notifier.loadTickets(), throwsA(same(error)));
      });
    });
  });
}
