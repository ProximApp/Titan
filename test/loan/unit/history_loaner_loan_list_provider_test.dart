import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/loan/providers/history_loaner_loan_list_provider.dart';
import 'package:titan/tools/repository/repository.dart';

class MockRepository extends Mock implements Openapi {}

void main() {
  group('HistoryLoanerLoanListNotifier', () {
    late MockRepository mockRepository;
    late ProviderContainer container;
    late HistoryLoanerLoanListNotifier notifier;

    setUp(() {
      mockRepository = MockRepository();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
      notifier = container.read(historyLoanerLoanListProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('loadHistory returns returned loans on success', () async {
      final loans = [Loan.empty().copyWith(id: '1', returned: true)];
      when(
        () => mockRepository.loansLoanersLoanerIdLoansGet(
          loanerId: 'loaner-1',
          returned: any(named: 'returned'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), loans),
      );

      final result = await notifier.loadHistory('loaner-1');

      expect(result.value, loans);
    });

    test('loadHistory returns an error value on http failure', () async {
      when(
        () => mockRepository.loansLoanersLoanerIdLoansGet(
          loanerId: 'loaner-1',
          returned: any(named: 'returned'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('err', 500), null),
      );

      final result = await notifier.loadHistory('loaner-1');

      expect(result, isA<AsyncError<List<Loan>>>());
    });

    test('loadHistory stores the error in state and returns it', () async {
      when(
        () => mockRepository.loansLoanersLoanerIdLoansGet(
          loanerId: 'loaner-1',
          returned: any(named: 'returned'),
        ),
      ).thenThrow(Exception('history failed'));

      final result = await notifier.loadHistory('loaner-1');

      expect(result, isA<AsyncError<List<Loan>>>());
      expect(notifier.state, isA<AsyncError<List<Loan>>>());
    });

    test('loadLoan fetches returned loans through loadList', () async {
      final loans = [Loan.empty().copyWith(id: '2')];
      when(
        () => mockRepository.loansLoanersLoanerIdLoansGet(
          loanerId: 'loaner-1',
          returned: any(named: 'returned'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), loans),
      );

      final result = await notifier.loadLoan('loaner-1');

      expect(result.value, loans);
      expect(notifier.state.value, loans);
    });

    test('copy returns a copy of the current list', () async {
      final loans = [Loan.empty().copyWith(id: '1')];
      notifier.state = AsyncValue.data(loans);

      final copy = await notifier.copy();

      expect(copy.value, loans);
      expect(identical(copy.value, loans), false);
    });

    test('filterLoans matches borrower names case-insensitively', () async {
      final loan = Loan.empty().copyWith(
        id: '1',
        borrower: CoreUserSimple.empty().copyWith(
          firstname: 'Alice',
          name: 'Smith',
        ),
      );
      notifier.state = AsyncValue.data([loan]);

      final result = await notifier.filterLoans('SMI');

      expect(result.value, [loan]);
    });
  });
}
