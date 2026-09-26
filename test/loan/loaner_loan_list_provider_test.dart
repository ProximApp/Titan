import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/loan/providers/loaner_id_provider.dart';
import 'package:titan/loan/providers/loaner_loan_list_provider.dart';
import 'package:titan/tools/repository/repository.dart';

class MockRepository extends Mock implements Openapi {}

void main() {
  group('LoanerLoanListNotifier', () {
    late MockRepository mockRepository;
    late ProviderContainer container;
    late LoanerLoanListNotifier notifier;

    setUp(() {
      mockRepository = MockRepository();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
      notifier = container.read(loanerLoanListProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('stays loading when no loaner is selected', () {
      container.read(loanerIdProvider);
      container.read(loanerLoanListProvider);

      expect(container.read(loanerLoanListProvider).isLoading, true);
    });

    test('loadLoan fetches the loans of a loaner', () async {
      final loans = [
        Loan.empty().copyWith(id: '1'),
        Loan.empty().copyWith(id: '2'),
      ];
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
    });

    test('loadLoan handles error', () async {
      when(
        () => mockRepository.loansLoanersLoanerIdLoansGet(
          loanerId: 'loaner-1',
          returned: any(named: 'returned'),
        ),
      ).thenThrow(Exception('loans failed'));

      final result = await notifier.loadLoan('loaner-1');

      expect(result, isA<AsyncError<List<Loan>>>());
    });

    test('addLoan appends the created loan', () async {
      final created = Loan.empty().copyWith(id: 'new');
      when(
        () => mockRepository.loansPost(body: any(named: 'body')),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), created),
      );

      notifier.state = AsyncValue.data([]);
      final result = await notifier.addLoan(LoanCreation.empty());

      expect(result, true);
      expect(notifier.state.value!.single.id, 'new');
    });

    test('updateLoan replaces the loan in the list', () async {
      final loan = Loan.empty().copyWith(id: '1');
      final updated = loan.copyWith(notes: 'updated');
      when(
        () => mockRepository.loansLoanIdPatch(
          loanId: '1',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );

      notifier.state = AsyncValue.data([loan]);
      final result = await notifier.updateLoan(updated);

      expect(result, true);
      expect(notifier.state.value!.single.notes, 'updated');
    });

    test('deleteLoan removes the loan', () async {
      final loan = Loan.empty().copyWith(id: '1');
      when(
        () => mockRepository.loansLoanIdDelete(loanId: '1'),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );

      notifier.state = AsyncValue.data([loan]);
      final result = await notifier.deleteLoan(loan);

      expect(result, true);
      expect(notifier.state.value, isEmpty);
    });

    test('returnLoan removes the returned loan', () async {
      final loan = Loan.empty().copyWith(id: '1');
      when(
        () => mockRepository.loansLoanIdReturnPost(loanId: '1'),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );

      notifier.state = AsyncValue.data([loan]);
      final result = await notifier.returnLoan(loan);

      expect(result, true);
      expect(notifier.state.value, isEmpty);
    });

    test('extendLoan keeps the loan in the list', () async {
      final loan = Loan.empty().copyWith(id: '1');
      when(
        () => mockRepository.loansLoanIdExtendPost(
          loanId: '1',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );

      notifier.state = AsyncValue.data([loan]);
      final result = await notifier.extendLoan(loan, 7);

      expect(result, true);
      expect(notifier.state.value, [loan]);
    });

    test('filterLoans matches on borrower and item names', () async {
      final alice = Loan.empty().copyWith(
        id: '1',
        borrower: CoreUserSimple.empty().copyWith(
          firstname: 'Alice',
          name: 'Smith',
        ),
        itemsQty: [
          ItemQuantity(
            quantity: 1,
            itemSimple: ItemSimple.empty().copyWith(name: 'Tente'),
          ),
        ],
      );
      final bob = Loan.empty().copyWith(
        id: '2',
        borrower: CoreUserSimple.empty().copyWith(
          firstname: 'Bob',
          name: 'Jones',
        ),
      );

      notifier.state = AsyncValue.data([alice, bob]);

      final byBorrower = await notifier.filterLoans('ali');
      expect(byBorrower.value!.map((l) => l.id), ['1']);

      final byItem = await notifier.filterLoans('TEN');
      expect(byItem.value!.map((l) => l.id), ['1']);

      final byNoOne = await notifier.filterLoans('zzz');
      expect(byNoOne.value, isEmpty);
    });
  });
}
