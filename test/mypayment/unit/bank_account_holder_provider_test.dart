import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/bank_account_holder_provider.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

/// `BankAccountHolderNotifier`'s write path.
///
/// Every page test only reads the holder (the main page's `StoreList` branch,
/// the invoice pages' gate), so `addBankAccountHolder` had never been called:
/// it is the call the structure-admin flow makes when a structure becomes the
/// bank account holder. `SingleNotifierAPI.add` only POSTs from a data state,
/// so the test loads the current holder first — exactly the order the UI takes.
void main() {
  group('BankAccountHolderNotifier', () {
    late MockOpenapi mockRepository;
    late ProviderContainer container;
    late BankAccountHolderNotifier notifier;

    final bde = Structure.empty().copyWith(id: 'structure-1', name: 'BDE');

    setUp(() {
      mockRepository = MockOpenapi();
      when(() => mockRepository.mypaymentBankAccountHolderGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), bde),
      );
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
      notifier = container.read(bankAccountHolderProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('addBankAccountHolder posts the structure id and keeps it', () async {
      await notifier.getBankAccountHolder();

      MyPaymentBankAccountHolder? posted;
      when(
        () => mockRepository.mypaymentBankAccountHolderPost(
          body: any(named: 'body'),
        ),
      ).thenAnswer((invocation) async {
        posted =
            invocation.namedArguments[#body] as MyPaymentBankAccountHolder;
        return chopper.Response(http.Response('body', 200), bde);
      });

      final added = await notifier.addBankAccountHolder(bde);

      expect(added, isTrue);
      expect(posted!.holderStructureId, 'structure-1');
      expect(container.read(bankAccountHolderProvider).value?.id, 'structure-1');
    });

    test('a refused POST reports false and keeps the loaded holder', () async {
      await notifier.getBankAccountHolder();
      when(
        () => mockRepository.mypaymentBankAccountHolderPost(
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('holder refused'));

      final added = await notifier.addBankAccountHolder(bde);

      expect(added, isFalse);
      // `add` restores the data it started from, so a failed holder change
      // never blanks the card that renders it.
      expect(container.read(bankAccountHolderProvider).value?.id, 'structure-1');
    });
  });
}
