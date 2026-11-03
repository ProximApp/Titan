import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/loan/providers/loaner_loan_list_provider.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

/// `loadHistory` — the RETURNED-loans loader behind the admin's history strip.
///
/// The existing provider tests drive `loadLoan`, which goes through
/// `loadList`; `loadHistory` is a hand-written sibling with its own three-way
/// outcome (2xx body, non-2xx, thrown transport error) and it had never run.
/// Its non-2xx branch is a trap worth pinning: it returns an `AsyncValue.error`
/// WITHOUT storing it, while the catch branch stores the error on the notifier
/// before returning it.
void main() {
  group('LoanerLoanListNotifier.loadHistory', () {
    late MockOpenapi mockRepository;
    late ProviderContainer container;
    late LoanerLoanListNotifier notifier;

    setUp(() {
      mockRepository = MockOpenapi();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
      notifier = container.read(loanerLoanListProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('a 2xx answer yields the returned loans', () async {
      final loans = [
        Loan.empty().copyWith(id: 'h-1', returned: true),
        Loan.empty().copyWith(id: 'h-2', returned: true),
      ];
      when(
        () => mockRepository.loansLoanersLoanerIdLoansGet(
          loanerId: 'loaner-1',
          returned: true,
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), loans),
      );

      final result = await notifier.loadHistory('loaner-1');

      expect(result.value!.map((l) => l.id), ['h-1', 'h-2']);
    });

    test(
      'a refused answer returns an error value without storing it',
      () async {
        when(
          () => mockRepository.loansLoanersLoanerIdLoansGet(
            loanerId: 'loaner-1',
            returned: true,
          ),
        ).thenAnswer(
          (_) async => chopper.Response(
            http.Response('{"detail": "nope"}', 500),
            null,
            error: 'nope',
          ),
        );

        final result = await notifier.loadHistory('loaner-1');

        expect(result, isA<AsyncError<List<Loan>>>());
        expect((result as AsyncError).error, 'Error');
        // Deliberately not stored: the caller keeps its previous state.
        expect(notifier.state, isNot(isA<AsyncError<List<Loan>>>()));
      },
    );

    test(
      'a transport failure is stored on the notifier and returned',
      () async {
        when(
          () => mockRepository.loansLoanersLoanerIdLoansGet(
            loanerId: 'loaner-1',
            returned: true,
          ),
        ).thenThrow(Exception('offline'));

        final result = await notifier.loadHistory('loaner-1');

        expect(result, isA<AsyncError<List<Loan>>>());
        expect(notifier.state, isA<AsyncError<List<Loan>>>());
        expect(notifier.state.error, isA<Exception>());
      },
    );
  });
}
