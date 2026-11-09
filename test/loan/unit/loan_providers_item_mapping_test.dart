import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/loan/providers/history_loaner_loan_list_provider.dart';
import 'package:titan/loan/providers/loaner_id_provider.dart';
import 'package:titan/loan/providers/loan_list_provider.dart';
import 'package:titan/loan/providers/loaner_loan_list_provider.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';
import '../loan_fixtures.dart';

/// Both loan list notifiers rebuild the PATCH body from the local `Loan`,
/// translating every borrowed item into an `ItemBorrowed`. The existing tests
/// patch loans with no items, so that translation never ran — and a dropped
/// `itemId` would silently empty the loan on the server.
void main() {
  late MockOpenapi repository;

  setUp(() => repository = MockOpenapi());

  Loan loanWithItem() => loanFixture(
    id: 'l-1',
    itemsQty: [
      itemQuantity(itemId: 'item-1', itemName: 'Tente', quantity: 2),
      itemQuantity(itemId: 'item-2', itemName: 'Corde', quantity: 1),
    ],
  );

  void stubPatch() {
    when(
      () => repository.loansLoanIdPatch(
        loanId: any(named: 'loanId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), null),
    );
  }

  test('the borrower loan list sends every borrowed item', () async {
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(loanerLoanListProvider.notifier);
    final loan = loanWithItem();
    notifier.state = AsyncValue.data([loan]);
    stubPatch();

    final result = await notifier.updateLoan(loan.copyWith(notes: 'edited'));

    expect(result, isTrue);
    final body =
        verify(
              () => repository.loansLoanIdPatch(
                loanId: 'l-1',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as LoanUpdate;
    expect(body.itemsBorrowed!.map((e) => e.itemId), ['item-1', 'item-2']);
    expect(body.itemsBorrowed!.map((e) => e.quantity), [2, 1]);
    expect(body.notes, 'edited');
  });

  test('the history list sends every borrowed item too', () async {
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(historyLoanerLoanListProvider.notifier);
    final loan = loanWithItem();
    notifier.state = AsyncValue.data([loan]);
    stubPatch();

    final result = await notifier.updateLoan(loan.copyWith(caution: '30 €'));

    expect(result, isTrue);
    final body =
        verify(
              () => repository.loansLoanIdPatch(
                loanId: 'l-1',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as LoanUpdate;
    expect(body.itemsBorrowed!.map((e) => e.itemId), ['item-1', 'item-2']);
    expect(body.caution, '30 €');
  });

  test(
    'reading the id provider keeps the lists loading until a loaner is set',
    () {
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      expect(container.read(loanerIdProvider), '');
      expect(container.read(loanerLoanListProvider).isLoading, isTrue);
    },
  );

  test('the user loan list sends every borrowed item as well', () async {
    when(() => repository.loansUsersMeGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('[]', 200), <Loan>[]),
    );
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(loanListProvider.notifier);
    final loan = loanWithItem();
    notifier.state = AsyncValue.data([loan]);
    stubPatch();

    final result = await notifier.updateLoan(loan.copyWith(returned: false));

    expect(result, isTrue);
    final body =
        verify(
              () => repository.loansLoanIdPatch(
                loanId: 'l-1',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as LoanUpdate;
    expect(body.itemsBorrowed!.map((e) => e.itemId), ['item-1', 'item-2']);
  });
}
