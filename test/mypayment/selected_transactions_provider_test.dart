import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/my_history_provider.dart';
import 'package:titan/mypayment/providers/selected_transactions_provider.dart';
import 'package:titan/tools/repository/repository.dart';

class MockRepository extends Mock implements Openapi {}

History history({
  required DateTime creation,
  TransactionStatus status = TransactionStatus.confirmed,
}) => History.empty().copyWith(creation: creation, status: status);

void main() {
  group('SelectedTransactionsNotifier', () {
    late MockRepository mockRepository;
    late ProviderContainer container;
    final currentMonth = DateTime(2026, 9, 15);

    setUp(() {
      mockRepository = MockRepository();
      when(() => mockRepository.mypaymentUsersMeWalletHistoryGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('[]', 200), <History>[]),
      );
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
    });

    tearDown(() => container.dispose());

    test('keeps confirmed and refunded transactions of the given month', () async {
      final inMonthConfirmed = history(creation: DateTime(2026, 9, 2));
      final inMonthRefunded = history(
        creation: DateTime(2026, 9, 20),
        status: TransactionStatus.refunded,
      );
      final otherMonth = history(creation: DateTime(2026, 8, 2));
      final otherYear = history(creation: DateTime(2025, 9, 2));
      final inMonthOtherStatus = history(
        creation: DateTime(2026, 9, 5),
        status: TransactionStatus.canceled,
      );

      when(() => mockRepository.mypaymentUsersMeWalletHistoryGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), [
          inMonthConfirmed,
          inMonthRefunded,
          otherMonth,
          otherYear,
          inMonthOtherStatus,
        ]),
      );
      container.read(myHistoryProvider);
      container.read(selectedTransactionsProvider(currentMonth));
      // The family provider rebuilds once the async history load completes.
      await Future(() {});

      expect(container.read(selectedTransactionsProvider(currentMonth)), [
        inMonthConfirmed,
        inMonthRefunded,
      ]);
    });

    test('is empty while the history is loading', () {
      container.read(selectedTransactionsProvider(currentMonth));

      expect(container.read(selectedTransactionsProvider(currentMonth)), []);
    });

    test('selected transactions can be updated', () async {
      final notifier = container.read(
        selectedTransactionsProvider(currentMonth).notifier,
      );
      final selected = [history(creation: DateTime(2026, 9, 2))];

      notifier.updateSelectedTransactions(selected);

      expect(
        container.read(selectedTransactionsProvider(currentMonth)),
        selected,
      );
    });
  });
}
